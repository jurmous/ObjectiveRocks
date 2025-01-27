//
//  RocksDBReadOptions.m
//  ObjectiveRocks
//
//  Created by Iska on 20/11/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDBReadOptions.h"
#import "RocksDBSnapshot.h"
#import "RocksDBSnapshot+Private.h"
#import <rocksdb/options.h>

@interface RocksDBReadOptions ()
{
	rocksdb::ReadOptions _options;
}
@property (nonatomic, assign) rocksdb::ReadOptions options;
@end

@implementation RocksDBReadOptions

#pragma mark - Lifecycle

- (instancetype)init
{
	self = [super init];
	if (self) {
		_options = rocksdb::ReadOptions();
	}
	return self;
}

#pragma mark - Accessor

- (BOOL)verifyChecksums
{
	return _options.verify_checksums;
}

- (void)setVerifyChecksums:(BOOL)verifyChecksums
{
	_options.verify_checksums = verifyChecksums;
}

- (BOOL)fillCache
{
	return _options.fill_cache;
}

- (void)setFillCache:(BOOL)fillCache
{
	_options.fill_cache = fillCache;
}

- (BOOL)prefixSameAsStart
{
	return _options.prefix_same_as_start;
}

- (void)setPrefixSameAsStart:(BOOL)prefixSameAsStart
{
	_options.prefix_same_as_start = prefixSameAsStart;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	RocksDBReadOptions *copy = [RocksDBReadOptions new];
	copy.options = self.options;
	return copy;
}

- (void)setSnapshot:(RocksDBSnapshot*)snapshot
{
	_options.snapshot = snapshot.snapshot;
}

@end
