//
//  ObjectiveRocks.m
//  ObjectiveRocks
//
//  Created by Iska on 15/11/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDB.h"

#import "RocksDBOptions+Private.h"

#import "RocksDBColumnFamily.h"
#import "RocksDBColumnFamily+Private.h"

#import "RocksDBEnv.h"
#import "RocksDBEnv+Private.h"

#import "RocksDBOptions.h"
#import "RocksDBReadOptions.h"
#import "RocksDBWriteOptions.h"

#import "RocksDBCompactRangeOptions+Private.h"

#import "RocksDBIterator+Private.h"
#import "RocksDBWriteBatch+Private.h"

#import "RocksDBSnapshot.h"
#import "RocksDBSnapshot+Private.h"

#import "RocksDBError.h"
#import "RocksDBSlice.h"

#include <rocksdb/db.h>
#include <rocksdb/slice.h>
#include <rocksdb/options.h>

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))
#import "RocksDBColumnFamilyMetaData+Private.h"
#import "RocksDBIndexedWriteBatch+Private.h"
#import "RocksDBProperties.h"
#endif

#pragma mark -

@interface RocksDBColumnFamilyDescriptor (Private)
@property (nonatomic, assign) std::vector<rocksdb::ColumnFamilyDescriptor> *columnFamilies;
@end

@interface RocksDB ()
{
	NSString *_path;
	rocksdb::DB *_db;
	rocksdb::ColumnFamilyHandle *_columnFamily;
	std::vector<rocksdb::ColumnFamilyHandle *> *_columnFamilyHandles;

	NSMutableArray *_columnFamilies;

	RocksDBOptions *_options;
	RocksDBReadOptions *_readOptions;
	RocksDBWriteOptions *_writeOptions;
}
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) rocksdb::DB *db;
@property (nonatomic, assign) rocksdb::ColumnFamilyHandle *columnFamily;
@property (nonatomic, strong) RocksDBOptions *options;
@property (nonatomic, strong) RocksDBReadOptions *readOptions;
@property (nonatomic, strong) RocksDBWriteOptions *writeOptions;
@end

@implementation RocksDB
@synthesize path = _path;
@synthesize db = _db;
@synthesize columnFamily = _columnFamily;
@synthesize options = _options;
@synthesize readOptions = _readOptions;
@synthesize writeOptions = _writeOptions;

#pragma mark - Lifecycle

+ (instancetype)databaseAtPath:(NSString *)path andOptions:(RocksDBOptions *)options
{
	RocksDB *rocks = [[RocksDB alloc] initWithPath:path withOptions:options];

	if ([rocks openDatabaseReadOnly:NO] == NO) {
		return nil;
	}
	return rocks;
}

+ (instancetype)databaseAtPath:(NSString *)path
				columnFamilies:(RocksDBColumnFamilyDescriptor *)descriptor
					andOptions:(RocksDBOptions *)options
{
	RocksDB *rocks = [[RocksDB alloc] initWithPath:path withOptions:options];

	if ([rocks openColumnFamilies:descriptor readOnly:NO] == NO) {
		return nil;
	}
	return rocks;
}

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))

+ (instancetype)databaseForReadOnlyAtPath:(NSString *)path
							   andOptions:(RocksDBOptions *)options
{
	RocksDB *rocks = [[RocksDB alloc] initWithPath:path withOptions:options];

	if ([rocks openDatabaseReadOnly:YES] == NO) {
		return nil;
	}
	return rocks;
}

+ (instancetype)databaseForReadOnlyAtPath:(NSString *)path
						   columnFamilies:(RocksDBColumnFamilyDescriptor *)descriptor
							   andOptions:(RocksDBOptions *)options
{
	RocksDB *rocks = [[RocksDB alloc] initWithPath:path withOptions:options];

	if ([rocks openColumnFamilies:descriptor readOnly:YES] == NO) {
		return nil;
	}
	return rocks;
}

#endif

- (instancetype)initWithPath:(NSString *)path withOptions:(RocksDBOptions *)options
{
	self = [super init];
	if (self) {
		_path = [path copy];
		_options = options;
		_readOptions = [RocksDBReadOptions new];
		_writeOptions = [RocksDBWriteOptions new];
	}
	return self;
}

