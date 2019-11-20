//
//  RocksDBWriteBatchIterator.m
//  ObjectiveRocks
//

#import "RocksDBWriteBatchIterator.h"
#import "RocksDBSlice.h"
#import "RocksDBSlice+Private.h"
#import "RocksDBError.h"

#import <rocksdb/utilities/write_batch_with_index.h>

@interface RocksDBWriteBatchEntry ()
@property (nonatomic, assign) RocksDBWriteBatchEntryType type;
@property (nonatomic, strong) RocksDBSlice *key;
@property (nonatomic, strong) RocksDBSlice *value;
@end

@implementation RocksDBWriteBatchEntry
@synthesize key, value, type;

- (instancetype) initWithType:(RocksDBWriteBatchEntryType)type
						  key:(RocksDBSlice *)key
					    value:(RocksDBSlice *)value
{
	self = [super init];
	if (self) {
		self.type = type;
		self.key = key;
		self.value = value;
	}
	return self;
}
@end

@interface RocksDBWriteBatchIterator ()
{
	rocksdb::WBWIIterator *_iterator;
}
@property (nonatomic, readonly) rocksdb::WBWIIterator *iterator;
@end

@implementation RocksDBWriteBatchIterator

@synthesize iterator = _iterator;

#pragma mark - Lifecycle

- (instancetype)initWithWriteBatchIterator:(rocksdb::WBWIIterator *)iterator
{
	self = [super init];
	if (self) {
		_iterator = iterator;
	}
	return self;
}

- (void)dealloc
{
	[self close];
}

- (void)close
{
	@synchronized(self) {
		if (_iterator != nullptr) {
			delete _iterator;
			_iterator = nullptr;
		}
	}
}

#pragma mark - Operations

- (BOOL)isValid
{
	return _iterator->Valid();
}

- (void)seekToFirst
{
	_iterator->SeekToFirst();
}

- (void)seekToLast
{
	_iterator->SeekToLast();
}

- (void)seekToKey:(NSData *)aKey
{
	if (aKey != nil) {
		_iterator->Seek(SliceFromData(aKey));
	}
}

- (void)seekForPrev:(NSData *)aKey
{
	if (aKey != nil) {
		_iterator->SeekForPrev(SliceFromData(aKey));
	}
}

- (void)next
{
	_iterator->Next();
}

- (void)previous
{
	_iterator->Prev();
}

- (RocksDBWriteBatchEntry *)entry
{
	rocksdb::WriteEntry entry = _iterator->Entry();
	RocksDBWriteBatchEntryType type;
	switch (entry.type) {
		case rocksdb::kPutRecord:
			type = RocksDBWriteBatchEntryTypePutRecord;
			break;
		case rocksdb::kMergeRecord:
			type = RocksDBWriteBatchEntryTypeMergeRecord;
			break;
		case rocksdb::kDeleteRecord:
			type = RocksDBWriteBatchEntryTypeDeleteRecord;
			break;
		case rocksdb::kSingleDeleteRecord:
			type = RocksDBWriteBatchEntryTypeSingleDeleteRecord;
			break;
		case rocksdb::kDeleteRangeRecord:
			type = RocksDBWriteBatchEntryTypeDeleteRangeRecord;
			break;
		case rocksdb::kLogDataRecord:
			type = RocksDBWriteBatchEntryTypeLogDataRecord;
			break;
		case rocksdb::kXIDRecord:
			type = RocksDBWriteBatchEntryTypeXIDRecord;
			break;
	}

	return [[RocksDBWriteBatchEntry alloc]
			initWithType:type
			key:[[RocksDBSlice alloc] initWithSlice:&entry.key]
			value:[[RocksDBSlice alloc] initWithSlice:&entry.value]
	];
}

- (BOOL)status:(NSError * __autoreleasing *)error
{
    rocksdb::Status status = _iterator->status();

    if (!status.ok()) {
        NSError *temp = [RocksDBError errorWithRocksStatus:status];
        if (error && *error == nil) {
            *error = temp;
        }
		return NO;
    }
	return YES;
}

#pragma mark - Enumeration

- (void)enumerateEntriesUsingBlock:(void (^)(RocksDBWriteBatchEntry *entry, BOOL *stop))block
{
	BOOL stop = NO;

	for (_iterator->SeekToFirst(); _iterator->Valid(); _iterator->Next()) {
		if (block) block(self.entry, &stop);
		if (stop == YES) break;
	}
}

- (void)reverseEnumerateEntriesUsingBlock:(void (^)(RocksDBWriteBatchEntry *entry, BOOL *stop))block
{
	BOOL stop = NO;

	for (_iterator->SeekToLast(); _iterator->Valid(); _iterator->Prev()) {
		if (block) block(self.entry, &stop);
		if (stop == YES) break;
	}
}

@end
