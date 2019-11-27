//
//  RocksDBEnv+Private.h
//  ObjectiveRocks
//

namespace rocksdb {
	class Env;
}

/**
 This category is intended to hide all C++ types from the public interface in order to
 maintain a pure Objective-C API for Swift compatibility.
 */
@interface RocksDBEnv (Private)

/**
 Reference to internal c++ Env
 */
@property (nonatomic, readonly) rocksdb::Env *env;

/**
 Initializes a new instance of `RocksDBEnv`

 @param env The rocksdb::Env instance.
 @return a newly-initialized instance of `RocksDBEnv`.
 */
- (instancetype)initWithEnv:(rocksdb::Env *)env;

@end
