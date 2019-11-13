//
//  RocksDBWriteBatch.h
//  ObjectiveRocks
//

#import <Foundation/Foundation.h>
#import "RocksDBColumnFamilyHandle.h"
#import "RocksDBWriteBatchBase.h"

NS_ASSUME_NONNULL_BEGIN

@class RocksDBColumnFamily;

@interface RocksDBSavePoint : NSObject
@property (nonatomic, readonly) size_t size;
@property (nonatomic, readonly) int count;
@property (nonatomic, readonly) uint32_t contentFlags;
@end

/**
 The `RocksDBWriteBatch` allows to place multiple updates in the same "batch" and apply them together
 using a synchronous write. Operations on a Write Batch instance have no effect if not applied to a DB
 instance, i.e. the Write Batch accumulates all modifications that are to be performed when applying
 to a DB instance. Write batches can also span multiple Column Families.

 @warning If not specified otherwise, Write Batch operations are applied to the Column Family
 used when initiazing the Batch instance.
 */
@interface RocksDBWriteBatch : RocksDBWriteBatchBase

/** Returns true if Put will be called during Iterate. */
- (BOOL)hasPut;
/** Returns true if Delete will be called during Iterate. */
- (BOOL)hasDelete;
/** Returns true if SingleDelete will be called during Iterate. */
- (BOOL)hasSingleDelete;
/** Returns true if DeleteRange will be called during Iterate. */
- (BOOL)hasDeleteRange;
/** Returns true if Merge will be called during Iterate. */
- (BOOL)hasMerge;
/** Returns true if MarkBeginPrepare will be called during Iterate. */
- (BOOL)hasBeginPrepare;
/** Returns true if MarkEndPrepare will be called during Iterate. */
- (BOOL)hasEndPrepare;
/** true if MarkCommit will be called during Iterate. */
- (BOOL)hasCommit;
/** true if MarkRollback will be called during Iterate.  */
- (BOOL)hasRollback;

#pragma mark - Wal termination point

/** Gets the WAL termination point. */
- (RocksDBSavePoint *)getWalTerminationPoint;

/**
 Marks this point in the WriteBatch as the last record to
 be inserted into the WAL, provided the WAL is enabled.
 */
- (void)markWalTerminationPoint;

@end

NS_ASSUME_NONNULL_END
