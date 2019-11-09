//
//  RocksDBCache.h
//  ObjectiveRocks
//
//  Created by Iska on 02/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 RocksDB cache.
 */
@interface RocksDBCache : NSObject

/**
 Create a new cache with a fixed size capacity. The cache is sharded
 to 2^numShardBits shards, by hash of the key. The total capacity
 is divided and evenly assigned to each shard. The default 
 numShardBits is 4.

 @param capacity The cache capacity.
 */
+ (instancetype)LRUCacheWithCapacity:(size_t)capacity;

/**
 Create a new cache with a fixed size capacity. The cache is sharded
 to 2^numShardBits shards, by hash of the key. The total capacity
 is divided and evenly assigned to each shard.

 @param capacity The cache capacity.
 @param numShardBits The number of shard bits.
 */
+ (instancetype)LRUCacheWithCapacity:(size_t)capacity numShardsBits:(int)numShardBits;

/**
 Create a new cache with a fixed size capacity. The cache is sharded
 to 2^numShardBits shards, by hash of the key. The total capacity
 is divided and evenly assigned to each shard.

 @param capacity The cache capacity.
 @param numShardBits The number of shard bits.
 @param strictCapacityLimit insert to the cache will fail when cache is full
 @param highPriorityPoolRatio percentage of the cache reserves for high priority entries
*/
+ (instancetype)LRUCacheWithCapacity:(size_t)capacity
					   numShardsBits:(int)numShardBits
				 strictCapacityLimit:(BOOL)strictCapacityLimit
			   highPriorityPoolRatio:(double)highPriorityPoolRatio;

@end

NS_ASSUME_NONNULL_END
