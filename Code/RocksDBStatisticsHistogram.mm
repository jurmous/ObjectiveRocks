//
//  RocksDBStatisticsHistogram.m
//  ObjectiveRocks
//
//  Created by Iska on 04/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import "RocksDBStatisticsHistogram.h"

@interface RocksDBStatisticsHistogram ()
@property (nonatomic, copy) NSString *ticker;
@property (nonatomic, assign) double median;
@property (nonatomic, assign) double percentile95;
@property (nonatomic, assign) double percentile99;
@property (nonatomic, assign) double average;
@property (nonatomic, assign) double standardDeviation;
@property (nonatomic, assign) double max;
@property (nonatomic, assign) uint64_t count;
@property (nonatomic, assign) uint64_t sum;
@property (nonatomic, assign) double min;
@end

@implementation RocksDBStatisticsHistogram
@synthesize ticker, median, percentile95, percentile99, average, standardDeviation;

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Histogram Type: %@, Median: %f, Percentile 95: %f, Percentile 99: %f, Average: %f, Standard Deviation: %f, Min: %f, Max: %f, Count: %llu, Sum: %llu>",
			self.ticker,
			self.median,
			self.percentile95,
			self.percentile99,
			self.average,
			self.standardDeviation,
			self.min,
			self.max,
			self.count,
			self.sum];
}

@end
