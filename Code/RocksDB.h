//
//  ObjectiveRocks.h
//  ObjectiveRocks
//
//  Created by Iska on 15/11/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#import "RocksDBColumnFamilyDescriptor.h"
#import "RocksDBColumnFamilyHandle.h"
#import "RocksDBOptions.h"
#import "RocksDBReadOptions.h"
#import "RocksDBWriteOptions.h"
#import "RocksDBCompactRangeOptions.h"

#import "RocksDBWriteBatch.h"
#import "RocksDBIterator.h"

#if !defined(ROCKSDB_LITE)
#import "RocksDBColumnFamilyMetadata.h"
#import "RocksDBIndexedWriteBatch.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class RocksDBColumnFamily;
@class RocksDBSnapshot;

#pragma mark - Initializing the database

@interface RocksDB : NSObject

///--------------------------------
/// @name Initializing the database
///--------------------------------

/**
 Intializes a DB instance with the given path and configured with the given options.

 @discussion This method initializes the DB with the default Column Family and allows for
 configuring the DB via the RocksDBOptions block. The block gets a single  argument, an
 instance of `RocksDBOptions`, which is initialized with the default values and passed for
 further tuning. If the options block is `nil`, then default settings will be used.

 @param path The file path of the DB.
 @param options RocksDBOptions to tune the database
 @param error filled if error is thrown
 @return The newly-intialized DB instance with the given path and options.

 @see RocksDBOptions
 @see RocksDBColumnFamily

 @warning When opening a DB in a read-write mode, you need to specify all Column Families
 that currently exist in the DB.
 */
+ (nullable instancetype)databaseAtPath:(NSString *)path
							 andOptions:(RocksDBOptions *)options
								  error:(NSError *__autoreleasing  _Nullable *)error;

/**
 Intializes a DB instance and opens the defined Column Families.

 @param path The file path of the database.
 @param descriptor The descriptor holds the names and the options of the existing Column Families
 in the DB.
 @param options RocksDBOptions to tune the database
 @param error filled if error is thrown
 @return The newly-intialized DB instance with the given path and database options. Furthermore, the
 DB instance also opens the defined Column Families.

 @see RocksDBColumnFamily
 @see RocksDBColumnFamilyDescriptor
 @see RocksDBOptions
 @see RocksDBDatabaseOptions

 @remark The `RocksDBDatabaseOptions` differs from the `RocksDBOptions` as it holds only database-wide
 configuration settings.

 @warning When opening a DB in a read-write mode, you need to specify all Column Families
 that currently exist in the DB.
 */
+ (nullable instancetype)databaseAtPath:(NSString *)path
						 columnFamilies:(RocksDBColumnFamilyDescriptor *)descriptor
							 andOptions:(RocksDBOptions *)options
								  error:(NSError *__autoreleasing  _Nullable *)error;

#if !defined(ROCKSDB_LITE)

/**
 Intializes a DB instance for read-only with the given path and configured with the given options.

 @discussion This method initializes the DB for read-only mode with the default Column Family and
 allows for configuring the DB via the RocksDBOptions block. The block gets a single  argument, an
 instance of `RocksDBOptions`, which is initialized with the default values and passed for
 further tuning. If the options block is `nil`, then default settings will be used.

 All DB interfaces that modify data, like put/delete, will return error. In read-only mode no
 compactions will happen.

 @param path The file path of the DB.
 @param options RocksDBOptions to tune the database
 @param error filled if error is thrown
 @return The newly-intialized DB instance with the given path and options.

 @see RocksDBOptions

 @remark Opening a non-existing database in read-only mode wont have any effect, even
 if `createIfMissing` option is set.
 */
+ (nullable instancetype)databaseForReadOnlyAtPath:(NSString *)path
										andOptions:(RocksDBOptions *)options
											 error:(NSError *__autoreleasing  _Nullable *)error;

/**
 Intializes a DB instance for read-only and opens the defined Column Families.

 @discussion All DB interfaces that modify data, like put/delete, will return error. In read-only mode no
 compactions will happen.

 @param path The file path of the database.
 @param descriptor The descriptor holds the names and the options of the existing Column Families
 in the DB.
 @param options RocksDBOptions to tune the database
 @param error filled if error is thrown
 @return The newly-intialized DB instance with the given path and database options. Furthermore, the
 DB instance also opens the defined Column Families.

 @see RocksDBColumnFamily
 @see RocksDBColumnFamilyDescriptor
 @see RocksDBOptions
 @see RocksDBDatabaseOptions

 @remark The `RocksDBDatabaseOptions` differs from the `RocksDBOptions` as it holds only database-wide
 configuration settings.

 @remark Opening a non-existing database in read-only mode wont have any effect, even
 if `createIfMissing` option is set.

 @remark When opening DB with read only, it is possible to specify only a subset of column families
 in the database that should be opened. However, default column family must specified.
 */
