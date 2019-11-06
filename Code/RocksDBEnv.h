//
//  RocksDBEnv.h
//  ObjectiveRocks
//
//  Created by Iska on 05/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>

#if ROCKSDB_USING_THREAD_STATUS
#import "RocksDBThreadStatus.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Constants for the built-in prefix extractors.
 */
typedef NS_ENUM(NSInteger, RocksDBEnvPriority)
{
	RocksDBEnvPriorityBottom,
	RocksDBEnvPriorityLow,
	RocksDBEnvPriorityHigh,
	RocksDBEnvPriorityTotal,
	RocksDBEnvPriorityUser
};

/**
 All file operations (and other operating system calls) issued by the RocksDB implementation are routed through an
 `RocksDBEnv` object. Currently `RocksDBEnv` only exposes the high & low priority thread pool parameters.
 */
@interface RocksDBEnv : NSObject

/**
 Initializes a new Env instane with the given high & low priority background threads.

 @param lowPrio The count of thread for the high priority queue.
 @param highPrio The count of thread for the low priority queue.
 @return A newly-initialized instance with the given number of threads.
 */
+ (instancetype)envWithLowPriorityThreadCount:(int)lowPrio andHighPriorityThreadCount:(int)highPrio;

/**  @brief Sets the count of thread for the given priority queue. */
- (void)setBackgroundThreads:(int)numThreads priority:(RocksDBEnvPriority)priority;

/**  @brief Sets the count of thread for the given priority queue. */
- (int)getBackgroundThreads:(RocksDBEnvPriority)priority;

/**
 Enlarge number of background worker threads of a specific thread pool
 for this environment if it is smaller than specified. 'LOW' is the default
 pool.
 @param number the number of threads.
 @param priority for specific thread pool
 */
- (void)incBackgroundThreadsIfNeeded:(int)number priority:(RocksDBEnvPriority)priority;

/**
 Returns the length of the queue associated with the specified
 thread pool.
 @param priority the priority id of a specified thread pool.
 @return the thread pool queue length.
 */
- (int) getThreadPoolQueueLen:(RocksDBEnvPriority)priority;

/**
 Lower IO priority for threads from the specified pool.
 @param priority the priority id of a specified thread pool.
 */
- (void) lowerThreadPoolIOPriority:(RocksDBEnvPriority)priority;

/**
 Lower CPU priority for threads from the specified pool.
 @param priority the priority id of a specified thread pool.
 */
- (void) lowerThreadPoolCPUPriority:(RocksDBEnvPriority)priority;

#if ROCKSDB_USING_THREAD_STATUS
/**
 Returns an array with the status of all threads that belong to the current Env.

 @see RocksDBThreadStatus

 @warning This method is not available in RocksDB Lite.
 */
- (NSArray<RocksDBThreadStatus *> *)threadList;
#endif

@end

NS_ASSUME_NONNULL_END
