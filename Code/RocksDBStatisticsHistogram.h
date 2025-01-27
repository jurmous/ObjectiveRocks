//
//  RocksDBStatisticsHistogram.h
//  ObjectiveRocks
//
//  Created by Iska on 04/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** @brief Holds histogram data. */
@interface RocksDBStatisticsHistogram : NSObject

/** @brief The name of this histogram type. */
@property (nonatomic, copy, readonly) NSString *ticker;

/** @brief The median value. */
@property (nonatomic, assign, readonly) double median;

/** @brief The percentile95 value. */
@property (nonatomic, assign, readonly) double percentile95;

/** @brief The percentile99 value. */
@property (nonatomic, assign, readonly) double percentile99;

/** @brief The average value. */
@property (nonatomic, assign, readonly) double average;

/** @brief The standard deviation value. */
@property (nonatomic, assign, readonly) double standardDeviation;

/** @brief The max value. */
@property (nonatomic, assign, readonly) double max;

/** @brief The total count of values. */
@property (nonatomic, assign, readonly) uint64_t count;

/** @brief The summed value. */
@property (nonatomic, assign, readonly) uint64_t sum;

/** @brief The minimum value. */
@property (nonatomic, assign, readonly) double min;

@end

NS_ASSUME_NONNULL_END
