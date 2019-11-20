//
//  RocksDBIndexedWriteBatch+Private.h
//  ObjectiveRocks
//

namespace rocksdb {
	class DB;
	class WriteBatchBase;
	class WriteBatchWithIndex;
}

/**
 This category is intended to hide all C++ types from the public interface in order to
 maintain a pure Objective-C API for Swift compatibility.
 */
@interface RocksDBIndexedWriteBatch (Private)

/** @brief The rocksdb::WriteBatchWithIndex associated with this instance. */
@property (nonatomic, readonly) rocksdb::WriteBatchWithIndex *writeBatchWithIndex;

@end
