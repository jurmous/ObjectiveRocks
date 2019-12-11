//
//  RocksDBReadOptions.h
//  ObjectiveRocks
//
//  Created by Iska on 20/11/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDBSnapshot.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Options that control read operations. */
@interface RocksDBReadOptions : NSObject <NSCopying> 

/** @brief If true, all data read from underlying storage will be
 verified against corresponding checksums.
 Default: true
 */
@property (nonatomic, assign) BOOL verifyChecksums;

/** @brief If true, the "data block"/"index block"/"filter block" read for this
 iteration will be cached in memory. Callers may wish to set this field to false 
 for bulk scans.
 Default: true
 */
@property (nonatomic, assign) BOOL fillCache;

/**
 Enforce that the iterator only iterates over the same prefix as the seek.
 This option is effective only for prefix seeks, i.e. prefix_extractor is
 non-null for the column family and [.totalOrderSeek] is false.
 Unlike iterate_upper_bound, [.setPrefixSameAsStart] only
 works within a prefix but in both directions.
 */
@property (nonatomic, assign) BOOL prefixSameAsStart;

/**
 Set snapshot to use for read operations
 */
@property (nonatomic, assign) RocksDBSnapshot* snapshot;

@end

NS_ASSUME_NONNULL_END
