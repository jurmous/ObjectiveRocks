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
		descriptor.addDefaultColumnFamily(options: nil)
		descriptor.addColumnFamily(withName: "new_cf", andOptions: nil)

		let options = RocksDBOptions()
		options.createIfMissing = true
		options.createMissingColumnFamilies = true

		rocks = RocksDB.database(atPath: path, columnFamilies: descriptor, andOptions: options)

		XCTAssertGreaterThanOrEqual((rocks.columnFamilies()[0]).value(forIntProperty: "rocksdb.estimate-num-keys"), 0 as UInt64);
		XCTAssertNotNil((rocks.columnFamilies()[0]).value(forProperty: "rocksdb.stats"));
		XCTAssertNotNil((rocks.columnFamilies()[0]).value(forProperty: "rocksdb.sstables"));

		XCTAssertGreaterThanOrEqual((rocks.columnFamilies()[1]).value(forIntProperty: "rocksdb.estimate-num-keys"), 0 as UInt64);
		XCTAssertNotNil((rocks.columnFamilies()[1]).value(forProperty: "rocksdb.stats"));
		XCTAssertNotNil((rocks.columnFamilies()[1]).value(forProperty: "rocksdb.sstables"));
	}
}