- (void)dealloc
{
	[self close];
}

- (void)close
{
	@synchronized(self) {
		[_columnFamilies makeObjectsPerformSelector:@selector(close)];

		if (_columnFamilyHandles != nullptr) {
			delete _columnFamilyHandles;
			_columnFamilyHandles = nullptr;
		}

		if (_db != nullptr) {
			delete _db;
			_db = nullptr;
		}
	}
}

- (BOOL)isClosed {
	@synchronized(self) {
		return _db == nullptr;
	}
}

#pragma mark - Name & Env

- (NSString *)name
{
	return [NSString stringWithUTF8String:_db->GetName().c_str()];
}

- (RocksDBEnv *)env
{
	return [[RocksDBEnv alloc] initWithEnv:_db->GetEnv()];
}

#pragma mark - Open

- (BOOL)openDatabaseReadOnly:(BOOL)readOnly
{
	rocksdb::Status status;
	if (readOnly) {
		status = rocksdb::DB::OpenForReadOnly(_options.options, _path.UTF8String, &_db);
	} else {
		status = rocksdb::DB::Open(_options.options, _path.UTF8String, &_db);
	}

	if (!status.ok()) {
		NSLog(@"Error opening database: %@", [RocksDBError errorWithRocksStatus:status]);
		[self close];
		return NO;
	}
	_columnFamily = _db->DefaultColumnFamily();

	return YES;
}

- (BOOL)openColumnFamilies:(RocksDBColumnFamilyDescriptor *)descriptor readOnly:(BOOL)readOnly
{
	rocksdb::Status status;
	std::vector<rocksdb::ColumnFamilyDescriptor> *columnFamilies = descriptor.columnFamilies;
	_columnFamilyHandles = new std::vector<rocksdb::ColumnFamilyHandle *>;

	if (readOnly) {
		status = rocksdb::DB::OpenForReadOnly(_options.options,
											  _path.UTF8String,
											  *columnFamilies,
											  _columnFamilyHandles,
											  &_db);
	} else {
		status = rocksdb::DB::Open(_options.options,
								   _path.UTF8String,
								   *columnFamilies,
								   _columnFamilyHandles,
								   &_db);
	}


	if (!status.ok()) {
		NSLog(@"Error opening database: %@", [RocksDBError errorWithRocksStatus:status]);
		[self close];
		return NO;
	}
	_columnFamily = _db->DefaultColumnFamily();

	return YES;
}

#pragma mark - Column Families

+ (NSArray *)listColumnFamiliesInDatabaseAtPath:(NSString *)path
{
	std::vector<std::string> names;

	rocksdb::Status status = rocksdb::DB::ListColumnFamilies(rocksdb::Options(), path.UTF8String, &names);
	if (!status.ok()) {
		NSLog(@"Error listing column families in database at %@: %@", path, [RocksDBError errorWithRocksStatus:status]);
	}

	NSMutableArray *columnFamilies = [NSMutableArray array];
	for(auto it = std::begin(names); it != std::end(names); ++it) {
		[columnFamilies addObject:[[NSString alloc] initWithCString:it->c_str() encoding:NSUTF8StringEncoding]];
	}
	return columnFamilies;
}

- (RocksDBColumnFamily *)createColumnFamilyWithName:(NSString *)name
											   andOptions:(RocksDBColumnFamilyOptions *)columnFamilyOptions
{
	rocksdb::ColumnFamilyHandle *handle;
	rocksdb::Status status = _db->CreateColumnFamily(columnFamilyOptions.options, name.UTF8String, &handle);
	if (!status.ok()) {
		NSLog(@"Error creating column family: %@", [RocksDBError errorWithRocksStatus:status]);
		return nil;
	}

	RocksDBOptions *options = [[RocksDBOptions alloc] initWithDatabaseOptions:_options.databaseOptions
													   andColumnFamilyOptions:columnFamilyOptions];

	RocksDBColumnFamily *columnFamily = [[RocksDBColumnFamily alloc] initWithDBInstance:_db
																		   columnFamily:handle
																			 andOptions:options];
	return columnFamily;
}

