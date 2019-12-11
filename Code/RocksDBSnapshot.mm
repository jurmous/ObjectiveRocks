//
//  RocksDBSnapshot.m
//  ObjectiveRocks
//
//  Created by Iska on 06/12/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDBSnapshot.h"
#import "RocksDB+Private.h"

#import <rocksdb/db.h>

@interface RocksDBSnapshot ()
{
	rocksdb::Snapshot *_snapshot;
	rocksdb::DB *_db;
}
@property (nonatomic, assign) const rocksdb::Snapshot *snapshot;
@property (nonatomic, assign) rocksdb::DB *db;
@end

@implementation RocksDBSnapshot
@synthesize snapshot = _snapshot;
@synthesize db = _db;

#pragma mark - Lifecycle

- (instancetype)initWithSnapshot:(const rocksdb::Snapshot *)snapshot
							  db:(rocksdb::DB *)db
{
	self = [super init];
	if (self) {
		self.db = db;
		self.snapshot = snapshot;
	}
	return self;
}

- (void)close
{
	@synchronized(self) {
		self.db->ReleaseSnapshot(self.snapshot);
	}
}

#pragma mark - 

- (uint64_t)sequenceNumber
{
	return self.snapshot->GetSequenceNumber();
}

@end
