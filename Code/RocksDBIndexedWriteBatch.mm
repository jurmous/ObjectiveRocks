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
#import "RocksDBWriteBatchIterator+Private.h"
#import "RocksDBColumnFamilyHandle+Private.h"

#import "RocksDBError.h"
#import "RocksDBSlice.h"

#import <rocksdb/db.h>
#import <rocksdb/options.h>
#import <rocksdb/utilities/write_batch_with_index.h>

@interface RocksDBIndexedWriteBatch ()
{
	rocksdb::DB *_db;
	RocksDBReadOptions *_readOptions;
	rocksdb::WriteBatchWithIndex *_writeBatchWithIndex;
}
@end

@implementation RocksDBIndexedWriteBatch

#pragma mark - Lifecycle 

- (instancetype)initWithDBInstance:(rocksdb::DB *)db
					  columnFamily:(RocksDBColumnFamilyHandle *)columnFamily
					   readOptions:(RocksDBReadOptions *)readOptions
{
	self = [super initWithNativeWriteBatch:new rocksdb::WriteBatchWithIndex()
							  columnFamily:columnFamily];
	if (self) {
		_db = db;
		_readOptions = [readOptions copy];
		_writeBatchWithIndex = static_cast<rocksdb::WriteBatchWithIndex *>(self.writeBatchBase);
	}
	return self;
}

#pragma mark - Queries

- (NSData *)dataForKey:(NSData *)aKey
		inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
				 error:(NSError * __autoreleasing *)error
{
	rocksdb::ColumnFamilyHandle *columnFamilyHandle = columnFamily != nil ? columnFamily.columnFamily : nullptr;

	std::string value;
	rocksdb::Status status = _writeBatchWithIndex->GetFromBatch(columnFamilyHandle,
																_db->GetDBOptions(),
																SliceFromData(aKey),
																&value);
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return nil;
	}

	return DataFromSlice(rocksdb::Slice(value));
}

- (NSData *)dataForKeyIncludingDatabase:(NSData *)aKey
						 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
							readOptions:(void (^)(RocksDBReadOptions *readOptions))readOptionsBlock
								  error:(NSError * __autoreleasing *)error
{
	RocksDBReadOptions *readOptions = [_readOptions copy];
	if (readOptionsBlock) {
		readOptionsBlock(readOptions);
	}

	rocksdb::ColumnFamilyHandle *columnFamilyHandle = columnFamily != nil ? columnFamily.columnFamily : nullptr;

	std::string value;
	rocksdb::Status status = _writeBatchWithIndex->GetFromBatchAndDB(_db,
																	 readOptions.options,
																	 columnFamilyHandle,
																	 SliceFromData(aKey),
																	 &value);
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return nil;
	}

	return DataFromSlice(rocksdb::Slice(value));
}

#pragma mark - Iterator

- (RocksDBWriteBatchIterator *)iterator
{
	rocksdb::WBWIIterator *nativeIterator = _writeBatchWithIndex->NewIterator(self.columnFamily.columnFamily);
	return [[RocksDBWriteBatchIterator alloc] initWithWriteBatchIterator:nativeIterator];
}

@end
