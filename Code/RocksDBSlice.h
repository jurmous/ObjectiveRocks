//
//  RocksDBSlice.h
//  ObjectiveRocks
//

#import <Foundation/Foundation.h>

@interface RocksDBSlice : NSObject

/**
 Initialize Slice with NSString
 */
- (instancetype)initWithString:(NSString *)string;

/**
 Initialize Slice with bytes
 */
- (instancetype)initWithBytes:(char*)bytes;

/**
 Initialize Slice with bytes and length
 */
- (instancetype)initWithBytes:(char*)bytes length:(size_t)length;

/**
 Initialize Slice with bytes, offset and length
 */
- (instancetype)initWithBytes:(char *)bytes offset:(size_t)offset length:(size_t)length;

/**
 Get byte at index
 */
- (char)get:(int)index;

/**
 Drops the specified `n` number of bytes from the start of the backing slice
 @param n The number of bytes to drop
 */
- (void)removePrefix:(size_t)n;

/**
 Clears the backing slice
 */
- (void)clear;

/**
 Returns data backing of slice
 */
- (const char*)data;

/**
 Return true if the length of the data is zero.
*/
- (BOOL)empty;

/**
 Determines whether this slice starts with another slice

 @param prefix Another slice which may of may not
 be a prefix of this slice.

 @return true when this slice starts with the
 `prefix` slice
 */
- (BOOL)startsWith:(RocksDBSlice *)prefix;

/**
 Three-way key comparison
 @param other A slice to compare against

 @return Should return either:
 1) < 0 if this < other
 2) == 0 if this == other
 3) > 0 if this > other
 */
- (int)compare:(RocksDBSlice *)other;

/**
 Creates a string representation of the data

 @param hex When true, the representation will be encoded in hexadecimal.
 */
- (NSString *)toString:(BOOL)hex;

/**
 Return the length (in bytes) of the data.
 */
- (size_t)size;

@end
