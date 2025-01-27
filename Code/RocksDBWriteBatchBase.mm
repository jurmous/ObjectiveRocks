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
@property (nonatomic, assign) rocksdb::WriteBatchBase *writeBatchBase;
@end

@implementation RocksDBWriteBatchBase
@synthesize writeBatchBase = _writeBatchBase;

#pragma mark - Lifecycle

- (instancetype)initWithNativeWriteBatchBase:(rocksdb::WriteBatchBase *)writeBatchBase
{
	self = [super init];
	if (self) {
		_writeBatchBase = writeBatchBase;
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

- (BOOL)setData:(NSData *)anObject
		 forKey:(NSData *)aKey
		  error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->Put(SliceFromData(aKey), SliceFromData(anObject));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

- (BOOL)setData:(NSData *)anObject
		 forKey:(NSData *)aKey
 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
		  error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->Put(columnFamily.columnFamily,
												  SliceFromData(aKey),
												  SliceFromData(anObject));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

#pragma mark - Merge

- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
			error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->Merge(SliceFromData(aKey),
													SliceFromData(anObject));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
   inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->Merge(columnFamily.columnFamily,
													SliceFromData(aKey),
													SliceFromData(anObject));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

#pragma mark - Delete

- (BOOL)deleteDataForKey:(NSData *)aKey
				   error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->Delete(SliceFromData(aKey));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

- (BOOL)deleteDataForKey:(NSData *)aKey
		  inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
				   error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->Delete(columnFamily.columnFamily, SliceFromData(aKey));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

- (BOOL)singleDelete:(NSData *)key
			   error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->SingleDelete(SliceFromData(key));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

- (BOOL)singleDelete:(NSData *)key
	  inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			   error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Status status = _writeBatchBase->SingleDelete(columnFamily.columnFamily, SliceFromData(key));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

- (BOOL)deleteRange:(RocksDBKeyRange *)range
			  error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Slice startSlice = SliceFromData(range.start);
	rocksdb::Slice endSlice = SliceFromData(range.end);

	rocksdb::Status status = _writeBatchBase->DeleteRange(startSlice, endSlice);
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
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

- (BOOL)putLogData:(NSData *)logData
			 error:(NSError * _Nullable __autoreleasing *)error;
{
	rocksdb::Status status = _writeBatchBase->PutLogData(SliceFromData(logData));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
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

- (RocksDBWriteBatch *)getWriteBatch
{
	rocksdb::WriteBatch *batch = self.writeBatchBase->GetWriteBatch();
	return [[RocksDBWriteBatch alloc] initWithNativeWriteBatchBase:batch];
}

@end
