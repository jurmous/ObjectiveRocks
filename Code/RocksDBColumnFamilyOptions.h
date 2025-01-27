//
//  RocksDBColumnFamilyOptions.h
//  ObjectiveRocks
//
//  Created by Iska on 28/12/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RocksDBMemTableRepFactory;
@class RocksDBTableFactory;
@class RocksDBComparator;
@class RocksDBMergeOperator;
@class RocksDBPrefixExtractor;

NS_ASSUME_NONNULL_BEGIN

/** The DB compression type. */
typedef NS_ENUM(char, RocksDBCompactionStyle)
{
	RocksDBCompactionStyleLevel = 0x0,
	RocksDBCompactionStyleUniversal = 0x1,
	RocksDBCompactionStyleFifo = 0x2,
	RocksDBCompactionStyleNone = 0x3
};

/** The DB compression type. */
typedef NS_ENUM(char, RocksDBCompressionType)
{
	RocksDBCompressionNone = 0x0,
	RocksDBCompressionSnappy = 0x1,
	RocksDBCompressionZlib = 0x2,
	RocksDBCompressionBZip2 = 0x3,
	RocksDBCompressionLZ4 = 0x4,
	RocksDBCompressionLZ4HC = 0x5
};

@interface RocksDBColumnFamilyOptions : NSObject

/** @brief Comparator used to define the order of keys in the table.
 Default: a comparator that uses lexicographic byte-wise ordering.

 @see RocksDBComparator
 */
@property (nonatomic, strong, nullable) RocksDBComparator *comparator;

/** @brief The client must provide a merge operator if Merge operation
 needs to be accessed.
 Default: nil

 @warning The client must ensure that the merge operator supplied here has
 the same name and *exactly* the same semantics as the merge operator provided
 to previous open calls on the same DB.

 @see RocksDBMergeOperator
 */
@property (nonatomic, strong, nullable) RocksDBMergeOperator *mergeOperator;

/** @brief Amount of data to build up in memory (backed by an unsorted log
 on disk) before converting to a sorted on-disk file.
 Default: 4MB.
 */
@property (nonatomic, assign) size_t writeBufferSize;

/** @brief The maximum number of write buffers that are built up in memory.
 Default: 2
 */
@property (nonatomic, assign) int maxWriteBufferNumber;

/** @brief The minimum number of write buffers that will be merged together
 before writing to storage.
 Default: 1
 */
@property (nonatomic, assign) int minWriteBufferNumberToMerge;

/** @brief Compress blocks using the specified compression algorithm.
 Default: RocksDBCompressionSnappy, which gives lightweight but fast compression.
 */
@property (nonatomic, assign) RocksDBCompressionType compressionType;

/** @brief Set compaction style for DB.
 Default: RocksDBCompactionStyleLevel
 */
@property (nonatomic, assign) RocksDBCompactionStyle compactionStyle;

/** @brief If non-nil, the specified function to determine the
 prefixes for keys will be used. These prefixes will be placed in the filter.

 @see RocksDBPrefixExtractor
 */
@property (nonatomic, strong, nullable) RocksDBPrefixExtractor *prefixExtractor;

/** @brief Number of levels for this DB. */
@property (nonatomic, assign) int numLevels;

/** @brief Number of files to trigger level-0 compaction.
 Default: 4
 */
@property (nonatomic, assign) int level0FileNumCompactionTrigger;

/** @brief Soft limit on number of level-0 files. */
@property (nonatomic, assign) int level0SlowdownWritesTrigger;

/** @brief Maximum number of level-0 files. */
@property (nonatomic, assign) int level0StopWritesTrigger;

/** @brief Target file size for compaction.
 Default: 2MB
 */
@property (nonatomic, assign) uint64_t targetFileSizeBase;

/** @brief By default target_file_size_multiplier is 1, which means
 by default files in different levels will have similar size. */
@property (nonatomic, assign) int targetFileSizeMultiplier;

/** @brief Control maximum total data size for a level.
 Default: 10MB
 */
@property (nonatomic, assign) uint64_t maxBytesForLevelBase;

/** @brief Default: 10 */
@property (nonatomic, assign) double maxBytesForLevelMultiplier;

/** @brief Puts are delayed 0-1 ms when any level has a compaction score that
 exceeds this limit.
 Default: 0 (disabled)
 */
@property (nonatomic, assign) double softRateLimit;

/** @brief Puts are delayed 1ms at a time when any level has a compaction
 score that exceeds this limit.
 Default: 0 (disabled)
 */
@property (nonatomic, assign) double hardRateLimit;

/** @brief Size of one block in arena memory allocation.
 Default: 0
 */
@property (nonatomic, assign) size_t arenaBlockSize;

/** @brief Disable automatic compactions. Manual compactions can still be issued
 on the column family. */
@property (nonatomic, assign) BOOL disableAutoCompactions;

/** @brief Purge duplicate/deleted keys when a memtable is flushed to storage. */
@property (nonatomic, assign) BOOL purgeRedundantKvsWhileFlush;

/** @brief An iteration->Next() sequentially skips over keys with the same
 user-key unless this option is set.
 Default: 0
 */
@property (nonatomic, assign) uint64_t maxSequentialSkipInIterations;

/** @brief This is a factory that provides MemTableRep objects.
 Default: A factory that provides a skip-list-based implementation of MemTableRep.

 @see RocksDBMemTableRepFactory
 */
@property (nonatomic, strong, nullable) RocksDBMemTableRepFactory *memTableRepFactory;

/** @brief This is a factory that provides TableFactory objects.
 Default: A block-based table factory that provides a default
 implementation of TableBuilder and TableReader with default
 BlockBasedTableOptions.

 @see RocksDBTableFactory
 */
@property (nonatomic, strong, nullable) RocksDBTableFactory *tableFacotry;

/** @brief If prefixExtractor is set and bloom_bits is not 0, create prefix bloom
 for memtable. If it is larger than 0.25, it is santinized to 0.25.

 @see RocksDBPrefixExtractor
 */
@property (nonatomic, assign) double memtablePrefixBloomSizeRatio;

/** @brief Page size for huge page TLB for bloom in memtable. */
@property (nonatomic, assign) size_t memtableHugePageTlbSize;

/** @brief Control locality of bloom filter probes to improve cache miss rate.
 Default: 0
 */
@property (nonatomic, assign) uint32_t bloomLocality;

/** @brief Maximum number of successive merge operations on a key in the memtable.
 Default: 0 (disabled)
 */
@property (nonatomic, assign) size_t maxSuccessiveMerges;

@end

NS_ASSUME_NONNULL_END
