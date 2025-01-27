//
//  RocksDBWriteBatchIterator.h
//  ObjectiveRocks
//
//  Created by Iska on 20/08/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import "RocksDBIterator.h"
#import "RocksDBSlice.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RocksDBWriteBatchEntryType)
{
	RocksDBWriteBatchEntryTypePutRecord,
	RocksDBWriteBatchEntryTypeMergeRecord,
	RocksDBWriteBatchEntryTypeDeleteRecord,
	RocksDBWriteBatchEntryTypeSingleDeleteRecord,
	RocksDBWriteBatchEntryTypeDeleteRangeRecord,
	RocksDBWriteBatchEntryTypeLogDataRecord,
	RocksDBWriteBatchEntryTypeXIDRecord
};

@interface RocksDBWriteBatchEntry : NSObject
@property (nonatomic, readonly) RocksDBWriteBatchEntryType type;
@property (nonatomic, readonly) RocksDBSlice *key;
@property (nonatomic, readonly) RocksDBSlice *value;

- (instancetype) initWithType:(RocksDBWriteBatchEntryType)type
						  key:(RocksDBSlice *)key
						value:(RocksDBSlice *)value;

@end

@interface RocksDBWriteBatchIterator : NSObject

/** @brief Closes this Iterator */
- (void)close;

/**
 An iterator is either positioned at a key/value pair, or not valid.

 @return `YES` if the iterator is valid, `NO` otherwise.
 */
- (BOOL)isValid;

/**
 Positions the iterator at the first key in the source.
 The iterator `isValid` after this call if the source is not empty.
 */
- (void)seekToFirst;

/**
 Positions the iterator at the last key in the source.
 The iterator `isValid` after this call if the source is not empty.
 */
- (void)seekToLast;

/**
 Positions the iterator at the first key in the source that at or past the given key.
 The iterator `isValid` after this call if the source contains an entry that comes at
 or past the given key.

 @param aKey The key to position the tartaritartor at.
 */
- (void)seekToKey:(NSData *)aKey;

/**
 Positions the iterator at the last key in the source at or before the given key.
 The iterator `isValid` after this call if the source contains an entry that comes at
 or past the given key.

 @param aKey The key to position the iterator at.
 */
- (void)seekForPrev:(NSData *)aKey;

/**
 Moves to the next entry in the source. After this call, `isValid` is
 true if the iterator was not positioned at the last entry in the source.
 */
- (void)next;

/**
 Moves to the previous entry in the source.  After this call, `isValid` is
 true iff the iterator was not positioned at the first entry in source.
 */
- (void)previous;

/**
 Returns the `RocksDBWriteBatchEntry` at the current position.
 
 @return The entry at the current position.
 
 @see RocksDBWriteBatchEntry`
 */
- (RocksDBWriteBatchEntry *)entry;

/**
 If an error has occurred, throw it.  Else just continue
 If non-blocking IO is requested and this operation cannot be
 satisfied without doing some IO, then this throws Error with Status::Incomplete.

 @param error RocksDBError  if error happens in underlying native library.
 */
- (BOOL)status:(NSError * __autoreleasing *)error;

/**
 Executes a given block for each entry in the iterator.

 @param block The block to apply to entries.
 */
- (void)enumerateEntriesUsingBlock:(void (^)(RocksDBWriteBatchEntry *entry, BOOL *stop))block;

/**
 Executes a given block for each entry in the iterator in reverse order.

 @param block The block to apply to entries.
 */
- (void)reverseEnumerateEntriesUsingBlock:(void (^)(RocksDBWriteBatchEntry *entry, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
