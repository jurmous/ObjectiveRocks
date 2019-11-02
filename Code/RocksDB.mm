//
//  ObjectiveRocks.m
//  ObjectiveRocks
//
//  Created by Iska on 15/11/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDB.h"

#import "RocksDBOptions+Private.h"

#import "RocksDBColumnFamilyHandle.h"
#import "RocksDBColumnFamilyHandle+Private.h"

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
#endif

#pragma mark -

@interface RocksDBColumnFamilyDescriptor (Private)
@property (nonatomic, assign) std::vector<rocksdb::ColumnFamilyDescriptor> *columnFamilies;
@end

@interface RocksDB ()
{
	NSString *_path;
	rocksdb::DB *_db;
	std::vector<rocksdb::ColumnFamilyHandle *> *_columnFamilyHandles;

	NSMutableArray *_columnFamilies;

	RocksDBColumnFamilyHandle *_columnFamily;
	RocksDBOptions *_options;
	RocksDBReadOptions *_readOptions;
	RocksDBWriteOptions *_writeOptions;
}
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) rocksdb::DB *db;
@property (nonatomic, strong) RocksDBColumnFamilyHandle *columnFamily;
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
	[self close: nil];
}

- (BOOL)close:(NSError *__autoreleasing  _Nullable *)error
{
	@synchronized(self) {
		[_columnFamilies makeObjectsPerformSelector:@selector(close)];
		[_columnFamilies removeAllObjects];

		if (_columnFamilyHandles != nullptr) {
			delete _columnFamilyHandles;
			_columnFamilyHandles = nullptr;
		}

		if (_db != nullptr) {
			rocksdb::Status status = _db->Close();
			if (!status.ok()) {
				NSError *temp = [RocksDBError errorWithRocksStatus:status];
				if (error && *error == nil) {
					*error = temp;
				}
				return NO;
			}

			delete _db;
			_db = nullptr;
		}
		return YES;
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
	_columnFamily = [[RocksDBColumnFamilyHandle alloc] initWithColumnFamily:_db->DefaultColumnFamily()];

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
	_columnFamily = [[RocksDBColumnFamilyHandle alloc] initWithColumnFamily:_db->DefaultColumnFamily()];

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

- (RocksDBColumnFamilyHandle *)createColumnFamilyWithName:(NSString *)name
											   andOptions:(RocksDBColumnFamilyOptions *)columnFamilyOptions
{
	rocksdb::ColumnFamilyHandle *handle;
	rocksdb::Status status = _db->CreateColumnFamily(columnFamilyOptions.options, name.UTF8String, &handle);
	if (!status.ok()) {
		NSLog(@"Error creating column family: %@", [RocksDBError errorWithRocksStatus:status]);
		return nil;
	}

	RocksDBColumnFamilyHandle *columnFamily = [[RocksDBColumnFamilyHandle alloc] initWithColumnFamily:handle];
	return columnFamily;
}

- (void)dropColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	rocksdb::Status status = _db->DropColumnFamily(columnFamily.columnFamily);
	if (!status.ok()) {
		NSLog(@"Error dropping column family: %@", [RocksDBError errorWithRocksStatus:status]);
		throw [RocksDBError errorWithRocksStatus:status];
	}
}

- (BOOL)dropColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *>*)columnFamilies error:(NSError *__autoreleasing  _Nullable *)error
{
	__block std::vector<rocksdb::ColumnFamilyHandle*> families;
    families.reserve([columnFamilies count]);
    [columnFamilies enumerateObjectsUsingBlock:^(RocksDBColumnFamilyHandle * _Nonnull family, NSUInteger idx, BOOL * _Nonnull stop) {
        families.push_back(family.columnFamily);
    }];

	rocksdb::Status status = _db->DropColumnFamilies(families);
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

- (NSArray *)columnFamilies
{
	if (_columnFamilyHandles == nullptr) {
		return [NSArray init];
	}

	if (_columnFamilies == nil) {
		_columnFamilies = [NSMutableArray new];
		for(auto it = std::begin(*_columnFamilyHandles); it != std::end(*_columnFamilyHandles); ++it) {
			RocksDBColumnFamilyHandle *columnFamily = [[RocksDBColumnFamilyHandle alloc] initWithColumnFamily:*it];
			[_columnFamilies addObject:columnFamily];
		}
	}

	return _columnFamilies;
}

- (RocksDBColumnFamilyHandle *)defaultColumnFamily
{
	return _columnFamily;
}

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))

