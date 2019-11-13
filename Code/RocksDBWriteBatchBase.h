//
//  RocksDBWriteBatchBase.h
//  ObjectiveRocks
//

#import <Foundation/Foundation.h>
#import "RocksDBColumnFamilyHandle.h"
#import "RocksDBRange.h"

NS_ASSUME_NONNULL_BEGIN

@class RocksDBColumnFamily;

/**
 The `RocksDBWriteBatch` allows to place multiple updates in the same "batch" and apply them together
 using a synchronous write. Operations on a Write Batch instance have no effect if not applied to a DB
 instance, i.e. the Write Batch accumulates all modifications that are to be performed when applying
 to a DB instance. Write batches can also span multiple Column Families.

 @warning If not specified otherwise, Write Batch operations are applied to the Column Family
 used when initiazing the Batch instance.
 */
@interface RocksDBWriteBatchBase : NSObject

/**
 Stores the given key-object pair into the Write Batch.

 @param anObject The object for key.
 @param aKey The key for object.
 */
- (void)setData:(NSData *)anObject forKey:(NSData *)aKey;

/**
 Stores the given key-object pair for the given Column Family into the Write Batch.

 @param anObject The object for key.
 @param aKey The key for object.
 @param columnFamily The column family where data should be written.
 */
- (void)setData:(NSData *)anObject forKey:(NSData *)aKey inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Merges the given key-object pair into the Write Batch.

 @param anObject The object for key.
 @param aKey The key for object.
 */
- (void)mergeData:(NSData *)anObject forKey:(NSData *)aKey;

/**
 Merges the given key-object pair for the given Column Family into the Write Batch.

 @param anObject The object for key.
 @param aKey The key for object.
 @param columnFamily The column family where data should be written.
 */
- (void)mergeData:(NSData *)anObject forKey:(NSData *)aKey inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Deletes the object for the given key from this Write Batch.

 @param aKey The key to delete.
 */
- (void)deleteDataForKey:(NSData *)aKey;

/**
 Deletes the object for the given key in the given Column Family from this Write Batch.

 @param aKey The key for object.
 @param columnFamily The column family from which the data should be deleted.
 */
- (void)deleteDataForKey:(NSData *)aKey inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
Remove the database entry for key. Requires that the key exists
and was not overwritten. It is not an error if the key did not exist
in the database.
If a key is overwritten (by calling {@link #put(byte[], byte[])} multiple
times), then the result of calling SingleDelete() on this key is undefined.
SingleDelete() only behaves correctly if there has been only one Put()
for this key since the previous call to SingleDelete() for this key.

@param key The key for object.
*/
- (void)singleDelete:(NSData *)key;

/**
Remove the database entry for key. Requires that the key exists
and was not overwritten. It is not an error if the key did not exist
in the database.
If a key is overwritten (by calling {@link #put(byte[], byte[])} multiple
times), then the result of calling SingleDelete() on this key is undefined.
SingleDelete() only behaves correctly if there has been only one Put()
for this key since the previous call to SingleDelete() for this key.

@param key The key for object.
@param columnFamily The column family from which the data should be deleted.
*/
- (void)singleDelete:(NSData *)key inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

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
 Append a blob of arbitrary size to the records in this batch. Blobs, puts, deletes, and merges
 will be encountered in the same order in thich they were inserted. The blob will NOT consume
 sequence number(s) and will NOT increase the count of the batch.

 Example application: add timestamps to the transaction log for use in replication.
 */
- (void)putLogData:(NSData *)logData;

/** @brief Clear all updates buffered in this batch. */
- (void)clear;

/** @brief Returns the number of updates in the batch. */
- (int)count;

/** @brief Retrieve the serialized version of this batch. */
- (NSData *)data;

/** @brief Retrieve data size of the batch. */
- (size_t)dataSize;

/** @biref */
- (void)setMaxBytes:(size_t)maxBytes;

/**
 Sets save point for potential rollback
 */
- (void)setSavePoint;

/**
 Rollback to last stored save point
 Returns true if succeeds to rollback
 @param error filled on problems encountered during rollback
 */
- (void)rollbackToSavePoint:(NSError * _Nullable __autoreleasing *)error;

/**
 Pop last stored save point
 Returns true if succeeds to rollback
 @param error filled on problems encountered during pop
 */
- (void)popSavePoint:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
