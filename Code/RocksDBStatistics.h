//
//  RocksDBStatistics.h
//  ObjectiveRocks
//
//  Created by Iska on 04/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RocksDBStatisticsHistogram.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, RocksDBStatsLevel)
{
	/** @brief Disable all metrics */
	RocksDBStatsLevelDisableAll,
	/** @brief Disable tickers */
	RocksDBStatsLevelExceptTickers,
	/** @brief Disable timer stats, and skip histogram stats */
	RocksDBStatsLevelExceptHistogramOrTimers,
	/** @brief Skip timer stats */
	RocksDBStatsLevelExceptTimers,
	/** @brief Collect all stats except time inside mutex lock AND time spent on compression. */
	RocksDBStatsLevelExceptDetailedTimers,
	/** @brief Collect all stats except the counters requiring to get time inside the mutex lock. */
	RocksDBStatsLevelExceptTimeForMutex,
	/**
	 @brief Collect all stats, including measuring duration of mutex operations.
	 If getting time is expensive on the platform to run, it can reduce scalability to more threads,
	 especially for writes.
	 */
	RocksDBStatsLevelAll,
};

/** @brief An enum for the Ticker Types. */
typedef NS_ENUM(uint32_t, RocksDBTicker)
{
	/**
	 * total block cache misses
	 * REQUIRES: BLOCK_CACHE_MISS == BLOCK_CACHE_INDEX_MISS +
	 *                               BLOCK_CACHE_FILTER_MISS +
	 *                               BLOCK_CACHE_DATA_MISS
	 */
	RocksDBTickerBlockCacheMiss = 0,

	/**
	 * total block cache hits
	 * REQUIRES: BLOCK_CACHE_HIT == BLOCK_CACHE_INDEX_HIT +
	 *                              BLOCK_CACHE_FILTER_HIT +
	 *                              BLOCK_CACHE_DATA_HIT
	 */
	RocksDBTickerBlockCacheHit,

	/** # of blocks added to block cache. */
	RocksDBTickerBlockCacheAdd,

	/** # of failures when adding blocks to block cache. */
	RocksDBTickerBlockCacheAddFailures,

	/** # of times cache miss when accessing index block from block cache. */
	RocksDBTickerBlockCacheIndexMiss,

	/** # of times cache hit when accessing index block from block cache. */
	RocksDBTickerBlockCacheIndexHit,

	/** # of index blocks added to block cache. */
	RocksDBTickerBlockCacheIndexAdd,

	/** # of bytes of index blocks inserted into cache. */
	RocksDBTickerBlockCacheIndexBytesInsert,

	/** # of times cache miss when accessing filter block from block cache. */
	RocksDBTickerBlockCacheFilterMiss,

	/** # of times cache hit when accessing filter block from block cache. */
	RocksDBTickerBlockCacheFilterHit,

	/** # of filter blocks added to block cache. */
	RocksDBTickerBlockCacheFilterAdd,

	/** # of bytes of bloom filter blocks inserted into cache. */
	RocksDBTickerBlockCacheFilterBytesInsert,

	/** # of times cache miss when accessing data block from block cache. */
	RocksDBTickerBlockCacheDataMiss,

	/** # of times cache hit when accessing data block from block cache. */
	RocksDBTickerBlockCacheDataHit,

	/** # of data blocks added to block cache. */
	RocksDBTickerBlockCacheDataAdd,

	/** # of bytes of data blocks inserted into cache. */
	RocksDBTickerBlockCacheDataBytesInsert,

	/** # of bytes read from cache. */
	RocksDBTickerBlockCacheBytesRead,

	/** # of bytes written into cache. */
	RocksDBTickerBlockCacheBytesWrite,

	/** # of times cache miss when accessing dict block from block cache. */
	RocksDBTickerBlockCacheCompressionDictMiss,

	/** # of times cache hit when accessing dict block from block cache. */
	RocksDBTickerBlockCacheCompressionDictHit,

	/** # of dict blocks added to block cache. */
	RocksDBTickerBlockCacheCompressionDictAdd,

	/** # of bytes of dict blocks inserted into cache. */
	RocksDBTickerBlockCacheCompressionDictBytesInsert,

	/**
	 * # of blocks redundantly inserted into block cache.
	 * REQUIRES: BLOCK_CACHE_ADD_REDUNDANT <= BLOCK_CACHE_ADD
	 */
	RocksDBTickerBlockCacheAddRedundant,

	/**
	 * # of index blocks redundantly inserted into block cache.
	 * REQUIRES: BLOCK_CACHE_INDEX_ADD_REDUNDANT <= BLOCK_CACHE_INDEX_ADD
	 */
	RocksDBTickerBlockCacheIndexAddRedundant,

	/**
	 * # of filter blocks redundantly inserted into block cache.
	 * REQUIRES: BLOCK_CACHE_FILTER_ADD_REDUNDANT <= BLOCK_CACHE_FILTER_ADD
	 */
	RocksDBTickerBlockCacheFilterAddRedundant,

	/**
	 * # of data blocks redundantly inserted into block cache.
	 * REQUIRES: BLOCK_CACHE_DATA_ADD_REDUNDANT <= BLOCK_CACHE_DATA_ADD
	 */
	RocksDBTickerBlockCacheDataAddRedundant,

	/**
	 * # of dict blocks redundantly inserted into block cache.
	 * REQUIRES: BLOCK_CACHE_COMPRESSION_DICT_ADD_REDUNDANT
	 *           <= BLOCK_CACHE_COMPRESSION_DICT_ADD
	 */
	RocksDBTickerBlockCacheCompressionDictAddRedundant,

	/** # of hits in secondary cache (overall). */
	RocksDBTickerSecondaryCacheHits,

	/** # of hits in secondary cache for filter blocks. */
	RocksDBTickerSecondaryCacheFilterHits,

	/** # of hits in secondary cache for index blocks. */
	RocksDBTickerSecondaryCacheIndexHits,

	/** # of hits in secondary cache for data blocks. */
	RocksDBTickerSecondaryCacheDataHits,

	/** Compressed secondary cache dummy hits (for debugging). */
	RocksDBTickerCompressedSecondaryCacheDummyHits,

	/** # of hits in compressed secondary cache. */
	RocksDBTickerCompressedSecondaryCacheHits,

	/** # of promotions from compressed to uncompressed secondary cache. */
	RocksDBTickerCompressedSecondaryCachePromotions,

	/** # of promotion skips in compressed secondary cache. */
	RocksDBTickerCompressedSecondaryCachePromotionSkips,

	/** # of times bloom filter has avoided file reads (negatives). */
	RocksDBTickerBloomFilterUseful,

	/** # of times bloom FullFilter has not avoided reads. */
	RocksDBTickerBloomFilterFullPositive,

	/** # of times bloom FullFilter has not avoided reads and data actually exists. */
	RocksDBTickerBloomFilterFullTruePositive,

	/** # of times bloom prefix filter was checked. */
	RocksDBTickerBloomFilterPrefixChecked,

	/** # of times bloom prefix filter was useful. */
	RocksDBTickerBloomFilterPrefixUseful,

	/**
	 * # of times bloom prefix filter returned a "true positive" for a single
	 * key read. A second key with the same prefix is considered false positive
	 * for these stats.
	 */
	RocksDBTickerBloomFilterPrefixTruePositive,

	/** # persistent cache hit. */
	RocksDBTickerPersistentCacheHit,

	/** # persistent cache miss. */
	RocksDBTickerPersistentCacheMiss,

	/** # total simulation block cache hits. */
	RocksDBTickerSimBlockCacheHit,

	/** # total simulation block cache misses. */
	RocksDBTickerSimBlockCacheMiss,

	/** # of memtable hits. */
	RocksDBTickerMemtableHit,

	/** # of memtable misses. */
	RocksDBTickerMemtableMiss,

	/** # of Get() queries served by L0. */
	RocksDBTickerGetHit_L0,

	/** # of Get() queries served by L1. */
	RocksDBTickerGetHit_L1,

	/** # of Get() queries served by L2 and up. */
	RocksDBTickerGetHit_L2_AndUp,

	/**
	 * COMPACTION_KEY_DROP_* count the reasons for key drop during compaction.
	 * There are 4 reasons currently.
	 */
	RocksDBTickerCompactionKeyDropNewerEntry,      // Key was written with a newer value (includes range del).
	RocksDBTickerCompactionKeyDropObsolete,        // The key is obsolete.
	RocksDBTickerCompactionKeyDropRangeDel,        // Key was covered by a range tombstone.
	RocksDBTickerCompactionKeyDropUser,            // Dropped by user compaction filter.
	RocksDBTickerCompactionRangeDelDropObsolete,   // All keys in range were deleted.
	RocksDBTickerCompactionOptimizedDelDropObsolete, // Deletions obsoleted before bottom level due to file gap.
	RocksDBTickerCompactionCancelled,              // If a compaction was canceled in sfm to prevent ENOSPC.

	/** Number of keys written via Put/Write. */
	RocksDBTickerNumberKeysWritten,

	/** Number of keys read. */
	RocksDBTickerNumberKeysRead,

	/** Number of keys updated, if inplace update is enabled. */
	RocksDBTickerNumberKeysUpdated,

	/** Uncompressed bytes issued by DB::Put(), DB::Delete(), DB::Merge(), DB::Write(). */
	RocksDBTickerBytesWritten,

	/**
	 * Uncompressed bytes read by DB::Get(). Could be from memtables, cache,
	 * or table files.
	 */
	RocksDBTickerBytesRead,

	/** The number of calls to seek. */
	RocksDBTickerNumberDBSeek,

	/** The number of calls to next. */
	RocksDBTickerNumberDBNext,

	/** The number of calls to prev. */
	RocksDBTickerNumberDBPrevious,

	/** The number of calls to seek that returned data. */
	RocksDBTickerNumberDBSeekFound,

	/** The number of calls to next that returned data. */
	RocksDBTickerNumberDBNextFound,

	/** The number of calls to prev that returned data. */
	RocksDBTickerNumberDBPreviousFound,

	/**
	 * The number of uncompressed bytes read from an iterator
	 * (includes size of key and value).
	 */
	RocksDBTickerIterBytesRead,

	/** Number of internal keys skipped by Iterator. */
	RocksDBTickerNumberIterSkip,

	/**
	 * Number of times we had to reseek inside an iteration to skip
	 * over large number of keys with same userkey.
	 */
	RocksDBTickerNumberOfReseeksInIteration,

	/** Number of iterators created. */
	RocksDBTickerNoIteratorCreated,

	/** Number of iterators deleted. */
	RocksDBTickerNoIteratorDeleted,

	/** Number of file opens. */
	RocksDBTickerNoFileOpens,

	/** Number of file errors. */
	RocksDBTickerNoFileErrors,

	/**
	 * Writer has to wait for compaction or flush to finish.
	 * The total wait time in microseconds.
	 */
	RocksDBTickerStallMicros,

	/**
	 * The wait time for DB mutex in microseconds.
	 * Disabled by default. Requires StatsLevel::kAll.
	 */
	RocksDBTickerDBMutexWaitMicros,

	/** Number of MultiGet calls. */
	RocksDBTickerNumberMultigetCalls,

	/** Number of MultiGet keys read. */
	RocksDBTickerNumberMultigetKeysRead,

	/** Number of MultiGet bytes read. */
	RocksDBTickerNumberMultigetBytesRead,

	/**
	 * Number of keys actually found in MultiGet calls (versus number
	 * requested by caller).
	 */
	RocksDBTickerNumberMultigetKeysFound,

	/** Number of merge failures. */
	RocksDBTickerNumberMergeFailures,

	/** Number of calls to GetUpdatesSince. */
	RocksDBTickerGetUpdatesSinceCalls,

	/** Number of times WAL sync is done. */
	RocksDBTickerWalFileSynced,

	/** Number of bytes written to WAL. */
	RocksDBTickerWalFileBytes,

	/**
	 * Writes done by the requesting thread (as opposed to thread at head
	 * of the writer queue).
	 */
	RocksDBTickerWriteDoneBySelf,

	/** Writes done by a thread at the head of the writer queue. */
	RocksDBTickerWriteDoneByOther,

	/** Number of Write calls that request WAL. */
	RocksDBTickerWriteWithWal,

	/** Bytes read during compaction. */
	RocksDBTickerCompactReadBytes,

	/** Bytes written during compaction. */
	RocksDBTickerCompactWriteBytes,

	/** Bytes written during flush. */
	RocksDBTickerFlushWriteBytes,

	/** Bytes read during compaction marked. */
	RocksDBTickerCompactReadBytesMarked,

	/** Bytes read during compaction periodic. */
	RocksDBTickerCompactReadBytesPeriodic,

	/** Bytes read during compaction TTL. */
	RocksDBTickerCompactReadBytesTTL,

	/** Bytes written during compaction marked. */
	RocksDBTickerCompactWriteBytesMarked,

	/** Bytes written during compaction periodic. */
	RocksDBTickerCompactWriteBytesPeriodic,

	/** Bytes written during compaction TTL. */
	RocksDBTickerCompactWriteBytesTTL,

	/**
	 * Number of table's properties loaded directly from file, without
	 * creating table reader object.
	 */
	RocksDBTickerNumberDirectLoadTableProperties,

	/** Number of superversions acquired. */
	RocksDBTickerNumberSuperversionAcquires,

	/** Number of superversions released. */
	RocksDBTickerNumberSuperversionReleases,

	/** Number of superversions cleaned up. */
	RocksDBTickerNumberSuperversionCleanups,

	/** # of compressions executed. */
	RocksDBTickerNumberBlockCompressed,

	/** # of decompressions executed. */
	RocksDBTickerNumberBlockDecompressed,

	/**
	 * The number of input bytes (uncompressed) to compression for SST blocks
	 * that are stored compressed.
	 */
	RocksDBTickerBytesCompressedFrom,

	/**
	 * The number of output bytes (compressed) from compression for SST blocks
	 * that are stored compressed.
	 */
	RocksDBTickerBytesCompressedTo,

	/**
	 * Number of uncompressed bytes for SST blocks stored uncompressed
	 * (kNoCompression, or compression not run/accepted).
	 */
	RocksDBTickerBytesCompressionBypassed,

	/**
	 * Number of input bytes (uncompressed) to compression for SST blocks that
	 * were rejected (e.g. ratio not acceptable).
	 */
	RocksDBTickerBytesCompressionRejected,

	/** Like BYTES_COMPRESSION_BYPASSED but counting number of blocks. */
	RocksDBTickerNumberBlockCompressionBypassed,

	/** Like BYTES_COMPRESSION_REJECTED but counting number of blocks. */
	RocksDBTickerNumberBlockCompressionRejected,

	/**
	 * Number of input bytes (compressed) to decompression in reading compressed
	 * SST blocks from storage.
	 */
	RocksDBTickerBytesDecompressedFrom,

	/**
	 * Number of output bytes (uncompressed) from decompression in reading
	 * compressed SST blocks from storage.
	 */
	RocksDBTickerBytesDecompressedTo,

	/** The total time of the merge operation in nanoseconds. */
	RocksDBTickerMergeOperationTotalTime,

	/** The total time of the filter operation in nanoseconds. */
	RocksDBTickerFilterOperationTotalTime,

	/** The total CPU time spent in compaction. */
	RocksDBTickerCompactionCpuTotalTime,

	/** Total row cache hits. */
	RocksDBTickerRowCacheHit,

	/** Total row cache misses. */
	RocksDBTickerRowCacheMiss,

	/**
	 * Read amplification: READ_AMP_TOTAL_READ_BYTES / READ_AMP_ESTIMATE_USEFUL_BYTES
	 * requires ReadOptions::read_amp_bytes_per_bit to be enabled.
	 */
	RocksDBTickerReadAmpEstimateUsefulBytes, // Estimate of total bytes actually used.
	RocksDBTickerReadAmpTotalReadBytes,      // Total size of loaded data blocks.

	/**
	 * Number of refill intervals where rate limiter's bytes
	 * are fully consumed.
	 */
	RocksDBTickerNumberRateLimiterDrains,

	// --- Legacy (Original) BlobDB statistics (pre-Integrated BlobDB) ---

	/** # of Put/PutTTL/PutUntil to BlobDB. */
	RocksDBTickerBlobDBNumPut,

	/** # of Write to BlobDB. */
	RocksDBTickerBlobDBNumWrite,

	/** # of Get to BlobDB. */
	RocksDBTickerBlobDBNumGet,

	/** # of MultiGet to BlobDB. */
	RocksDBTickerBlobDBNumMultiget,

	/** # of Seek/SeekToFirst/SeekToLast/SeekForPrev to BlobDB iterator. */
	RocksDBTickerBlobDBNumSeek,

	/** # of Next to BlobDB iterator. */
	RocksDBTickerBlobDBNumNext,

	/** # of Prev to BlobDB iterator. */
	RocksDBTickerBlobDBNumPrev,

	/** # of keys written to BlobDB. */
	RocksDBTickerBlobDBNumKeysWritten,

	/** # of keys read from BlobDB. */
	RocksDBTickerBlobDBNumKeysRead,

	/** # of bytes (key + value) written to BlobDB. */
	RocksDBTickerBlobDBBytesWritten,

	/** # of bytes (key + value) read from BlobDB. */
	RocksDBTickerBlobDBBytesRead,

	/** # of keys written by BlobDB as non-TTL inlined value. */
	RocksDBTickerBlobDBWriteInlined,

	/** # of keys written by BlobDB as TTL inlined value. */
	RocksDBTickerBlobDBWriteInlinedTTL,

	/** # of keys written by BlobDB as non-TTL blob value. */
	RocksDBTickerBlobDBWriteBlob,

	/** # of keys written by BlobDB as TTL blob value. */
	RocksDBTickerBlobDBWriteBlobTTL,

	/** # of bytes written to blob file. */
	RocksDBTickerBlobDBBlobFileBytesWritten,

	/** # of bytes read from blob file. */
	RocksDBTickerBlobDBBlobFileBytesRead,

	/** # of times a blob file is synced. */
	RocksDBTickerBlobDBBlobFileSynced,

	/**
	 * # of blob indexes evicted from base DB by BlobDB compaction filter
	 * because of expiration.
	 */
	RocksDBTickerBlobDBBlobIndexExpiredCount,

	/**
	 * Size of blob index evicted from base DB by BlobDB compaction filter
	 * because of expiration.
	 */
	RocksDBTickerBlobDBBlobIndexExpiredSize,

	/**
	 * # of blob indexes evicted from base DB by BlobDB compaction filter
	 * because of file deletion.
	 */
	RocksDBTickerBlobDBBlobIndexEvictedCount,

	/**
	 * Size of blob indexes evicted from base DB by BlobDB compaction filter
	 * because of file deletion.
	 */
	RocksDBTickerBlobDBBlobIndexEvictedSize,

	/** # of blob files being garbage collected. */
	RocksDBTickerBlobDBGCNumFiles,

	/** # of blob files generated by garbage collection. */
	RocksDBTickerBlobDBGCNumNewFiles,

	/** # of BlobDB garbage collection failures. */
	RocksDBTickerBlobDBGCFailures,

	/** # of keys relocated to new blob file by garbage collection. */
	RocksDBTickerBlobDBGCNumKeysRelocated,

	/** # of bytes relocated to new blob file by garbage collection. */
	RocksDBTickerBlobDBGCBytesRelocated,

	/** # of blob files evicted because BlobDB is full. */
	RocksDBTickerBlobDBFifoNumFilesEvicted,

	/** # of keys in the blob files evicted because BlobDB is full. */
	RocksDBTickerBlobDBFifoNumKeysEvicted,

	/** # of bytes in the blob files evicted because BlobDB is full. */
	RocksDBTickerBlobDBFifoBytesEvicted,

	// --- Integrated BlobDB stats ---

	/** # of times cache miss when accessing a blob from blob cache. */
	RocksDBTickerBlobDbCacheMiss,

	/** # of times cache hit when accessing a blob from blob cache. */
	RocksDBTickerBlobDbCacheHit,

	/** # of data blocks added to blob cache. */
	RocksDBTickerBlobDbCacheAdd,

	/** # of failures when adding blobs to blob cache. */
	RocksDBTickerBlobDbCacheAddFailures,

	/** # of bytes read from blob cache. */
	RocksDBTickerBlobDbCacheBytesRead,

	/** # of bytes written into blob cache. */
	RocksDBTickerBlobDbCacheBytesWrite,

	// --- WritePrepared Transaction concurrency overheads ---

	/** # of times prepare_mutex_ is acquired in the fast path. */
	RocksDBTickerTxnPrepareMutexOverhead,

	/** # of times old_commit_map_mutex_ is acquired in the fast path. */
	RocksDBTickerTxnOldCommitMapMutexOverhead,

	/** # of times we checked a batch for duplicate keys. */
	RocksDBTickerTxnDuplicateKeyOverhead,

	/** # of times snapshot_mutex_ is acquired in the fast path. */
	RocksDBTickerTxnSnapshotMutexOverhead,

	/** # of times ::Get returned TryAgain due to expired snapshot seq. */
	RocksDBTickerTxnGetTryAgain,

	// --- File trash/deletion stats (SstFileManager) ---

	/** # of files marked as trash (to be deleted later). */
	RocksDBTickerFilesMarkedTrash,

	/** # of trash files deleted by background thread from the trash queue. */
	RocksDBTickerFilesDeletedFromTrashQueue,

	/** # of files deleted immediately by the delete scheduler. */
	RocksDBTickerFilesDeletedImmediately,

	// --- Error Handler stats ---

	/** # of background errors. */
	RocksDBTickerErrorHandlerBgErrorCount,

	/** # of background I/O errors. */
	RocksDBTickerErrorHandlerBgIoErrorCount,

	/** # of retryable background I/O errors. */
	RocksDBTickerErrorHandlerBgRetryableIoErrorCount,

	/** # of times auto-resume was triggered. */
	RocksDBTickerErrorHandlerAutoresumeCount,

	/** Total # of auto-resume retries. */
	RocksDBTickerErrorHandlerAutoresumeRetryTotalCount,

	/** # of auto-resume successes. */
	RocksDBTickerErrorHandlerAutoresumeSuccessCount,

	// --- Memtable GC stats ---

	/** Raw payload bytes in memtable at flush time. */
	RocksDBTickerMemtablePayloadBytesAtFlush,

	/** Outdated/garbage bytes in memtable at flush time. */
	RocksDBTickerMemtableGarbageBytesAtFlush,

	// --- Checksum verification stats ---

	/** Bytes read by `VerifyChecksum()` and `VerifyFileChecksums()`. */
	RocksDBTickerVerifyChecksumReadBytes,

	// --- Backup stats ---

	/** Bytes read while creating backups. */
	RocksDBTickerBackupReadBytes,

	/** Bytes written while creating backups. */
	RocksDBTickerBackupWriteBytes,

	// --- Remote compaction stats ---

	/** Bytes read during remote compaction. */
	RocksDBTickerRemoteCompactReadBytes,

	/** Bytes written during remote compaction. */
	RocksDBTickerRemoteCompactWriteBytes,

	// --- Tiered storage stats ---

	/** Bytes read from hot-tier files. */
	RocksDBTickerHotFileReadBytes,

	/** Bytes read from warm-tier files. */
	RocksDBTickerWarmFileReadBytes,

	/** Bytes read from cold-tier files. */
	RocksDBTickerColdFileReadBytes,

	/** Read operations to hot-tier files. */
	RocksDBTickerHotFileReadCount,

	/** Read operations to warm-tier files. */
	RocksDBTickerWarmFileReadCount,

	/** Read operations to cold-tier files. */
	RocksDBTickerColdFileReadCount,

	/** Last-level read bytes. */
	RocksDBTickerLastLevelReadBytes,

	/** Last-level read count. */
	RocksDBTickerLastLevelReadCount,

	/** Non-last-level read bytes. */
	RocksDBTickerNonLastLevelReadBytes,

	/** Non-last-level read count. */
	RocksDBTickerNonLastLevelReadCount,

	// --- Iterator-level Seek stats across sorted runs ---

	/** # of times last-level Seek was filtered out (like prefix Bloom). */
	RocksDBTickerLastLevelSeekFiltered,

	/** # of times last-level Seek's filter indicated a match. */
	RocksDBTickerLastLevelSeekFilterMatch,

	/** # of times last-level Seek read at least one data block. */
	RocksDBTickerLastLevelSeekData,

	/**
	 * # of times last-level Seek found a useful value without filter.
	 * (At least one real value read.)
	 */
	RocksDBTickerLastLevelSeekDataUsefulNoFilter,

	/**
	 * # of times last-level Seek found a useful value after filter match.
	 */
	RocksDBTickerLastLevelSeekDataUsefulFilterMatch,

	/** # of times non-last-level Seek was filtered out. */
	RocksDBTickerNonLastLevelSeekFiltered,

	/** # of times non-last-level Seek's filter indicated a match. */
	RocksDBTickerNonLastLevelSeekFilterMatch,

	/** # of times non-last-level Seek read at least one data block. */
	RocksDBTickerNonLastLevelSeekData,

	/**
	 * # of times non-last-level Seek found a useful value
	 * without filter checking.
	 */
	RocksDBTickerNonLastLevelSeekDataUsefulNoFilter,

	/**
	 * # of times non-last-level Seek found a useful value
	 * after filter match.
	 */
	RocksDBTickerNonLastLevelSeekDataUsefulFilterMatch,

	// --- Block checksum stats ---

	/** # of block checksums computed (verification). */
	RocksDBTickerBlockChecksumComputeCount,

	/**
	 * # of block checksums that mismatched, i.e. corruption was detected.
	 * (Each read can detect the same corrupted block multiple times, if
	 * the data is not fixed or re-fetched.)
	 */
	RocksDBTickerBlockChecksumMismatchCount,

	/** # of MultiGet coroutines created. */
	RocksDBTickerMultigetCoroutineCount,

	/**
	 * Time spent in `ReadAsync` file system call (for asynchronous read).
	 * Sum of microseconds.
	 */
	RocksDBTickerReadAsyncMicros,

	/** # of async read callbacks returning an error. */
	RocksDBTickerAsyncReadErrorCount,

	/**
	 * # of times a table open read found no data in the prefetched tail region.
	 */
	RocksDBTickerTableOpenPrefetchTailMiss,

	/**
	 * # of times a table open read found the needed data in the prefetched tail region.
	 */
	RocksDBTickerTableOpenPrefetchTailHit,

	// --- Timestamp filtering stats ---

	/** # of times timestamps are checked when opening/reading a table. */
	RocksDBTickerTimestampFilterTableChecked,

	/** # of times timestamps helped skip table access entirely. */
	RocksDBTickerTimestampFilterTableFiltered,

	/**
	 * # of times readahead is trimmed during scans
	 * (ReadOptions.auto_readahead_size is set).
	 */
	RocksDBTickerReadaheadTrimmed,

	// --- FIFO compaction stats ---

	/** # of times FIFO compactions drop files by max size condition. */
	RocksDBTickerFifoMaxSizeCompactions,

	/** # of times FIFO compactions drop files by TTL condition. */
	RocksDBTickerFifoTtlCompactions,

	// --- Prefetch stats for user scans ---

	/** # of bytes prefetched during user-initiated scan. */
	RocksDBTickerPrefetchBytes,

	/** # of prefetched bytes that were actually used. */
	RocksDBTickerPrefetchBytesUseful,

	/** # of FS reads avoided because data was prefetched. */
	RocksDBTickerPrefetchHits,

	/** # of footer corruptions detected when opening SST files. */
	RocksDBTickerSstFooterCorruptionCount,

	// --- File read corruption retries (verify_and_reconstruct_read) ---

	/** # of file read retries after detecting a block checksum mismatch. */
	RocksDBTickerFileReadCorruptionRetryCount,

	/** # of successful file read retries after a block checksum mismatch. */
	RocksDBTickerFileReadCorruptionRetrySuccessCount,

	/**
	 * Keep this at the end. Used to determine the size of the enum.
	 */
	RocksDBTickerEnumMax
};

