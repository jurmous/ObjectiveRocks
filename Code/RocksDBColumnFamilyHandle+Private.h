//
//  RocksDBColumnFamilyHandle+Private.h
//  ObjectiveRocks
//
//  Created by Jurriaan Mous on 20/10/2019.
//  Copyright © 2019 BrainCookie. All rights reserved.
//

#import "RocksDBColumnFamilyHandle.h"

namespace rocksdb {
	class ColumnFamilyHandle;
}

/**
 This category is intended to hide all C++ types from the public interface in order to
 maintain a pure Objective-C API for Swift compatibility.
 */
@interface RocksDBColumnFamilyHandle (Private)

/** @brief The underlying rocksdb::ColumnFamilyHandle associated with this instance. */
@property (nonatomic, assign) rocksdb::ColumnFamilyHandle *columnFamily;

/**
 Initializes a new instance of `RocksDBColumnFamilyHandle` with the given options for
 and rocks::ColumnFamilyHandle instances.

 @param columnFamily The rocks::ColumnFamilyHandle instance.
 @return a newly-initialized instance of `RocksDBColumnFamily`.
 */
- (instancetype)initWithColumnFamily:(rocksdb::ColumnFamilyHandle *)columnFamily;

@end
