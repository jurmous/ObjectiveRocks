//
//  RocksDBWriteBatch.m
//  ObjectiveRocks
//
//  Created by Iska on 02/12/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDBWriteBatch.h"
#import "RocksDBWriteBatch+Private.h"
#import "RocksDBWriteBatchBase+Private.h"
#import "RocksDBColumnFamilyHandle.h"
#import "RocksDBColumnFamilyHandle+Private.h"
#import "RocksDBSlice+Private.h"

#import <rocksdb/write_batch_base.h>
#import <rocksdb/write_batch.h>

@interface RocksDBSavePoint ()
@property (nonatomic, assign) size_t size;
@property (nonatomic, assign) int count;
@property (nonatomic, assign) uint32_t contentFlags;
@end

@interface RocksDBWriteBatch ()
@property (nonatomic, assign) rocksdb::WriteBatch *writeBatch;
@end

@implementation RocksDBSavePoint

- (instancetype)initWithSize:(size_t)size count:(int)count contentFlags:(uint32_t)contentFlags
{
	self = [super init];
	if (self) {
		self.size = size;
		self.count = count;
		self.contentFlags = contentFlags;
	}
	return self;
}

@end

@implementation RocksDBWriteBatch : RocksDBWriteBatchBase
@synthesize writeBatch = _writeBatch;

#pragma mark - Lifecycle

- (instancetype)init
{
	return [self initWithNativeWriteBatch:new rocksdb::WriteBatch()];
}

- (instancetype)initWithNativeWriteBatch:(rocksdb::WriteBatch *)writeBatch
{
	self = [self initWithNativeWriteBatchBase:writeBatch];
	if (self) {
		_writeBatch = writeBatch;
	}
	return self;
}

- (void)dealloc
{
	@synchronized(self) {
		if (_writeBatch != nullptr) {
			// No need to delete since it is deleted by super
			_writeBatch = nullptr;
		}
	}
}

- (BOOL)hasPut
{
	return _writeBatch->HasPut();
}

- (BOOL)hasDelete
{
	return _writeBatch->HasDelete();
}

- (BOOL)hasSingleDelete
{
	return _writeBatch->HasSingleDelete();
}

- (BOOL)hasDeleteRange
{
	return _writeBatch->HasDeleteRange();
}

- (BOOL)hasMerge
{
	return _writeBatch->HasMerge();
}

- (BOOL)hasBeginPrepare
{
	return _writeBatch->HasBeginPrepare();
}

- (BOOL)hasEndPrepare
{
	return _writeBatch->HasEndPrepare();
}

- (BOOL)hasCommit
{
	return _writeBatch->HasCommit();
}

- (BOOL)hasRollback
{
	return _writeBatch->HasRollback();
}

- (void)markWalTerminationPoint
{
	_writeBatch->MarkWalTerminationPoint();
}

- (RocksDBSavePoint *)getWalTerminationPoint
{
	rocksdb::SavePoint savePoint = _writeBatch->GetWalTerminationPoint();

	return [[RocksDBSavePoint alloc] initWithSize:savePoint.size
											count:savePoint.count
									 contentFlags:savePoint.content_flags];

}

@end