/** @brief An enum for the Histogram Types. */
typedef NS_ENUM(uint32_t, RocksDBHistogram)
{
	/** @brief Time spent in DB Get() calls */
	RocksDBHistogramDBGet = 0,

	/** @brief Time spent in DB Write() calls */
	RocksDBHistogramDBWrite,

	/** @brief Time spent during compaction. */
	RocksDBHistogramCompactionTime,

	/** @brief Time spent during subcompaction. */
	RocksDBHistogramSubcompactionTime,

	/** @brief Time spent during table syncs. */
	RocksDBHistogramTableSyncMicros,

	/** @brief Time spent during compaction outfile syncs. */
	RocksDBHistogramCompactionOutfileSyncMicros,

	/** @brief Time spent during WAL file syncs. */
	RocksDBHistogramWalFileSyncMicros,

	/** @brief Time spent during manifest file syncs. */
	RocksDBHistogramManifestFileSyncMicros,

	/** @brief Time spent during in IO during table open. */
	RocksDBHistogramTableOpenIOMicros,

	/** @brief Time spend during DB MultiGet() calls. */
	RocksDBHistogramDBMultiget,

	/** @brief Time spend during read block compaction. */
	RocksDBHistogramReadBlockCompactionMicros,

	/** @brief Time spend during read block Get(). */
	RocksDBHistogramReadBlockGetMicros,

	/** @brief Time spend during write raw blocks. */
	RocksDBHistogramWriteRawBlockMicros,

	/** @brief The number of stalls in L0 slowdowns. */
	RocksDBHistogramStall_L0SlowdownCount,

	/** @brief The number of stalls in memtable compations */
	RocksDBHistogramStallMemtableCompactionCount,

	/** @brief The number of stalls in L0 files. */
	RocksDBHistogramStall_L0NumFilesCount,

	/** @brief The count of delays in hard rate limiting. */
	RocksDBHistogramHardRateLimitDelayCount,

	/** @brief The count of delays in soft rate limiting. */
	RocksDBHistogramSoftRateLimitDelayCount,

	/** @brief The number of files in a single compaction. */
	RocksDBHistogramNumFilesInSingleCompaction,

	/** @brief Time Spent in Seek() calls. */
	RocksDBHistogramDBSeek,

	/** @brief Time spent in Write Stall. */
	RocksDBHistogramWriteStall,

	/** @brief  Time spent in SST Read. */
	RocksDBHistogramSSTReadMicros,

	/** @brief The number of subcompactions actually scheduled during a compaction. */
	RocksDBHistogramNumCompactionsScheduled,

	/** @brief Distribution of bytes read in each operations. */
	RocksDBHistogramBytesPerRead,

	/** @brief Distribution of bytes written in each operations. */
	RocksDBHistogramBytesPerWrite,

	/** @brief Distribution of bytes via multiget in each operations. */
	RocksDBHistogramBytesPerMultiGet,

	/** @brief # of bytes compressed. */
	RocksDBHistogramBytesCompressed,

	/** @brief # of bytes decompressed. */
	RocksDBHistogramBytesDecompressed,

	/** @brief Compression time. */
	RocksDBHistogramCompressionTimeNanos,

	/** @brief Decompression time. */
	RocksDBHistogramDecompressionTimeNanos,

	/** @brief Number of merge operands passed to the merge operator in user read requests. **/
	RocksDBHistogramReadNumMergeOperands,

	/** @brief Size of keys written to BlobDB. **/
	RocksDBHistogramBlobDbKeySize,

	/** @brief Size of values written to BlobDB. **/
	RocksDBHistogramBlobDbValueSize,

	/** @brief BlobDB Put/PutWithTTL/PutUntil/Write latency. **/
	RocksDBHistogramBlobDbWriteMicros,

	/** @brief BlobDB Get lagency. **/
	RocksDBHistogramBlobDbGetMicros,

	/** @brief BlobDB MultiGet lagency. **/
	RocksDBHistogramBlobDbMultigetMicros,

	/** @brief BlobDB Seek/SeekToFirst/SeekToLast/SeekForPrev latency. **/
	RocksDBHistogramBlobDbSeekMicros,

	/** @brief BlobDB Next latency. **/
	RocksDBHistogramBlobDbNextMicros,

	/** @brief BlobDB Prev latency. **/
	RocksDBHistogramBlobDbPrevMicros,

	/** @brief Blob file write latency. **/
	RocksDBHistogramBlobDbBlobFileWriteMicros,

	/** @brief Blob file read latency. **/
	RocksDBHistogramBlobDbBlobFileReadMicros,

	/** @brief Blob file sync latency. **/
	RocksDBHistogramBlobDbBlobFileSyncMicros,

	/** @brief BlobDB garbage collection time. **/
	RocksDBHistogramBlobDbGcMicros,

	/** @brief BlobDB compression time. **/
	RocksDBHistogramBlobDbCompressionMicros,

	/** @brief BlobDB decompression time. **/
	RocksDBHistogramBlobDbDecompressionMicros,

	/** @brief Time spent flushing memtable to disk. **/
	RocksDBHistogramFlushTime
};

