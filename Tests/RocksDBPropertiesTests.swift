//
//  RocksDBPropertiesTests.swift
//  ObjectiveRocks
//
//  Created by Iska on 11/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

import XCTest
import ObjectiveRocks

class RocksDBPropertiesTests : RocksDBTests {

	func testSwift_Properties() {
		let options = RocksDBOptions()
		options.createIfMissing = true
		options.maxWriteBufferNumber = 10;
		options.minWriteBufferNumberToMerge = 10;

		rocks = RocksDB.database(atPath: self.path, andOptions: options)

		try! rocks.setData("value 1".data, forKey: "key 1".data)
		try! rocks.setData("value 2".data, forKey: "key 2".data)
		try! rocks.setData("value 3".data, forKey: "key 3".data)

		XCTAssertGreaterThan(rocks.value(forIntProperty: "rocksdb.num-entries-active-mem-table"), 0 as UInt64);
	}

	func testSwift_Properties_ColumnFamily() {
		let descriptor = RocksDBColumnFamilyDescriptor()
		descriptor.addDefaultColumnFamily(with: RocksDBColumnFamilyOptions())
		descriptor.addColumnFamily(withName: "new_cf", andOptions: RocksDBColumnFamilyOptions())

		let options = RocksDBOptions()
		options.createIfMissing = true
		options.createMissingColumnFamilies = true

		rocks = RocksDB.database(atPath: path, columnFamilies: descriptor, andOptions: options)

		let columnFamilies = rocks.columnFamilies()

		XCTAssertGreaterThanOrEqual(rocks.value(forIntProperty: "rocksdb.estimate-num-keys", inColumnFamily: columnFamilies[0]), 0 as UInt64);
		XCTAssertNotNil(rocks.value(forProperty: "rocksdb.stats", inColumnFamily: columnFamilies[0]));
		XCTAssertNotNil(rocks.value(forProperty: "rocksdb.sstables", inColumnFamily: columnFamilies[0]));

		XCTAssertGreaterThanOrEqual(rocks.value(forIntProperty: "rocksdb.estimate-num-keys", inColumnFamily: columnFamilies[1]), 0 as UInt64);
		XCTAssertNotNil(rocks.value(forProperty: "rocksdb.stats", inColumnFamily: columnFamilies[1]));
		XCTAssertNotNil(rocks.value(forProperty: "rocksdb.sstables", inColumnFamily: columnFamilies[1]));
	}
}