+ (nullable instancetype)databaseForReadOnlyAtPath:(NSString *)path
									columnFamilies:(RocksDBColumnFamilyDescriptor *)descriptor
										andOptions:(RocksDBOptions *)options
											 error:(NSError *__autoreleasing  _Nullable *)error;

#endif

/** @brief Closes the database instance */
- (void)close;

/**
 @brief Closes the database instance
 @param error if error is caught while closing the db
 */
- (BOOL)close:(NSError *__autoreleasing  _Nullable *)error;

/** @brief Whether or not the database instance is closed */
- (BOOL)isClosed;

/**
 Sets the default read & write options for all database operations.

 @param readOptions An instance of `RocksDBReadOptions` which configures the behaviour of read
 operations in the DB.
 @param writeOptions An instance of `RocksDBWriteOptions` which configures the behaviour of write
 operations in the DB.

 @see RocksDBReadOptions
 @see RocksDBWriteOptions
 */
- (void)setDefaultReadOptions:(RocksDBReadOptions *)readOptions
				 writeOptions:(RocksDBWriteOptions *)writeOptions NS_SWIFT_NAME(setDefault(readOptions:writeOptions:));

/**
 Destroy the DB residing under the given path.

 @param path The file path of the database.
 @param options For database
 @param error filled on failures
 @return An array containing all Column Families currently present in the DB.
 */
+ (BOOL)destroyDatabaseAtPath:(NSString *)path
				   andOptions:(RocksDBOptions *)options
						error:(NSError *__autoreleasing  _Nullable *)error;

@end

#pragma mark - Name & Env

@interface RocksDB (NameAndEnv)
/**
 Get DB name -- the exact same name that was provided as an argument to as path to [.open].
 */
@property (nonatomic, readonly) NSString* name;

/**
 Get the Env object from the DB
 */
@property (nonatomic, readonly) RocksDBEnv* env;

@end

#pragma mark - Column Family Management

@interface RocksDB (ColumnFamilies)

///--------------------------------
/// @name Column Family Management
///--------------------------------

/**
 Lists all existing Column Families in the DB residing under the given path.

 @param path The file path of the database.
 @param options For column family retrieval
 @param error filled on failures
 @return An array containing all Column Families currently present in the DB.

 @see RocksDBColumnFamily
 */
+ (NSArray<NSData *> *)listColumnFamiliesInDatabaseAtPath:(NSString *)path
												 andOptions:(RocksDBOptions *)options
													  error:(NSError *__autoreleasing  _Nullable *)error;

/**
 Creates a new Column Family with the given name and options.

 @param name The name of the new Column Family.
 @param options A block with a `RocksDBColumnFamilyOptions` instance for configuring the
 new Column Family.
 @param error filled on failures
 @return The newly-created Column Family with the given name and options.

 @see RocksDBColumnFamilyHandle
 @see RocksDBColumnFamilyOptions
 */
- (nullable RocksDBColumnFamilyHandle *)createColumnFamilyWithName:(NSString *)name
														andOptions:(RocksDBColumnFamilyOptions *)options
															 error:(NSError *__autoreleasing  _Nullable *)error;

/**
 Drops a Column family.
 Throws an exception if it fails.

 @param columnFamily the handle to columnFamily to drop
 @param error filled on failures

 @see RocksDBColumnFamilyHandle
 */
- (BOOL)dropColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
				   error:(NSError *__autoreleasing  _Nullable *)error;

/**
 Bulk drop column families. This call only records drop records in the
 manifest and prevents the column families from flushing and compacting.
 In case of error, the request may succeed partially. User may call
 ListColumnFamilies to check the result.
 */
- (BOOL)dropColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *>*)columnFamilies error:(NSError *__autoreleasing  _Nullable *)error;

