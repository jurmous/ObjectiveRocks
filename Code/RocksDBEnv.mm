//
//  RocksDBEnv.m
//  ObjectiveRocks
//
//  Created by Iska on 05/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import "RocksDBEnv.h"

#if ROCKSDB_USING_THREAD_STATUS
#import "RocksDBThreadStatus.h"
#endif

#import <rocksdb/env.h>
#import <rocksdb/thread_status.h>

#pragma mark - Informal Protocols

@interface RocksDBEnv ()
{
	rocksdb::Env *_env;
}
@property (nonatomic, assign) rocksdb::Env *env;
@end

#if ROCKSDB_USING_THREAD_STATUS
@interface RocksDBThreadStatus ()
@property (nonatomic, assign) uint64_t threadId;
@property (nonatomic, assign) RocksDBThreadType threadType;
@property (nonatomic, copy) NSString *databaseName;
@property (nonatomic, copy) NSString *columnFamilyname;
@property (nonatomic, assign) RocksDBOperationType operationType;
@property (nonatomic, assign) RocksDBStateType stateType;
@end
#endif

#pragma mark - Impl

@implementation RocksDBEnv
@synthesize env = _env;

#pragma mark - Lifecycle

+ (instancetype)envWithLowPriorityThreadCount:(int)lowPrio andHighPriorityThreadCount:(int)highPrio
{
	RocksDBEnv *instance = [RocksDBEnv new];
	[instance setBackgroundThreads:lowPrio priority:RocksDBEnvPriorityLow];
	[instance setBackgroundThreads:highPrio priority:RocksDBEnvPriorityHigh];
	return instance;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		_env = rocksdb::Env::Default();
	}
	return self;
}

- (instancetype)initWithEnv:(rocksdb::Env *)env
{
	self = [super init];
	if (self) {
		_env = env;
	}
	return self;
}

- (void)dealloc
{
	@synchronized(self) {
		_env = nullptr;
	}
}

#pragma mark - Threads

- (void)setBackgroundThreads:(int)numThreads priority:(RocksDBEnvPriority)priority
{
	if (numThreads <= 0) numThreads = 1;
	_env->SetBackgroundThreads(numThreads, [self getPriority:priority]);
}

- (int)getBackgroundThreads:(RocksDBEnvPriority)priority
{
	return _env->GetBackgroundThreads([self getPriority:priority]);
}

- (rocksdb::Env::Priority)getPriority:(RocksDBEnvPriority)priority
{
	switch(priority){
		case RocksDBEnvPriorityBottom:
			return rocksdb::Env::BOTTOM;
		case RocksDBEnvPriorityLow:
			return rocksdb::Env::LOW;
		case RocksDBEnvPriorityHigh:
			return rocksdb::Env::HIGH;
		case RocksDBEnvPriorityTotal:
			return rocksdb::Env::TOTAL;
		case RocksDBEnvPriorityUser:
			return rocksdb::Env::USER;
	}
}

- (void)incBackgroundThreadsIfNeeded:(int)number priority:(RocksDBEnvPriority)priority
{
	_env->IncBackgroundThreadsIfNeeded(number, [self getPriority:priority]);
}

- (int)getThreadPoolQueueLen:(RocksDBEnvPriority)priority
{
	return _env->GetThreadPoolQueueLen();
}

- (void)lowerThreadPoolIOPriority:(RocksDBEnvPriority)priority
{
	_env->LowerThreadPoolIOPriority([self getPriority:priority]);
}

- (void)lowerThreadPoolCPUPriority:(RocksDBEnvPriority)priority
{
	_env->LowerThreadPoolCPUPriority([self getPriority:priority]);
}

#if ROCKSDB_USING_THREAD_STATUS

- (NSArray *)threadList
{
	std::vector<rocksdb::ThreadStatus> thread_list;
	_env->GetThreadList(&thread_list);

	NSMutableArray *threadList = [NSMutableArray array];
	for (auto it = std::begin(thread_list); it != std::end(thread_list); ++it) {
		RocksDBThreadStatus *thread = [RocksDBThreadStatus new];
		thread.threadId = (*it).thread_id;
		thread.threadType  = (RocksDBThreadType)(*it).thread_type;
		thread.databaseName = [NSString stringWithCString:(*it).db_name.c_str() encoding:NSUTF8StringEncoding];
		thread.columnFamilyname = [NSString stringWithCString:(*it).cf_name.c_str() encoding:NSUTF8StringEncoding];
		thread.operationType = (RocksDBOperationType)(*it).operation_type;
		thread.stateType = (RocksDBStateType)(*it).state_type;
		[threadList addObject:thread];
	}

	return threadList;
}

#endif

@end
