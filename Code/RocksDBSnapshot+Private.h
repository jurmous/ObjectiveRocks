//
//  RocksDBSnapshot+Private.h
//  ObjectiveRocks
//
//  Created by Iska on 11/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import "RocksDBSnapshot.h"

namespace rocksdb {
	class Snapshot;
}

/**
 This category is intended to hide all C++ types from the public interface in order to
 maintain a pure Objective-C API for Swift compatibility.
 */
@interface RocksDBSnapshot (Private)

@property (nonatomic, assign) const rocksdb::Snapshot *snapshot;

/**
 Initializes a new instance of `RocksDBWriteBatch` with the given options and
 rocksdb::DB abd rocksdb::ColumnFamilyHandle instances.

 @param snapshot The rocksdb::Snapshot instance.
 @return a newly-initialized instance of `RocksDBSnapshot`.

 @see RocksDBReadOptions
 */
- (instancetype)initWithSnapshot:(const rocksdb::Snapshot *)snapshot
							  db:(rocksdb::DB *)db;

@end