/** @brief Returns an array */
- (NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies;

#if !defined(ROCKSDB_LITE)

/**
 Returns the Meta Data object for the Column Family associated with this instance.

 @see RocksDBColumnFamilyMetaData

 @warning Not available in RocksDB Lite.
 */
- (RocksDBColumnFamilyMetaData *)columnFamilyMetaData;

/**
 Returns the Meta Data object for the Column Family associated with this instance.

 @see RocksDBColumnFamilyMetaData

 @warning Not available in RocksDB Lite.
 */
- (RocksDBColumnFamilyMetaData *)columnFamilyMetaData: (RocksDBColumnFamilyHandle *)columnFamily;

/**
 Gets the handle for the default column family
 */
@property (nonatomic, readonly) RocksDBColumnFamilyHandle* defaultColumnFamily;

#endif

@end

#if !defined(ROCKSDB_LITE)

#pragma mark - Database properties

@interface RocksDB (Properties)

///--------------------------------
/// @name Database properties
///--------------------------------

/**
 Returns the string value for the given property.

 @param property The property name.
 @return The string value of the property.

 @warning Not available in RocksDB Lite.
 */
- (nullable NSString *)valueForProperty:(NSString *)property;

/**
 Returns the string value for the given property.

 @param property The property name.
 @param columnFamily To read from
 @return The string value of the property.

 @warning Not available in RocksDB Lite.
 */
- (nullable NSString *)valueForProperty:(NSString *)property
						 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Returns the integer value for the given int property name.

 @param property The property name.
 @return The integer value of the property.

 @warning Not available in RocksDB Lite.
 */
- (uint64_t)valueForIntProperty:(NSString *)property;

/**
 Returns the integer value for the given int property name.

 @param property The property name.
 @param columnFamily To read from
 @return The integer value of the property.

 @warning Not available in RocksDB Lite.
 */
- (uint64_t)valueForIntProperty:(NSString *)property
				 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Returns the map value for the given map property name.

 @param property The property name.
 @return The map value of the property.

 @warning Not available in RocksDB Lite.
 */
- (NSDictionary<NSString *, NSString*> *)valueForMapProperty:(NSString *)property;

/**
 Returns the map value for the given map property name.

 @param property The property name.
 @param columnFamily Column Family to read from.
 @return The map value of the property.

 @warning Not available in RocksDB Lite.
 */
- (NSDictionary<NSString *, NSString *> *)valueForMapProperty:(NSString *)property
				 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

@end

#endif

#pragma mark - Write operations

@interface RocksDB (WriteOps)

///--------------------------------
/// @name Write operations
///--------------------------------

/**
 Stores the given key-object pair into the DB.

 @param anObject The object for key.
 @param aKey The key for object.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the operation succeeded, `NO` otherwise
 */
- (BOOL)setData:(NSData *)anObject
		   forKey:(NSData *)aKey
			error:(NSError * _Nullable *)error;

/**
 Stores the given key-object pair into the DB.

 @param anObject The object for key.
 @param aKey The key for object.
 @param columnFamily The column family to put in
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the operation succeeded, `NO` otherwise
 */
- (BOOL)setData:(NSData *)anObject
		 forKey:(NSData *)aKey
forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
		  error:(NSError * _Nullable *)error;

/**
 Stores the given key-object pair into the DB.

 @param anObject The object for key.
 @param aKey The key for object.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param writeOptions `RocksDBWriteOptions` instance for configuring this write operation.
 @return `YES` if the operation succeeded, `NO` otherwise

 @see RocksDBWriteOptions
 */
- (BOOL)setData:(NSData *)anObject
		 forKey:(NSData *)aKey
   writeOptions:(RocksDBWriteOptions *) writeOptions
		  error:(NSError * _Nullable *)error;

/**
 Stores the given key-object pair into the DB.

 @param anObject The object for key.
 @param aKey The key for object.
 @param columnFamily The column family to put in
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param writeOptions `RocksDBWriteOptions` instance for configuring this write operation.
 @return `YES` if the operation succeeded, `NO` otherwise

 @see RocksDBWriteOptions
 */
- (BOOL)setData:(NSData *)anObject
		 forKey:(NSData *)aKey
forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
   writeOptions:(RocksDBWriteOptions *) writeOptions
		  error:(NSError * _Nullable *)error;

@end

#pragma mark - Merge operations

@interface RocksDB (MergeOps)

///--------------------------------
/// @name Merge operations
///--------------------------------

/**
 Merges the given object with the existing data for the given key.

 @discussion A merge is an atomic read-modify-write operation, whose semantics are defined
 by the user-provided merge operator.

 @param anObject The object being merged.
 @param aKey The key for the object.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the operation succeeded, `NO` otherwise

 @see RocksDBMergeOperator
 */
- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
			error:(NSError * _Nullable *)error;

/**
 Merges the given object with the existing data for the given key.

 @discussion A merge is an atomic read-modify-write operation, whose semantics are defined
 by the user-provided merge operator.
 This method can be used to configure single write operations bypassing the defaults.

 @param anObject The object being merged.
 @param aKey The key for the object.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param writeOptions  `RocksDBWriteOptions` instance for configuring this merge operation.
 @return `YES` if the operation succeeded, `NO` otherwise

 @see RocksDBMergeOperator
 */
- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
	 writeOptions:(RocksDBWriteOptions *) writeOptions
			error:(NSError * _Nullable *)error;


/**
 Merges the given object with the existing data for the given key.

 @discussion A merge is an atomic read-modify-write operation, whose semantics are defined
 by the user-provided merge operator.
 This method can be used to configure single write operations bypassing the defaults.

 @param anObject The object being merged.
 @param aKey The key for the object.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param columnFamily The column family to merge in
 @return `YES` if the operation succeeded, `NO` otherwise

 @see RocksDBMergeOperator
 */
- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
  inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			error:(NSError * _Nullable *)error;

/**
 Merges the given object with the existing data for the given key.

 @discussion A merge is an atomic read-modify-write operation, whose semantics are defined
 by the user-provided merge operator.
 This method can be used to configure single write operations bypassing the defaults.

 @param anObject The object being merged.
 @param aKey The key for the object.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param columnFamily The column family to merge in
 @param writeOptions  `RocksDBWriteOptions` instance for configuring this merge operation.
 @return `YES` if the operation succeeded, `NO` otherwise

 @see RocksDBMergeOperator
 */
- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
  inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
	 writeOptions:(RocksDBWriteOptions *) writeOptions
			error:(NSError * _Nullable *)error;

@end

#pragma mark - Read operations

@interface RocksDB (ReadOps)

///--------------------------------
/// @name Read operations
///--------------------------------

/**
 Returns the object for the given key.

 @param aKey The key for object.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return The object for the given key.
 */
- (nullable NSData *)dataForKey:(NSData *)aKey error:(NSError * _Nullable *)error;

/**
 Returns the object for the given key.

 @param aKey The key for object.
 @param columnFamily The column family to get from
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return The object for the given key.
 */
- (nullable NSData *)dataForKey:(NSData *)aKey
				 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
						  error:(NSError * _Nullable *)error;

/**
 Returns the object for the given key.

 @param aKey The key for object.
 @param readOptions `RocksDBReadOptions` instance for configuring this read operation.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return The object for the given key.

 @see RocksDBReadOptions
 */
- (nullable NSData *)dataForKey:(NSData *)aKey
					readOptions:(RocksDBReadOptions *)readOptions
						  error:(NSError * _Nullable *)error;

/**
 Returns the object for the given key.

 @param aKey The key for object.
 @param columnFamily The column family to get from
 @param readOptions `RocksDBReadOptions` instance for configuring this read operation.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return The object for the given key.

 @see RocksDBReadOptions
 */
- (nullable NSData *)dataForKey:(NSData *)aKey
				 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
					readOptions:(RocksDBReadOptions *)readOptions
						  error:(NSError * _Nullable *)error;

/**
 Returns a list of values for the given keys.

 @param keys The keys to get
 @return The object for the given key.

 @see RocksDBReadOptions
 */
- (NSArray<NSData *> *)multiGet:(NSArray<NSData *> *)keys;

/**
 Returns a list of values for the given keys.

 @param keys The keys to get
 @param readOptions `RocksDBReadOptions` instance for configuring this read operation.
 @return The object for the given key.

 @see RocksDBReadOptions
 */
- (NSArray<NSData *> *)multiGet:(NSArray<NSData *> *)keys
					readOptions:(RocksDBReadOptions *)readOptions;

/**
 Returns a list of values for the given keys.

 @param keys The keys to get
 @param columnFamilies The column families to get from
 @return The object for the given key.

 @see RocksDBReadOptions
 */
- (NSArray<NSData *> *)multiGet:(NSArray<NSData *> *)keys
			   inColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies;

/**
 Returns a list of values for the given keys.

 @param keys The keys to get
 @param columnFamilies The column families to get from
 @param readOptions `RocksDBReadOptions` instance for configuring this read operation.
 @return The object for the given key.

 @see RocksDBReadOptions
 */
- (NSArray<NSData *> *)multiGet:(NSArray<NSData *> *)keys
			   inColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies
					readOptions:(RocksDBReadOptions *)readOptions;

/**
 If the [key] definitely does not exist in the database, then this method
 returns false, else true.

 This check is potentially lighter-weight than invoking dataForKey. One way
 to make this lighter weight is to avoid doing any IOs.

 @param aKey The key for object to check.
 @param value out parameter if a value is found in block-cache.
 @return The object for the given key.
 */
- (BOOL)keyMayExist:(NSData *)aKey value:(NSMutableData * _Nullable)value;

/**
 If the [key] definitely does not exist in the database, then this method
 returns false, else true.

 This check is potentially lighter-weight than invoking dataForKey. One way
 to make this lighter weight is to avoid doing any IOs.

 @param aKey The key for object to check.
 @param columnFamily The column family to check in
 @param value out parameter if a value is found in block-cache.
 @return The object for the given key.
 */
- (BOOL)keyMayExist:(NSData *)aKey
	 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			  value:(NSMutableData * _Nullable)value;

/**
 If the [key] definitely does not exist in the database, then this method
 returns false, else true.

 This check is potentially lighter-weight than invoking dataForKey. One way
 to make this lighter weight is to avoid doing any IOs.

 @param aKey The key for object to check.
 @param readOptions `RocksDBReadOptions` instance for configuring this read operation.
 @param value out parameter if a value is found in block-cache.
 @return The object for the given key.
 */
- (BOOL)keyMayExist:(NSData *)aKey
		readOptions:(RocksDBReadOptions *)readOptions
			  value:(NSMutableData * _Nullable)value;

/**
 If the [key] definitely does not exist in the database, then this method
 returns false, else true.

 This check is potentially lighter-weight than invoking dataForKey. One way
 to make this lighter weight is to avoid doing any IOs.

 @param aKey The key for object to check.
 @param columnFamily The column family to check in
 @param readOptions `RocksDBReadOptions` instance for configuring this read operation.
 @param value out parameter if a value is found in block-cache.
 @return The object for the given key.
 */
- (BOOL)keyMayExist:(NSData *)aKey
	 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
		readOptions:(RocksDBReadOptions *)readOptions
			  value:(NSMutableData * _Nullable)value;

@end

#pragma mark - Delete operations

@interface RocksDB (DeleteOps)

///--------------------------------
/// @name Delete operations
///--------------------------------

/**
 Deletes the object for the given key.

 @param aKey The key to delete.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the operation succeeded, `NO` otherwise
 */
- (BOOL)deleteDataForKey:(NSData *)aKey error:(NSError * _Nullable *)error;

/**
 Deletes the object for the given key.

 @param aKey The key to delete.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param columnFamily To delete key from
 @return `YES` if the operation succeeded, `NO` otherwise
 */
- (BOOL)deleteDataForKey:(NSData *)aKey
		 forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
				   error:(NSError * _Nullable *)error;

/**
 Deletes the object for the given key.

 @param aKey The key to delete.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param writeOptions `RocksDBWriteOptions` instance for configuring this delete operation.
 @return `YES` if the operation succeeded, `NO` otherwise

 @see RocksDBWriteOptions
 */
- (BOOL)deleteDataForKey:(NSData *)aKey
			writeOptions:(RocksDBWriteOptions *)writeOptions
				   error:(NSError * _Nullable *)error;

/**
 Deletes the object for the given key.

 @param aKey The key to delete.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param columnFamily To delete key from
 @param writeOptions `RocksDBWriteOptions` instance for configuring this delete operation.
 @return `YES` if the operation succeeded, `NO` otherwise

 @see RocksDBWriteOptions
 */
- (BOOL)deleteDataForKey:(NSData *)aKey
		 forColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			writeOptions:(RocksDBWriteOptions *)writeOptions
				   error:(NSError * _Nullable *)error;

/**
 Removes the database entries in the range , i.e.,
 including "beginKey" and excluding "endKey". a non-OK status on error. It
 is not an error if no keys exist in the range ["beginKey", "endKey").
 Delete the database entry (if any) for "key". Returns OK on success, and a
 non-OK status on error. It is not an error if "key" did not exist in the
 database.

 @param range to delete
 @param error if something went wrong deleting

 @see RocksDBKeyRange
 @see RocksDBWriteOptions
 */
- (BOOL)deleteRange:(RocksDBKeyRange *)range
			  error:(NSError * _Nullable *)error;

/**
 Removes the database entries in the range , i.e.,
 including "beginKey" and excluding "endKey". a non-OK status on error. It
 is not an error if no keys exist in the range ["beginKey", "endKey").
 Delete the database entry (if any) for "key". Returns OK on success, and a
 non-OK status on error. It is not an error if "key" did not exist in the
 database.

 @param range to delete
 @param columnFamily ColumnFamilyHandle instance
 @param error if something went wrong deleting

 @see RocksDBKeyRange
 @see RocksDBWriteOptions
 */
- (BOOL)deleteRange:(RocksDBKeyRange *)range
	 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			  error:(NSError * _Nullable *)error;

/**
 Removes the database entries in the range , i.e.,
 including "beginKey" and excluding "endKey". a non-OK status on error. It
 is not an error if no keys exist in the range ["beginKey", "endKey").
 Delete the database entry (if any) for "key". Returns OK on success, and a
 non-OK status on error. It is not an error if "key" did not exist in the
 database.

 @param range to delete
 @param options Write options for deletion
 @param error if something went wrong deleting

 @see RocksDBKeyRange
 @see RocksDBWriteOptions
 */
- (BOOL)deleteRange:(RocksDBKeyRange *)range
		withOptions:(RocksDBWriteOptions *)options
			  error:(NSError * _Nullable *)error;

/**
 Removes the database entries in the range , i.e.,
 including "beginKey" and excluding "endKey". a non-OK status on error. It
 is not an error if no keys exist in the range ["beginKey", "endKey").
 Delete the database entry (if any) for "key". Returns OK on success, and a
 non-OK status on error. It is not an error if "key" did not exist in the
 database.

 @param range to delete
 @param columnFamily ColumnFamilyHandle instance
 @param options Write options for deletion
 @param error if something went wrong deleting

 @see RocksDBKeyRange
 @see RocksDBWriteOptions
 */
- (BOOL)deleteRange:(RocksDBKeyRange *)range
		withOptions:(RocksDBWriteOptions *)options
	 inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			  error:(NSError * _Nullable *)error;

@end

#pragma mark - Atomic Writes

@interface RocksDB (WriteBatch)

///--------------------------------
/// @name Atomic Writes
///--------------------------------

/**
 Applies a write batch instance on this DB.

 @discussion In contrast to the block-based approach, this method allows for building the batch separately
 and then applying it when needed.

 @param writeBatch The write batch instance to apply.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param writeOptions The write options to configure this batch.
 @return `YES` if the operation succeeded, `NO` otherwise

 @see RocksDBWriteBatch
 @see RocksDBWriteOptions
 */
- (BOOL)applyWriteBatch:(RocksDBWriteBatchBase *)writeBatch
		   writeOptions:(RocksDBWriteOptions *)writeOptions
				  error:(NSError * _Nullable *)error;

@end

#pragma mark - Database Iterator

@interface RocksDB (Iterator)

///--------------------------------
/// @name Database Iterator
///--------------------------------

/**
 Returns an iterator instance for scan operations.

 @return An iterator instace.

 @see RocksDBIterator
 */
- (RocksDBIterator *)iterator;

/**
 Returns an iterator instance for scan operations inside a specified column family.

 @param columnFamily The column family to iterate over
 @return An iterator instace.

 @see RocksDBIterator
 */
- (RocksDBIterator *)iteratorOverColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Returns an iterator instance for scan operations

 @param readOptions `RocksDBReadOptions` instance for configuring the iterator instance.
 @return An iterator instace.

 @see RocksDBIterator
 @see RocksDBReadOptions
 */
- (RocksDBIterator *)iteratorWithReadOptions:(RocksDBReadOptions *)readOptions;

/**
 Returns an iterator instance for scan operations

 @param readOptions `RocksDBReadOptions` instance for configuring the iterator instance.
 @param columnFamily The column family to iterate over
 @return An iterator instace.

 @see RocksDBIterator
 @see RocksDBReadOptions
 */
- (RocksDBIterator *)iteratorWithReadOptions:(RocksDBReadOptions *)readOptions
							overColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Returns iterator instances for scan operations over specified column families

 @param columnFamilies The column family to iterate over
 @return An iterator instace.

 @see RocksDBIterator
 @see RocksDBReadOptions
 */
- (NSArray<RocksDBIterator *> *)iteratorsOverColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies
													  error:(NSError * _Nullable *)error;

/**
 Returns iterator instances for scan operations over specified column families

 @param readOptions `RocksDBReadOptions` instance for configuring the iterator instance.
 @param columnFamilies The column family to iterate over
 @return An iterator instace.

 @see RocksDBIterator
 @see RocksDBReadOptions
 */
- (NSArray<RocksDBIterator *> *)iteratorsWithReadOptions:(RocksDBReadOptions *)readOptions
									  overColumnFamilies:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies
												   error:(NSError * _Nullable *)error;

@end

#pragma mark - Database Snapshot

@interface RocksDB (Snapshot)

///--------------------------------
/// @name Database Snapshot
///--------------------------------

/**
 Returns a snapshot of the DB. A snapshot provides consistent read-only view over the state of the key-value store.

 @see RocksDBSnapshot
 */
- (RocksDBSnapshot *)snapshot;

/**
 Returns a snapshot of the DB. A snapshot provides consistent read-only view over the state of the key-value store.

 @param readOptions  `RocksDBReadOptions` instance for configuring the returned snapshot instance.

 @see RocksDBSnapshot
 @see RocksDBReadOptions
 */
- (RocksDBSnapshot *)snapshotWithReadOptions:(RocksDBReadOptions *)readOptions;

@end

#pragma mark - Compaction

@interface RocksDB (Compaction)

///--------------------------------
/// @name Database Compaction
///--------------------------------

/**
 Compacts the underlying storage for the specified key range [begin, end].

 A `nil` start key is treated as a key before all keys, and a `nil` end key is treated as a key
 after all keys in the database. Thus, in order to compact the entire database, the `RocksDBOpenRange` can be used.

 @param range The key range for the compcation.
 @param options The options for the compact range operation.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the operation succeeded, `NO` otherwise.

 @see RocksDBKeyRange
 @see RocksDBCompactRangeOptions
 */
- (BOOL)compactRange:(RocksDBKeyRange *)range
		 withOptions:(RocksDBCompactRangeOptions *)options
			   error:(NSError * _Nullable *)error;

/**
 Compacts the underlying storage for the specified key range [begin, end].

 A `nil` start key is treated as a key before all keys, and a `nil` end key is treated as a key
 after all keys in the database. Thus, in order to compact the entire database, the `RocksDBOpenRange` can be used.

 @param range The key range for the compcation.
 @param options The options for the compact range operation.
 @param columnFamily The column family to compact
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the operation succeeded, `NO` otherwise.

 @see RocksDBKeyRange
 @see RocksDBCompactRangeOptions
 */
- (BOOL)compactRange:(RocksDBKeyRange *)range
		 withOptions:(RocksDBCompactRangeOptions *)options
	  inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			   error:(NSError * _Nullable *)error;

/**
 Enable automatic compactions for the given column
 families if they were previously disabled.

 The function will first set the
 [ColumnFamilyOptions.disableAutoCompactions] option for each
 column family to false, after which it will schedule a flush/compaction.

 NOTE: Setting disableAutoCompactions to 'false' through
 [.setOptions]
 does NOT schedule a flush/compaction afterwards, and only changes the
 parameter itself within the column family option.

 @param columnFamilies the column family handles
 @param error RocksDBError If an error occurs
 */
- (BOOL)enableAutoCompaction:(NSArray<RocksDBColumnFamilyHandle *> *)columnFamilies error:(NSError * __autoreleasing *)error;

@end

#pragma mark - File Deletions

@interface RocksDB (FileDeletion)

///--------------------------------
/// @name File Deletion
///--------------------------------

/**
 Prevent file deletions. Compactions will continue to occur,
 but no obsolete files will be deleted. Calling this multiple
 times have the same effect as calling it once.
 @param error RocksDBError If an error occurs
 */
- (BOOL)disableFileDeletions:(NSError * __autoreleasing *)error;

/**
 Allow compactions to delete obsolete files.
 If force == true, the call to EnableFileDeletions()
 will guarantee that file deletions are enabled after
 the call, even if DisableFileDeletions() was called
 multiple times before.

 If force == false, EnableFileDeletions will only
 enable file deletion after it's been called at least
 as many times as DisableFileDeletions(), enabling
 the two methods to be called by two threads
 concurrently without synchronization
 -- i.e., file deletions will be enabled only after both
 threads call EnableFileDeletions()

 @param force boolean value described above.
 @param error RocksDBError If an error occurs
 */
- (BOOL)enableFileDelections:(BOOL)force error:(NSError * __autoreleasing *)error;

/**
 Delete the file name from the db directory and update the internal state to
 reflect that. Supports deletion of sst and log files only. 'name' must be
 path relative to the db directory. eg. 000001.sst, /archive/000003.log
 
 @param name the file name
 @param error RocksDBError If an error occurs
 */
- (BOOL)deleteFile:(NSString *)name error:(NSError * __autoreleasing *)error;

@end

#pragma mark - Background Work

@interface RocksDB (BackgroundWork)

///--------------------------------
/// @name Background Work
///--------------------------------

/**
 This function will wait until all currently running background processes
 finish. After it returns, no background process will be run until
 .continueBackgroundWork] is called

 @param error RocksDBError If an error occurs when pausing background work
 */
- (BOOL)pauseBackgroundWork:(NSError * __autoreleasing *)error;

/**
 Resumes background work which was suspended by previously calling .pauseBackground
 @param error RocksDBError If an error occurs when resuming background work
 */
- (BOOL)continueBackgroundWork:(NSError * __autoreleasing *)error;

@end

#pragma mark Sequence number

@interface RocksDB (SequenceNumber)

/**
 The sequence number of the most recent transaction.
 */
@property (nonatomic, readonly) uint64_t latestSequenceNumber;

/**
 Instructs DB to preserve deletes with sequence numbers >= sequenceNumber.

 Has no effect if DBOptions#preserveDeletes() is set to false.

 This function assumes that user calls this function with monotonically
 increasing seqnums (otherwise we can't guarantee that a particular delete
 hasn't been already processed).

 @param sequenceNumber the minimum sequence number to preserve

 @return true if the value was successfully updated,
 false if user attempted to call if with
 sequenceNumber <= current value.
*/
- (BOOL)setPreserveDeletesSequenceNumber:(uint64_t)sequenceNumber;

@end

#pragma mark - Level operations

@interface RocksDB (LevelOperations)

/**
 Number of levels used for this DB.
*/
- (int)numberLevels;

/**
 Number of levels used for this DB.
 @param columnFamily ColumnFamilyHandle instance
*/
- (int)numberLevelsInColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Maximum level to which a new compacted memtable is pushed if it does not create overlap.
*/
- (int)maxMemCompactionLevel;

/**
 Maximum level to which a new compacted memtable is pushed if it does not create overlap.
 @param columnFamily ColumnFamilyHandle instance
*/
- (int)maxMemCompactionLevelInColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Number of files in level-0 that would stop writes.
*/
- (int)level0StopWriteTrigger;

/**
 Promote L0
 */
- (BOOL)promoteL0:(int)targetLevel
			error:(NSError * _Nullable __autoreleasing *)error;

/**
 Promote L0
 */
- (BOOL)promoteL0:(int)targetLevel
   inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
			error:(NSError * _Nullable __autoreleasing *)error;

/**
 Number of files in level-0 that would stop writes.
 @param columnFamily ColumnFamilyHandle instance
*/
- (int)level0StopWriteTriggerInColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

@end

#pragma mark - WAL

@interface RocksDB (WAL)

/**
 Sync the WAL.

 Note that [.write] followed by [.syncWal] is not exactly the same as [.write] with
 [WriteOptions.sync] set to true; In the latter case the changes
 won't be visible until the sync is done.

 Currently only works if [Options.allowMmapWrites] is set to false.
*/
- (BOOL)syncWal:(NSError * __autoreleasing *)error;

/**
 Flush the WAL memory buffer to the file. If `sync` is true, it calls [.syncWal] afterwards.
 @param sync true to also fsync to disk.
 */
- (BOOL)flushWal:(BOOL)sync error:(NSError *__autoreleasing  _Nullable *)error;

@end

#pragma mark Verification

@interface RocksDB (Verification)

/**
 Verify checksum
 @param error RocksDBError if the checksum is not valid
 */
- (BOOL)verifyChecksum:(NSError * __autoreleasing *)error;

@end

#pragma mark Stats

@interface RocksDB (Stats)

/**
 Reset internal stats for DB and all column families.
 Note this doesn't reset [Options.statistics] as it is not owned by DB.
*/
- (BOOL)resetStats:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