- (RocksDBColumnFamilyMetaData *)columnFamilyMetaData
{
	rocksdb::ColumnFamilyMetaData metadata;
	_db->GetColumnFamilyMetaData(_columnFamily.columnFamily, &metadata);

	RocksDBColumnFamilyMetaData *columnFamilyMetaData = [[RocksDBColumnFamilyMetaData alloc] initWithMetaData:metadata];
	return columnFamilyMetaData;
}

- (RocksDBColumnFamilyMetaData *)columnFamilyMetaData:(RocksDBColumnFamilyHandle *)columnFamily
{
	rocksdb::ColumnFamilyMetaData metadata;
	_db->GetColumnFamilyMetaData(columnFamily.columnFamily, &metadata);

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

#pragma mark - Properties

- (NSString *)valueForProperty:(NSString *)property
{
	return [self valueForProperty:property inColumnFamily:_columnFamily];
}

- (NSString *)valueForProperty:(NSString *)property inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	std::string value;
	bool ok = _db->GetProperty(columnFamily.columnFamily,
							   SliceFromData([property dataUsingEncoding:NSUTF8StringEncoding]),
							   &value);
	if (!ok) {
		return nil;
	}

	NSData *data = DataFromSlice(rocksdb::Slice(value));
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (uint64_t)valueForIntProperty:(NSString *)property
{
	return [self valueForIntProperty:property inColumnFamily:_columnFamily];
}

- (uint64_t)valueForIntProperty:(NSString *)property inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	uint64_t value;
	bool ok = _db->GetIntProperty(columnFamily.columnFamily,
								  SliceFromData([property dataUsingEncoding:NSUTF8StringEncoding]),
								  &value);
	if (!ok) {
		return 0;
	}
	return value;
}

- (NSDictionary<NSString *,NSString *> *)valueForMapProperty:(NSString *)property
{
	return [self valueForMapProperty:property inColumnFamily:_columnFamily];
}

- (NSDictionary<NSString *,NSString *> *)valueForMapProperty:(NSString *)property
											inColumnFamily:(nonnull RocksDBColumnFamilyHandle *)columnFamily
{
	NSMutableDictionary<NSString *,NSString *> *newDictionary = [NSMutableDictionary dictionary];

	std::map<std::string, std::string> value;

	bool ok = _db->GetMapProperty(_columnFamily.columnFamily,
								  SliceFromData([property dataUsingEncoding:NSUTF8StringEncoding]),
								  &value);
	if (ok) {
		for(auto const &entry : value) {
			NSString* newKey = [NSString stringWithUTF8String:entry.first.c_str()];
			newDictionary[newKey] = [NSString stringWithUTF8String:entry.second.c_str()];
		}
	}

	return newDictionary;
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
	return [self setData:anObject forKey:aKey forColumnFamily:_columnFamily writeOptions:_writeOptions error:error];
}

- (BOOL)setData:(NSData *)anObject
		 forKey:(NSData *)aKey
forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
		  error:(NSError * __autoreleasing *)error
{
	return [self setData:anObject forKey:aKey forColumnFamily:columnFamily writeOptions:_writeOptions error:error];
}

- (BOOL)setData:(NSData *)anObject
		 forKey:(NSData *)aKey
forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
   writeOptions:(RocksDBWriteOptions *) writeOptions
		  error:(NSError * __autoreleasing *)error
{
	rocksdb::Status status = _db->Put(writeOptions.options,
									  columnFamily.columnFamily,
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
	return [self mergeData:anObject forKey:aKey forColumnFamily:_columnFamily writeOptions:writeOptions error:error];
}


- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
  forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			error:(NSError * __autoreleasing *)error
{
	return [self mergeData:anObject forKey:aKey forColumnFamily:columnFamily writeOptions:_writeOptions error:error];
}

- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
  forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
	 writeOptions:(RocksDBWriteOptions *)writeOptions
			error:(NSError * __autoreleasing *)error
{
	rocksdb::Status status = _db->Merge(_writeOptions.options,
										columnFamily.columnFamily,
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
	return [self dataForKey:aKey inColumnFamily:_columnFamily readOptions:_readOptions error:error];
}

- (NSData *)dataForKey:(NSData *)aKey
		inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
				 error:(NSError * __autoreleasing *)error
{
	return [self dataForKey:aKey inColumnFamily:columnFamily readOptions:_readOptions error:error];
}

- (NSData *)dataForKey:(NSData *)aKey
		inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
		   readOptions:(RocksDBReadOptions *)readOptions
				 error:(NSError * __autoreleasing *)error
{
	std::string value;
	rocksdb::Status status = _db->Get(readOptions.options,
									  columnFamily.columnFamily,
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

- (NSArray<NSData *> *)multiGet:(NSArray<NSData *> *)keys
{
	return [self multiGet:keys readOptions:_readOptions];
}

- (NSArray<NSData *> *)multiGet:(NSArray<NSData *> *)keys
					readOptions:(nonnull RocksDBReadOptions *)readOptions
{
	std::vector<rocksdb::Slice> vKeys;
	for (NSData* key in keys) {
		vKeys.push_back(SliceFromData(key));
	}

	std::vector<std::string> values;
	_db->MultiGet(readOptions.options, vKeys, &values);

	NSMutableArray<NSData *> * results = [NSMutableArray array];
	for (auto &value : values) {
		NSString * v = [NSString stringWithUTF8String:value.c_str()];
		[results addObject:[v dataUsingEncoding:NSUTF8StringEncoding]];
	}
	return results;
}

- (NSArray<NSData *> *)multiGet:(NSArray<NSData *> *)keys inColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies
{
	return [self multiGet:keys inColumnFamilies:columnFamilies readOptions:_readOptions];
}

- (NSArray<NSData *> *)multiGet:(NSArray<NSData *> *)keys inColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies readOptions:(RocksDBReadOptions *)readOptions
{
	std::vector<rocksdb::ColumnFamilyHandle *> families;
	for (RocksDBColumnFamilyHandle* handle in columnFamilies) {
		families.push_back(handle.columnFamily);
	}

	std::vector<rocksdb::Slice> vKeys;
	for (NSData* key in keys) {
		vKeys.push_back(SliceFromData(key));
	}

	std::vector<std::string> values;
	_db->MultiGet(readOptions.options, families, vKeys, &values);

	NSMutableArray<NSData *> * results = [NSMutableArray array];
	for (auto &value : values) {
		NSString * v = [NSString stringWithUTF8String:value.c_str()];
		[results addObject:[v dataUsingEncoding:NSUTF8StringEncoding]];
	}
	return results;
}

- (BOOL)keyMayExist:(NSData *)aKey value:(NSString * _Nullable *)value
{
	return [self keyMayExist:aKey readOptions:_readOptions value:value];
}

- (BOOL)keyMayExist:(NSData *)aKey
	 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			  value:(NSString * _Nullable *)value
{
	return [self keyMayExist:aKey inColumnFamily:columnFamily readOptions:_readOptions value:value];
}

- (BOOL)keyMayExist:(NSData *)aKey
		readOptions:(RocksDBReadOptions *)readOptions
			  value:(NSString * _Nullable *)value
{
	return [self keyMayExist:aKey inColumnFamily:_columnFamily readOptions:_readOptions value:value];
}

- (BOOL)keyMayExist:(NSData *)aKey
	 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
		readOptions:(RocksDBReadOptions *)readOptions
			  value:(NSString * _Nullable *)value
{
	bool found = NO;
	std::string stringValue;
	_db->KeyMayExist(readOptions.options,
					 columnFamily.columnFamily,
					 SliceFromData(aKey),
					 &stringValue,
					 &found);

	*value = [NSString stringWithUTF8String:stringValue.c_str()];
	return found;
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
	return [self deleteDataForKey:aKey forColumnFamily:_columnFamily writeOptions:_writeOptions error:error];
}

- (BOOL)deleteDataForKey:(NSData *)aKey
		 forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
				   error:(NSError * __autoreleasing *)error
{
	return [self deleteDataForKey:aKey forColumnFamily:columnFamily writeOptions:_writeOptions error:error];
}

- (BOOL)deleteDataForKey:(NSData *)aKey
		 forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			writeOptions:(RocksDBWriteOptions *)writeOptions
				   error:(NSError * __autoreleasing *)error
{
	rocksdb::Status status = _db->Delete(writeOptions.options,
										 columnFamily.columnFamily,
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

- (BOOL)deleteRange:(RocksDBKeyRange *)range
			  error:(NSError * _Nullable __autoreleasing *)error
{
	return [self deleteRange:range withOptions:_writeOptions inColumnFamily:_columnFamily error:error];
}

- (BOOL)deleteRange:(RocksDBKeyRange *)range
		 forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
				   error:(NSError * _Nullable __autoreleasing *)error
{
	return [self deleteRange:range withOptions:_writeOptions inColumnFamily:columnFamily error:error];
}

- (BOOL)deleteRange:(RocksDBKeyRange *)range
		withOptions:(RocksDBWriteOptions *)options
			  error:(NSError * _Nullable __autoreleasing *)error
{
	return [self deleteRange:range withOptions:options inColumnFamily:_columnFamily error:error];
}

- (BOOL)deleteRange:(RocksDBKeyRange *)range
		withOptions:(RocksDBWriteOptions *)options
	 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			  error:(NSError * _Nullable __autoreleasing *)error
{
	rocksdb::Slice startSlice = SliceFromData(range.start);
	rocksdb::Slice endSlice = SliceFromData(range.end);

	rocksdb::Status status = _db->DeleteRange(options.options, columnFamily.columnFamily, startSlice, endSlice);
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

- (RocksDBWriteBatch *)writeBatchInColumnFamily:(RocksDBColumnFamilyHandle*)columnFamily
{
	return [[RocksDBWriteBatch alloc] initWithColumnFamily:columnFamily];
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
												   columnFamily:_columnFamily.columnFamily
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
	return [self iteratorWithReadOptions:readOptions overColumnFamily:_columnFamily];
}

- (RocksDBIterator *)iteratorOverColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	return [self iteratorWithReadOptions:_readOptions overColumnFamily:columnFamily];
}

- (RocksDBIterator *)iteratorWithReadOptions:(RocksDBReadOptions *)readOptions
							overColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
{
	rocksdb::Iterator *iterator = _db->NewIterator(readOptions.options,
												   columnFamily.columnFamily);

	return [[RocksDBIterator alloc] initWithDBIterator:iterator];
}

- (NSArray<RocksDBIterator *> *)iteratorsOverColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies
													  error:(NSError * _Nullable *)error
{
	return [self iteratorsWithReadOptions:_readOptions overColumnFamilies:columnFamilies error:error];
}

- (NSArray<RocksDBIterator *> *)iteratorsWithReadOptions:(RocksDBReadOptions *)readOptions
									  overColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies
												   error:(NSError * _Nullable *)error
{


	std::vector<rocksdb::ColumnFamilyHandle *> families;
	for (RocksDBColumnFamilyHandle* handle in columnFamilies) {
		families.push_back(handle.columnFamily);
	}

	std::vector<rocksdb::Iterator *> iterators;

	rocksdb::Status status = _db->NewIterators(readOptions.options, families, &iterators);
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
	}

	NSMutableArray<RocksDBIterator *> *resultIterators = [NSMutableArray array];

	for (auto &i : iterators) {
		RocksDBIterator *it = [[RocksDBIterator alloc] initWithDBIterator:i];
		[resultIterators addObject:it];
	}

	return resultIterators;
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
	return [self compactRange:range withOptions:rangeOptions inColumnFamily:_columnFamily error:error];
}

- (BOOL)compactRange:(RocksDBKeyRange *)range
		 withOptions:(RocksDBCompactRangeOptions *)rangeOptions
	  inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			   error:(NSError * __autoreleasing *)error
{
	rocksdb::Slice startSlice = SliceFromData(range.start);
	rocksdb::Slice endSlice = SliceFromData(range.end);

	rocksdb::Status status = _db->CompactRange(rangeOptions.options, columnFamily.columnFamily, &startSlice, &endSlice);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

- (BOOL)enableAutoCompaction:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies error:(NSError *__autoreleasing  _Nullable *)error
{
	std::vector<rocksdb::ColumnFamilyHandle *> families;

	for (RocksDBColumnFamilyHandle* columnFamily in columnFamilies){
		families.push_back(columnFamily.columnFamily);
	}

	rocksdb::Status status = _db->EnableAutoCompaction(families);

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