- (NSArray *)columnFamilies
{
	if (_columnFamilyHandles == nullptr) {
		return nil;
	}

	if (_columnFamilies == nil) {
		_columnFamilies = [NSMutableArray new];
		for(auto it = std::begin(*_columnFamilyHandles); it != std::end(*_columnFamilyHandles); ++it) {
			RocksDBColumnFamily *columnFamily = [[RocksDBColumnFamily alloc] initWithDBInstance:_db
																				   columnFamily:*it
																					 andOptions:_options];
			[_columnFamilies addObject:columnFamily];
		}
	}

	return _columnFamilies;
}

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))

- (RocksDBColumnFamilyMetaData *)columnFamilyMetaData
{
	rocksdb::ColumnFamilyMetaData metadata;
	_db->GetColumnFamilyMetaData(_columnFamily, &metadata);

	RocksDBColumnFamilyMetaData *columnFamilyMetaData = [[RocksDBColumnFamilyMetaData alloc] initWithMetaData:metadata];
	return columnFamilyMetaData;
}

#endif

#pragma mark - Read/Write Options

- (void)setDefaultReadOptions:(RocksDBReadOptions *)readOptions writeOptions:(RocksDBWriteOptions *)writeOptions
{
	_readOptions = readOptions;
	_writeOptions = writeOptions;
}

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))

#pragma mark - Peroperties

