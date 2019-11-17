//
//  RocksDBIndexedWriteBatch.m
//  ObjectiveRocks
//
//  Created by Iska on 20/08/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import "RocksDBIndexedWriteBatch.h"

#import "RocksDB+Private.h"
#import "RocksDBOptions+Private.h"
#import "RocksDBWriteBatch+Private.h"
#import "RocksDBWriteBatchBase+Private.h"
#import "RocksDBWriteBatchIterator+Private.h"
#import "RocksDBColumnFamilyHandle+Private.h"
#import "RocksDBWriteBatch+Private.h"
#import "RocksDBIterator+Private.h"

#import "RocksDBError.h"
#import "RocksDBSlice+Private.h"

#import <rocksdb/db.h>
#import <rocksdb/options.h>
#import <rocksdb/utilities/write_batch_with_index.h>

@interface RocksDBIndexedWriteBatch ()
{
	rocksdb::WriteBatchWithIndex *_writeBatchWithIndex;
}
@property (nonatomic, readonly) rocksdb::WriteBatchWithIndex *writeBatchWithIndex;
@end

@implementation RocksDBIndexedWriteBatch

@synthesize writeBatchWithIndex = _writeBatchWithIndex;

#pragma mark - Lifecycle

- (instancetype)init:(BOOL)overwriteKey
{
	self = [super init];
	if (self) {
		_writeBatchWithIndex = new rocksdb::WriteBatchWithIndex(rocksdb::BytewiseComparator(), 0, overwriteKey);
	}
	return self;
}

- (instancetype)initWithDBInstance:(rocksdb::DB *)db
					   readOptions:(RocksDBReadOptions *)readOptions
{
	self = [super initWithNativeWriteBatchBase:new rocksdb::WriteBatchWithIndex()];
	if (self) {
		_writeBatchWithIndex = static_cast<rocksdb::WriteBatchWithIndex *>(self.writeBatchBase);
	}
	return self;
}

#pragma mark - Iterator

- (RocksDBWriteBatchIterator *)iterator
{
	rocksdb::WBWIIterator *nativeIterator = _writeBatchWithIndex->NewIterator();
	return [[RocksDBWriteBatchIterator alloc] initWithWriteBatchIterator:nativeIterator];
}

- (RocksDBWriteBatchIterator *)iteratorInColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	rocksdb::WBWIIterator *nativeIterator = _writeBatchWithIndex->NewIterator(columnFamily.columnFamily);
	return [[RocksDBWriteBatchIterator alloc] initWithWriteBatchIterator:nativeIterator];
}

- (RocksDBIterator *)iteratorWithBase:(RocksDBIterator *)iterator
{
	rocksdb::Iterator *nativeIterator = _writeBatchWithIndex->NewIteratorWithBase(iterator.iterator);
	return [[RocksDBIterator alloc] initWithDBIterator:nativeIterator];
}

- (RocksDBIterator *)iteratorWithBase:(RocksDBIterator *)iterator
					   inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	rocksdb::Iterator *nativeIterator = _writeBatchWithIndex->NewIteratorWithBase(columnFamily.columnFamily, iterator.iterator);
	return [[RocksDBIterator alloc] initWithDBIterator:nativeIterator];
}

- (NSData *)getFromBatch:(RocksDBDatabaseOptions *)options
					 key:(NSData *)key
				   error:(NSError * __autoreleasing *)error
{
	std::string value;
	rocksdb::Status status = _writeBatchWithIndex->GetFromBatch(options.options, SliceFromData(key), &value);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return nil;
	}

	return DataFromSlice(rocksdb::Slice(value));
}

- (NSData *)getFromBatch:(RocksDBDatabaseOptions *)options
		fromColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
					 key:(NSData *)key
				   error:(NSError * __autoreleasing *)error
{
	std::string value;
	rocksdb::Status status = _writeBatchWithIndex->GetFromBatch(columnFamily.columnFamily, options.options, SliceFromData(key), &value);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return nil;
	}

	return DataFromSlice(rocksdb::Slice(value));
}

- (NSData *)getFromBatchAndDB:(RocksDB *)db
					  options:(RocksDBReadOptions *)options
						  key:(NSData *)key
						error:(NSError * __autoreleasing *)error
{
	std::string value;
	rocksdb::Status status = _writeBatchWithIndex->GetFromBatchAndDB(db.db, options.options, SliceFromData(key), &value);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return nil;
	}

	return DataFromSlice(rocksdb::Slice(value));
}

- (NSData *)getFromBatchAndDB:(RocksDB *)db
					  options:(RocksDBReadOptions *)options
			 fromColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
						  key:(NSData *)key
						error:(NSError * __autoreleasing *)error
{
	std::string value;
	rocksdb::Status status = _writeBatchWithIndex->GetFromBatchAndDB(db.db, options.options, columnFamily.columnFamily, SliceFromData(key), &value);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return nil;
	}

	return DataFromSlice(rocksdb::Slice(value));
}

@end
