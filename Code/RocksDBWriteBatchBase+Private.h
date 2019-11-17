//
//  RocksDBWriteBatch+Private.h
//  ObjectiveRocks
//

#import "RocksDBWriteBatch.h"

namespace rocksdb {
	class DB;
	class WriteBatchBase;
}

/**
 This category is intended to hide all C++ types from the public interface in order to
 maintain a pure Objective-C API for Swift compatibility.
 */
@interface RocksDBWriteBatchBase (Private)

/** @brief The rocksdb::WriteBatchBase associated with this instance. */
@property (nonatomic, readonly) rocksdb::WriteBatchBase *writeBatchBase;

/**
 Initializes a new instance of `RocksDBWriteBatch` with the given native rocksdb::WriteBatchBase
 instance, encoding options and RocksDBColumnFamilyHandle instance.

 @discussion This initializer is used by the subclasses of `RocksDBWriteBatch`.

 @param writeBatchBase An instance of a concrete subclass implementation of rocksdb::WriteBatchBase.
 @return a newly-initialized instance of `RocksDBWriteBatch`.
 */
- (instancetype)initWithNativeWriteBatchBase:(rocksdb::WriteBatchBase *)writeBatchBase;

@end
