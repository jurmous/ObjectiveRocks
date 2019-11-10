//
//  RocksDBSlice.h
//  ObjectiveRocks
//
//  Created by Iska on 10/12/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <rocksdb/slice.h>

#import "RocksDBSlice.h"

NS_INLINE rocksdb::Slice SliceFromData(NSData *data)
{
	return rocksdb::Slice((char *)data.bytes, data.length);
}

NS_INLINE NSData * DataFromSlice(rocksdb::Slice slice)
{
	return [NSData dataWithBytes:slice.data() length:slice.size()];
}

@interface RocksDBSlice (Private)

/**
 Initialize a new RocksDBSlize with a rocksdb::Slice reference
 */
- (instancetype) initWithSlice:(rocksdb::Slice *)slice;

@end
