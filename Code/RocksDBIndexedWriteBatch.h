//
//  RocksDBIndexedWriteBatch.h
//  ObjectiveRocks
//
//  Created by Iska on 20/08/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import "RocksDBWriteBatch.h"
#import "RocksDBWriteBatchIterator.h"
#import "RocksDBReadOptions.h"
#import "RocksDBOptions.h"

NS_ASSUME_NONNULL_BEGIN

@class RocksDBColumnFamily;
@class RocksDBReadOptions;

/**
 A `RocksDBIndexedWriteBatch` builds a binary searchable index for all the keys
 inserted, which can be iterated via the `RocksDBWriteBatchIterator`.
 */
@interface RocksDBIndexedWriteBatch : RocksDBWriteBatch

/**
 Returns the value for the given key in this Write Batch.

 @discussion This method will only read the key from this batch.

 @remark If the batch does not have enough data to resolve Merge operations,
 MergeInProgress status may be returned.

 @param aKey The key for object.
 @param columnFamily The column family from which the data should be read.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return The object for the given key.

 @see RocksDBColumnFamily
 */
- (nullable NSData *)dataForKey:(NSData *)aKey
				 inColumnFamily:(RocksDBColumnFamily *)columnFamily
						  error:(NSError * _Nullable *)error;

/**
 Returns the object for the given key.

 @discussion This function will query both this batch and the DB and then merge
 the results using the DB's merge operator (if the batch contains any
 merge requests).

 Setting the `RocksDBSnapshot` on the `RocksDBReadOptions` will affect what is read 
 from the DB but will not change which keys are read from the batch (the keys in
 this batch do not yet belong to any snapshot and will be fetched
 regardless).

 @param aKey The key for object.
 @param columnFamily The column family from which the data should be read.
 @param readOptions A block with a `RocksDBReadOptions` instance for configuring this read operation.
 @param error If an error occurs, upon return contains an `NSError` object that describes åthe problem.
 @return The object for the given key.

 @see RocksDBColumnFamily
 @see RocksDBReadOptions
 */
- (nullable NSData *)dataForKeyIncludingDatabase:(NSData *)aKey
								  inColumnFamily:(RocksDBColumnFamily *)columnFamily
									 readOptions:(nullable void (^)(RocksDBReadOptions *readOptions))readOptions
										   error:(NSError * _Nullable *)error;
/**
 Creates and returns an iterator over this indexed write batch.

 @discussion Keys will be iterated in the order given by the write batch's
 comparator. For multiple updates on the same key, each update will be 
 returned as a separate entry, in the order of update time.

 @return An iterator over this indexed write batch.

 @see RocksDBWriteBatchIterator
 */
- (RocksDBWriteBatchIterator *)iterator;

/**
Creates and returns an iterator over this indexed write batch inside column family

@discussion Keys will be iterated in the order given by the write batch's
comparator. For multiple updates on the same key, each update will be
returned as a separate entry, in the order of update time.

@param columnFamily to iterate over

@return An iterator over this indexed write batch.

@see RocksDBWriteBatchIterator
*/
- (RocksDBWriteBatchIterator *)iteratorInColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Provides Read-Your-Own-Writes like functionality by
 creating a new Iterator that will use [org.rocksdb.WBWIRocksIterator]
 as a delta and baseIterator as a base. Operates on the default column family.

 @param iterator The base iterator,
 @return An iterator which shows a view comprised of both the database
 point-in-timefrom baseIterator and modifications made in this write batch.
*/
- (RocksDBIterator *)iteratorWithBase:(RocksDBIterator *)iterator;

/**
 Provides Read-Your-Own-Writes like functionality by
 creating a new Iterator that will use [maryk.rocksdb.WBWIRocksIterator]
 as a delta and baseIterator as a base

 Updating write batch with the current key of the iterator is not safe.
 We strongly recommand users not to do it. It will invalidate the current
 key() and value() of the iterator. This invalidation happens even before
 the write batch update finishes. The state may recover after Next() is
 called.

 @param iterator The base iterator
 @param columnFamily The column family to iterate over
 @return An iterator which shows a view comprised of both the database
 point-in-time from baseIterator and modifications made in this write batch.
*/
- (RocksDBIterator *)iteratorWithBase:(RocksDBIterator *)iterator
					   inColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily;

/**
 Similar to [RocksDB.get] but will only
 read the key from this batch.

 @param options The database options to use
 @param key The key to read the value for
 @param error filled if error was encountered

 @return a byte array storing the value associated with the input key if
 any. null if it does not find the specified key.

 @throws RocksDBException if the batch does not have enough data to resolve
 Merge operations, MergeInProgress status may be returned.
*/
- (NSData *)getFromBatch:(RocksDBDatabaseOptions *)options
					 key:(NSData *)key
				   error:(NSError * __autoreleasing *)error;

/**
 Similar to [RocksDB.get] but will only
 read the key from this batch.

 @param options The database options to use
 @param columnFamily The column family to retrieve the value from
 @param key The key to read the value for
 @param error filled if error was encountered

 @return a byte array storing the value associated with the input key if
 any. null if it does not find the specified key.

 @throws RocksDBException if the batch does not have enough data to resolve
 Merge operations, MergeInProgress status may be returned.
*/
- (NSData *)getFromBatch:(RocksDBDatabaseOptions *)options
		fromColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
					 key:(NSData *)key
				   error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
