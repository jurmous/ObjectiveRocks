//
//  RocksDBWriteBatchBase.mm
//  ObjectiveRocks
//

#import "RocksDBWriteBatchBase.h"
#import "RocksDBWriteBatchBase+Private.h"
#import "RocksDBWriteBatch+Private.h"
#import "RocksDBColumnFamilyHandle.h"
#import "RocksDBColumnFamilyHandle+Private.h"
#import "RocksDBSlice+Private.h"
#import "RocksDBRange.h"
#import "RocksDBError.h"

#import <rocksdb/write_batch_base.h>
#import <rocksdb/write_batch.h>

@interface RocksDBWriteBatchBase ()
{
	RocksDBColumnFamilyHandle *_columnFamily;
}
@property (nonatomic, assign) rocksdb::WriteBatchBase *writeBatchBase;
@end

@implementation RocksDBWriteBatchBase
@synthesize writeBatchBase = _writeBatchBase;

#pragma mark - Lifecycle

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

- (void)singleDelete:(NSData *)key
{
	[self singleDelete:key inColumnFamily:_columnFamily];
}

- (void)singleDelete:(NSData *)key inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	if (key != nil) {
		_writeBatchBase->SingleDelete(columnFamily.columnFamily, SliceFromData(key));
	}
}

- (BOOL)deleteRange:(RocksDBKeyRange *)range
			  error:(NSError * _Nullable __autoreleasing *)error
{
	return [self deleteRange:range inColumnFamily:_columnFamily error:error];
}

- (BOOL)deleteRange:(RocksDBKeyRange *)range
	 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			  error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Slice startSlice = SliceFromData(range.start);
	rocksdb::Slice endSlice = SliceFromData(range.end);

	rocksdb::Status status = _writeBatchBase->DeleteRange(columnFamily.columnFamily, startSlice, endSlice);
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
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

#pragma mark - Save Point

- (void)setSavePoint
{
	_writeBatchBase->SetSavePoint();
}

- (BOOL)rollbackToSavePoint:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->RollbackToSavePoint();
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

- (BOOL)popSavePoint:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->PopSavePoint();
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
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

- (void)setMaxBytes:(size_t)maxBytes
{
	_writeBatchBase->SetMaxBytes(maxBytes);
}

@end
