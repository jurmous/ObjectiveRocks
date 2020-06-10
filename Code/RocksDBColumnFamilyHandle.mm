//
//  RocksDBColumnFamilyHandle.m
//  ObjectiveRocks
//
//  Created by Jurriaan Mous on 20/10/2019.
//

#import <rocksdb/db.h>
#import "RocksDBColumnFamilyHandle.h"
#import "RocksDBError.h"

@interface RocksDBColumnFamilyHandle ()
{
	rocksdb::ColumnFamilyHandle *_columnFamily;
}
@property (nonatomic, assign) rocksdb::ColumnFamilyHandle *columnFamily;
@end

@implementation RocksDBColumnFamilyHandle

- (instancetype)initWithColumnFamily:(rocksdb::ColumnFamilyHandle *)columnFamily
{
	if (self) {
		self->_columnFamily = columnFamily;
	}
	return self;
}

- (uint32_t)id
{
	return _columnFamily->GetID();
}

- (NSData *)name
{
	std::string name =  _columnFamily->GetName();
	return [[NSData alloc] initWithBytes:name.data() length:name.length()];
}

- (void)close
{
	@synchronized(self) {
		if (self.columnFamily != nullptr) {
			delete self.columnFamily;
			self.columnFamily = nullptr;
		}
	}
}


@end
