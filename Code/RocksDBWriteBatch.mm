//
//  RocksDBWriteBatch.m
//  ObjectiveRocks
//
//  Created by Iska on 02/12/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDBWriteBatch.h"
#import "RocksDBWriteBatch+Private.h"
#import "RocksDBColumnFamilyHandle.h"
#import "RocksDBColumnFamilyHandle+Private.h"
#import "RocksDBSlice+Private.h"

#import <rocksdb/write_batch_base.h>
#import <rocksdb/write_batch.h>

@interface RocksDBWriteBatch ()
{
	RocksDBColumnFamilyHandle *_columnFamily;
}
@property (nonatomic, assign) rocksdb::WriteBatchBase *writeBatchBase;
@end

@implementation RocksDBWriteBatch
@synthesize writeBatchBase = _writeBatchBase;

#pragma mark - Lifecycle

- (instancetype)initWithColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	return [self initWithNativeWriteBatch:new rocksdb::WriteBatch()
							 columnFamily:columnFamily];
}

- (instancetype)initWithNativeWriteBatch:(rocksdb::WriteBatchBase *)writeBatchBase
							columnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	self = [super init];
	if (self) {
		_writeBatchBase = writeBatchBase;
		_columnFamily = columnFamily;
	}
	return self;
}

- (void)dealloc
{
	@synchronized(self) {
		if (_writeBatchBase != nullptr) {
			delete _writeBatchBase;
			_writeBatchBase = nullptr;
		}
	}
}

#pragma mark - Put

- (void)setData:(NSData *)anObject forKey:(NSData *)aKey
{
	[self setData:anObject forKey:aKey inColumnFamily:_columnFamily];
}

- (void)setData:(NSData *)anObject forKey:(NSData *)aKey inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	if (aKey != nil && anObject != nil) {
		_writeBatchBase->Put(columnFamily.columnFamily, SliceFromData(aKey), SliceFromData(anObject));
	}
}

#pragma mark - Merge

- (void)mergeData:(NSData *)anObject forKey:(NSData *)aKey
{
	[self mergeData:anObject forKey:aKey inColumnFamily:_columnFamily];
}

- (void)mergeData:(NSData *)anObject forKey:(NSData *)aKey inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	if (aKey != nil && anObject != nil) {
		_writeBatchBase->Merge(columnFamily.columnFamily, SliceFromData(aKey), SliceFromData(anObject));
	}
}

#pragma mark - Delete

- (void)deleteDataForKey:(NSData *)aKey
{
	[self deleteDataForKey:aKey inColumnFamily:_columnFamily];
}

- (void)deleteDataForKey:(NSData *)aKey inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	if (aKey != nil) {
		_writeBatchBase->Delete(columnFamily.columnFamily, SliceFromData(aKey));
	}
}

#pragma mark - 

- (void)putLogData:(NSData *)logData;
{
	if (logData != nil) {
		_writeBatchBase->PutLogData(SliceFromData(logData));
	}
}

- (void)clear
{
	_writeBatchBase->Clear();
}

#pragma mark - Meta

- (int)count
{
	return _writeBatchBase->GetWriteBatch()->Count();
}

- (NSData *)data
{
	std::string rep = _writeBatchBase->GetWriteBatch()->Data();
	return DataFromSlice(rocksdb::Slice(rep));
}

- (size_t)dataSize
{
	return _writeBatchBase->GetWriteBatch()->GetDataSize();
}

@end