- (NSString *)valueForProperty:(RocksDBProperty)property
{
	std::string value;
	bool ok = _db->GetProperty(_columnFamily,
							   SliceFromData([ResolveProperty(property) dataUsingEncoding:NSUTF8StringEncoding]),
							   &value);
	if (!ok) {
		return nil;
	}

	NSData *data = DataFromSlice(rocksdb::Slice(value));
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (uint64_t)valueForIntProperty:(RocksDBIntProperty)property
{
	uint64_t value;
	bool ok = _db->GetIntProperty(_columnFamily,
								  SliceFromData([ResolveIntProperty(property) dataUsingEncoding:NSUTF8StringEncoding]),
								  &value);
	if (!ok) {
		return 0;
	}
	return value;
}

#endif

#pragma mark - Write Operations

- (BOOL)setData:(NSData *)anObject forKey:(NSData *)aKey error:(NSError * __autoreleasing *)error
{
	return [self setData:anObject forKey:aKey writeOptions:_writeOptions error:error];
}

- (BOOL)setData:(NSData *)anObject
		 forKey:(NSData *)aKey
   writeOptions:(RocksDBWriteOptions *) writeOptions
		  error:(NSError * __autoreleasing *)error
{

	rocksdb::Status status = _db->Put(writeOptions.options,
									  _columnFamily,
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

#pragma mark - Merge Operations

- (BOOL)mergeData:(NSData *)anObject forKey:(NSData *)aKey error:(NSError * __autoreleasing *)error
{
	return [self mergeData:anObject forKey:aKey writeOptions:_writeOptions error:error];
}

- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
	 writeOptions:(RocksDBWriteOptions *)writeOptions
			error:(NSError * __autoreleasing *)error
{

	rocksdb::Status status = _db->Merge(_writeOptions.options,
										_columnFamily,
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

#pragma mark - Read Operations

- (NSData *)dataForKey:(NSData *)aKey error:(NSError * __autoreleasing *)error
{
	return [self dataForKey:aKey readOptions:_readOptions error:error];
}

- (NSData *)dataForKey:(NSData *)aKey
		   readOptions:(RocksDBReadOptions *)readOptions
				 error:(NSError * __autoreleasing *)error
{

	std::string value;
	rocksdb::Status status = _db->Get(readOptions.options,
									  _columnFamily,
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

#pragma mark - Delete Operations

- (BOOL)deleteDataForKey:(NSData *)aKey error:(NSError * __autoreleasing *)error
{
	return [self deleteDataForKey:aKey writeOptions:_writeOptions error:error];
}

- (BOOL)deleteDataForKey:(NSData *)aKey
			writeOptions:(RocksDBWriteOptions *)writeOptions
				   error:(NSError * __autoreleasing *)error
{

	rocksdb::Status status = _db->Delete(writeOptions.options,
										 _columnFamily,
										 SliceFromData(aKey));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

#pragma mark - Batch Writes

- (RocksDBWriteBatch *)writeBatch
{
	return [[RocksDBWriteBatch alloc] initWithColumnFamily:_columnFamily];
}

- (BOOL)performWriteBatch:(void (^)(RocksDBWriteBatch *batch, RocksDBWriteOptions *options))batchBlock
					error:(NSError * __autoreleasing *)error
{
	if (batchBlock == nil) return NO;

	RocksDBWriteBatch *writeBatch = [self writeBatch];
	RocksDBWriteOptions *writeOptions = [_writeOptions copy];

	batchBlock(writeBatch, writeOptions);
	rocksdb::WriteBatch *batch = writeBatch.writeBatchBase->GetWriteBatch();
	rocksdb::Status status = _db->Write(writeOptions.options, batch);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

- (BOOL)applyWriteBatch:(RocksDBWriteBatch *)writeBatch
		   writeOptions:(RocksDBWriteOptions *)writeOptions
				  error:(NSError * __autoreleasing *)error
{
	rocksdb::WriteBatch *batch = writeBatch.writeBatchBase->GetWriteBatch();
	rocksdb::Status status = _db->Write(writeOptions.options, batch);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))

- (RocksDBIndexedWriteBatch *)indexedWriteBatch
{
	return [[RocksDBIndexedWriteBatch alloc] initWithDBInstance:_db
												   columnFamily:_columnFamily
													readOptions:_readOptions];
}

- (BOOL)performIndexedWriteBatch:(void (^)(RocksDBIndexedWriteBatch *batch, RocksDBWriteOptions *options))batchBlock
						   error:(NSError * __autoreleasing *)error
{
	if (batchBlock == nil) return NO;

	RocksDBIndexedWriteBatch *writeBatch = [self indexedWriteBatch];
	RocksDBWriteOptions *writeOptions = [_writeOptions copy];

	batchBlock(writeBatch, writeOptions);
	rocksdb::WriteBatch *batch = writeBatch.writeBatchBase->GetWriteBatch();
	rocksdb::Status status = _db->Write(writeOptions.options, batch);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

#endif

#pragma mark - Iteration

- (RocksDBIterator *)iterator
{
	return [self iteratorWithReadOptions:_readOptions];
}

- (RocksDBIterator *)iteratorWithReadOptions:(RocksDBReadOptions *)readOptions
{
	rocksdb::Iterator *iterator = _db->NewIterator(readOptions.options,
												   _columnFamily);

	return [[RocksDBIterator alloc] initWithDBIterator:iterator];
}

#pragma mark - Snapshot

- (RocksDBSnapshot *)snapshot
{
	return [self snapshotWithReadOptions:[_readOptions copy]];
}

- (RocksDBSnapshot *)snapshotWithReadOptions:(RocksDBReadOptions *)readOptions
{
	rocksdb::ReadOptions options = readOptions.options;
	options.snapshot = _db->GetSnapshot();
	readOptions.options = options;

	RocksDBSnapshot *snapshot = [[RocksDBSnapshot alloc] initWithDBInstance:_db columnFamily:_columnFamily andReadOptions:readOptions];
	return snapshot;
}

#pragma mark - Compaction

- (BOOL)compactRange:(RocksDBKeyRange *)range
		 withOptions:(RocksDBCompactRangeOptions *)rangeOptions
			   error:(NSError * __autoreleasing *)error
{

	rocksdb::Slice startSlice = SliceFromData(range.start);
	rocksdb::Slice endSlice = SliceFromData(range.end);

	rocksdb::Status status = _db->CompactRange(rangeOptions.options, _columnFamily, &startSlice, &endSlice);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

#pragma mark - WAL

- (BOOL)syncWal:(NSError *__autoreleasing  _Nullable *)error
{
	rocksdb::Status status = _db->SyncWAL();
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

- (BOOL)flushWal:(BOOL)sync error:(NSError *__autoreleasing  _Nullable *)error
{
	rocksdb::Status status = _db->FlushWAL(sync);
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

#pragma mark Verification

- (BOOL)verifyChecksum:(NSError *__autoreleasing  _Nullable *)error
{
	rocksdb::Status status = _db->VerifyChecksum();
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

#pragma mark Stats

- (BOOL)resetStats:(NSError *__autoreleasing  _Nullable *)error
{
	rocksdb::Status status = _db->ResetStats();
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

@end
