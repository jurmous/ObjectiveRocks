//
//  RocksDBSlice.m
//  ObjectiveRocks
//

#import <Foundation/Foundation.h>
#import "RocksDBSlice.h"
#import "RocksDBSlice+Private.h"

@interface RocksDBSlice ()
{
	rocksdb::Slice *_slice;
}
@property (nonatomic, assign) const rocksdb::Slice *slice;
@end

@implementation RocksDBSlice : NSObject
@synthesize slice = _slice;

- (instancetype)init
{
	self = [super init];
	if (self) {
		_slice = new rocksdb::Slice();
	}
	return self;
}

- (instancetype)initWithSlice:(rocksdb::Slice *)slice
{
	self = [super init];
	if (self) {
		_slice = new rocksdb::Slice(*slice);
	}
	return self;
}

- (instancetype)initWithString:(NSString *)string
{
	self = [super init];
	if (self) {
		_slice = new rocksdb::Slice([string cStringUsingEncoding: NSNonLossyASCIIStringEncoding]);
	}
	return self;
}

- (instancetype)initWithBytes:(char*)bytes
{
	self = [super init];
	if (self) {
		_slice = new rocksdb::Slice(bytes);
	}
	return self;
}

- (instancetype)initWithBytes:(char *)bytes length:(size_t)length
{
	self = [super init];
	if (self) {
		_slice = new rocksdb::Slice(bytes, length);
	}
	return self;
}

- (instancetype)initWithBytes:(char *)bytes offset:(size_t)offset length:(size_t)length
{
	self = [super init];
	if (self) {
		_slice = new rocksdb::Slice(bytes + offset, length);
	}
	return self;
}

- (const char*)data
{
	return _slice->data();
}

- (char)get:(int)index
{
	return _slice->data_[index];
}

- (void)removePrefix:(size_t)n
{
	_slice->remove_prefix(n);
}

- (void)clear
{
	_slice->clear();
}

- (BOOL)empty
{
	return _slice->empty();
}

- (BOOL)startsWith:(RocksDBSlice *)prefix
{
	return _slice->starts_with(*prefix.slice);
}

- (int)compare:(RocksDBSlice *)other
{
	return _slice->compare(*other.slice);
}

- (NSString *)toString:(BOOL)hex
{
	return [NSString stringWithCString:_slice->ToString(hex).c_str() encoding:NSNonLossyASCIIStringEncoding];
}

- (size_t)size
{
	return _slice->size();
}

- (NSData *)toData
{
	return DataFromSlice(*_slice);
}

- (void)dealloc
{
	delete _slice;
	_slice = nullptr;
}

@end
