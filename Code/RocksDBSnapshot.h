//
//  RocksDBSnapshot.h
//  ObjectiveRocks
//
//  Created by Iska on 06/12/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The `RocksDBSnapshot` provides a consistent read-only view over the state of the key-value store.
 */
@interface RocksDBSnapshot : NSObject

/** @brief Returns the Snapshot's sequence number. */
- (uint64_t)sequenceNumber;

/** @brief Closes the snapshot */
- (void)close;

@end

NS_ASSUME_NONNULL_END