/**
 The `RocksDBStatistics`, when set in the `RocksDBOptions`, is used to collect usage statistics.

 @see RocksDBOptions
 */
@interface RocksDBStatistics : NSObject

@property (nonatomic, readwrite) RocksDBStatsLevel statsLevel;

/**
 Returns the value for the given ticker.

 @param ticker The ticker type to get.
 @return The value for the given ticker type.
*/
- (uint64_t)countForTicker:(RocksDBTicker)ticker;

/**
 Returns the value for the given ticker and resets ticker count.

 @param ticker The ticker type to get.
 @return The value for the given ticker type.
*/
- (uint64_t)countForTickerAndReset:(RocksDBTicker)ticker;

/**
 Returns the histogram for the given histogram type.

 @param type The type of the histogram to get.
 @return The value for the given histogram type.

 @see RocksDBStatisticsHistogram
 */
- (RocksDBStatisticsHistogram *)histogramDataForType:(RocksDBHistogram)type;

/**
 Returns the histogram as a String for the given histogram type.

 @param type The type of the histogram to get.
 @return The value for the given histogram type.
 */
- (NSString *)histogramStringForType:(RocksDBHistogram)type;

/** @brief String representation of the statistic object. */
- (NSString *)description;

/**
 Resets all ticker and histogram stats.
 */
- (BOOL)reset:(NSError *__autoreleasing  _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
