//
//  RocksDBStatistics.m
//  ObjectiveRocks
//

#import "RocksDBStatistics.h"
#import "RocksDBError.h"

#import <rocksdb/statistics.h>

#pragma mark - Informal Protocols

@interface RocksDBStatistics ()
{
	std::shared_ptr<rocksdb::Statistics> _statistics;
}
@property (nonatomic, assign) std::shared_ptr<rocksdb::Statistics> statistics;
@end

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

#pragma mark - Impl

@implementation RocksDBStatistics
@synthesize statistics = _statistics;

#pragma mark - Lifecycle

- (instancetype)init
{
	self = [super init];
	if (self) {
		_statistics = rocksdb::CreateDBStatistics();
	}
	return self;
}

- (void)dealloc
{
	@synchronized(self) {
		if (_statistics != nullptr) {
			_statistics.reset();
		}
	}
}

#pragma mark - Accessor

- (RocksDBStatsLevel)statsLevel
{
	switch (_statistics->get_stats_level()) {
		case rocksdb::kExceptHistogramOrTimers:
			return RocksDBStatsLevelExceptHistogramOrTimers;
		case rocksdb::kExceptTimers:
			return RocksDBStatsLevelExceptTimers;
		case rocksdb::kExceptDetailedTimers:
			return RocksDBStatsLevelExceptDetailedTimers;
		case rocksdb::kExceptTimeForMutex:
			return RocksDBStatsLevelExceptTimeForMutex;
		case rocksdb::kAll:
			return RocksDBStatsLevelAll;
	}
}

- (void)setStatsLevel:(RocksDBStatsLevel)statsLevel
{
	switch (statsLevel) {
		case RocksDBStatsLevelExceptHistogramOrTimers:
			_statistics->set_stats_level(rocksdb::kExceptHistogramOrTimers);
		case RocksDBStatsLevelExceptTimers:
			_statistics->set_stats_level(rocksdb::kExceptTimers);
		case RocksDBStatsLevelExceptDetailedTimers:
			_statistics->set_stats_level(rocksdb::kExceptDetailedTimers);
		case RocksDBStatsLevelExceptTimeForMutex:
			_statistics->set_stats_level(rocksdb::kExceptTimeForMutex);
		case RocksDBStatsLevelAll:
			_statistics->set_stats_level(rocksdb::kAll);
	}
}

- (uint64_t)countForTicker:(RocksDBTicker)ticker
{
	return _statistics->getTickerCount(ticker);
}

- (uint64_t)countForTickerAndReset:(RocksDBTicker)ticker
{
	return _statistics->getAndResetTickerCount(ticker);
}

- (NSString *)histogramStringForType:(RocksDBHistogram)type
{
	std::string histogramString = _statistics->getHistogramString(type);
	return [NSString stringWithCString:histogramString.c_str() encoding:NSUTF8StringEncoding];
}

- (RocksDBStatisticsHistogram *)histogramDataForType:(RocksDBHistogram)ticker
{
	rocksdb::HistogramData *data = new rocksdb::HistogramData;
	_statistics->histogramData(ticker, data);

	RocksDBStatisticsHistogram *histogram = [RocksDBStatisticsHistogram new];

	std::string tickerName = rocksdb::HistogramsNameMap[ticker].second;

	histogram.ticker = [NSString stringWithCString:tickerName.c_str() encoding:NSUTF8StringEncoding];
	histogram.median = data->median;
	histogram.percentile95 = data->percentile95;
	histogram.percentile95 = data->percentile99;
	histogram.average = data->average;
	histogram.standardDeviation = data->standard_deviation;
	histogram.max = data->max;
	histogram.count = data->count;
	histogram.sum = data->sum;
	histogram.min = data->min;

	delete data;

	return histogram;
}

- (BOOL)reset:(NSError *__autoreleasing  _Nullable *)error
{
	rocksdb::Status status = _statistics->Reset();
	if (!status.ok()) {
		NSLog(@"Error resetting Statistics");
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

#pragma mark - Description

- (NSString *)description
{
	return [NSString stringWithCString:_statistics->ToString().c_str() encoding:NSUTF8StringEncoding];
}

@end
