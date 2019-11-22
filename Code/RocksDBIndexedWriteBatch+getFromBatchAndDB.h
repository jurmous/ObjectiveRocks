//
//  RocksDBIndexedWriteBatch+getFromBatchAndDB.h
//  ObjectiveRocks
//

#import "RocksDBIndexedWriteBatch.h"
#import "RocksDBReadOptions.h"
#import "RocksDB.h"

/**
 A `RocksDBIndexedWriteBatch` builds a binary searchable index for all the keys
 inserted, which can be iterated via the `RocksDBWriteBatchIterator`.
 */
@interface RocksDBIndexedWriteBatch (getFromBatchAndDB)

/**
 Similar to [RocksDB.get] but will also
 read writes from this batch.

 This function will query both this batch and the DB and then merge
 the results using the DB's merge operator (if the batch contains any
 merge requests).

 Setting [ReadOptions.setSnapshot] will affect what is
 read from the DB but will NOT change which keys are read from the batch
 (the keys in this batch do not yet belong to any snapshot and will be
 fetched regardless).

 @param db The Rocks database
 @param options The read options to use
 @param key The key to read the value for
 @param error filled if error was encountered

 @return a byte array storing the value associated with the input key if
 any. null if it does not find the specified key.

 @throws RocksDBException if the value for the key cannot be read
*/
- (nullable NSData *)getFromBatchAndDB:(RocksDB *)db
							   options:(RocksDBReadOptions *)options
								   key:(NSData *)key
								 error:(NSError * __autoreleasing *)error;

/**
 Similar to [RocksDB.get] but will also
 read writes from this batch.

 This function will query both this batch and the DB and then merge
 the results using the DB's merge operator (if the batch contains any
 merge requests).

 Setting [ReadOptions.setSnapshot] will affect what is
 read from the DB but will NOT change which keys are read from the batch
 (the keys in this batch do not yet belong to any snapshot and will be
 fetched regardless).

 @param db The Rocks database
 @param columnFamily The column family to retrieve the value from
 @param options The read options to use
 @param key The key to read the value for
 @param error filled if error was encountered

 @return a byte array storing the value associated with the input key if
 any. null if it does not find the specified key.
*/
- (nullable NSData *)getFromBatchAndDBAndColumnFamily:(RocksDB *)db
											  options:(RocksDBReadOptions *)options
									 fromColumnFamily:(RocksDBColumnFamilyHandle *)columnFamily
												  key:(NSData *)key
												error:(NSError * __autoreleasing *)error;

@end
