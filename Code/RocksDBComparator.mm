//
//  RocksDBComparator.m
//  ObjectiveRocks
//
//  Created by Iska on 22/11/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDBComparator.h"
#import "RocksDBSlice+Private.h"
#import "RocksDBCallbackComparator.h"

#import <rocksdb/comparator.h>
#include <rocksdb/slice.h>

@interface RocksDBComparator ()
{
	NSString *_name;
	int (^_comparatorBlock)(RocksDBSlice *key1, RocksDBSlice *key2);
	const rocksdb::Comparator *_comparator;
}
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) const rocksdb::Comparator *comparator;
@end

@implementation RocksDBComparator
@synthesize name = _name;
@synthesize comparator = _comparator;

#pragma mark - Comparator Factory

+ (instancetype)comparatorWithType:(RocksDBComparatorType)type
{
	switch (type) {
		case RocksDBComparatorBytewiseAscending:
			return [[self alloc] initWithNativeComparator:rocksdb::BytewiseComparator()];

		case RocksDBComparatorBytewiseDescending:
			return [[self alloc] initWithNativeComparator:rocksdb::ReverseBytewiseComparator()];

		case RocksDBComparatorStringCompareAscending:
			return [[self alloc] initWithName:@"objectiverocks.string.compare.asc" andBlock:^int(RocksDBSlice *key1, RocksDBSlice *key2) {
				NSString *str1 = [[NSString alloc] initWithData:key1.toData encoding:NSUTF8StringEncoding];
				NSString *str2 = [[NSString alloc] initWithData:key2.toData encoding:NSUTF8StringEncoding];
				return [str1 compare:str2];
			}];

		case RocksDBComparatorStringCompareDescending:
			return [[self alloc] initWithName:@"objectiverocks.string.compare.desc" andBlock:^int(RocksDBSlice *key1, RocksDBSlice *key2) {

				NSString *str1 = [[NSString alloc] initWithData:key1.toData encoding:NSUTF8StringEncoding];
				NSString *str2 = [[NSString alloc] initWithData:key2.toData encoding:NSUTF8StringEncoding];
				return -1 * [str1 compare:str2];
			}];
	}
}

#pragma mark - Lifecycle

- (instancetype)initWithName:(NSString *)name
					andBlock:(int (^)(RocksDBSlice *key1, RocksDBSlice *key2))block
{
	self = [super init];
	if (self) {
		_name = [name copy];
		_comparatorBlock = [block copy];
		_comparator = RocksDBCallbackComparator((__bridge void *)self, name.UTF8String, &trampoline);
	}
	return self;
}

- (instancetype)initWithNativeComparator:(const rocksdb::Comparator *)comparator
{
	self = [super init];
	if (self) {
		_name = [NSString stringWithCString:comparator->Name() encoding:NSUTF8StringEncoding];
		_comparator = comparator;
	}
	return self;
}

#pragma mark - Callback

- (int)compare:(const rocksdb::Slice &)slice1 with:(const rocksdb::Slice &)slice2
{
	RocksDBSlice *key1 = [[RocksDBSlice alloc] initWithSlice:const_cast<rocksdb::Slice*>(&slice1)];
	RocksDBSlice *key2 = [[RocksDBSlice alloc] initWithSlice:const_cast<rocksdb::Slice*>(&slice2)];
	return _comparatorBlock ? _comparatorBlock(key1, key2) : 0;
}

int trampoline(void* instance, const rocksdb::Slice& slice1, const rocksdb::Slice& slice2)
{
	return [(__bridge id)instance compare:slice1 with:slice2];
}

@end
