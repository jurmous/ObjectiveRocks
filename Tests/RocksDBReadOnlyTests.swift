//
//  RocksDBReadOnlyTests.swift
//  ObjectiveRocks
//
//  Created by Iska on 10/08/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

import XCTest
import ObjectiveRocks

class RocksDBReadOnlyTests : RocksDBTests {

	func testDB_Open_ReadOnly_NilIfMissing() {
		let options = RocksDBOptions();
		rocks = RocksDB.databaseForReadOnly(atPath: path, andOptions:options)
		XCTAssertNil(rocks);
	}

	func testDB_Open_ReadOnly() {
		let options = RocksDBOptions();
		options.createIfMissing = true

		rocks = RocksDB.database(atPath: path, andOptions: options);
		XCTAssertNotNil(rocks);
		rocks.close()

		rocks = RocksDB.databaseForReadOnly(atPath: path, andOptions: options)
		XCTAssertNotNil(rocks);
	}

	func testDB_ReadOnly_NotWritable() {
		let options = RocksDBOptions();
		options.createIfMissing = true
		rocks = RocksDB.database(atPath: path, andOptions: options);
		XCTAssertNotNil(rocks);
		try! rocks.setData("data", forKey: "key")
		rocks.close()

		rocks = RocksDB.databaseForReadOnly(atPath: path, andOptions:RocksDBOptions())

		try! rocks.data(forKey: "key")

		AssertThrows {
			try self.rocks.setData("data", forKey:"key")
		}

		AssertThrows {
			try self.rocks.deleteData(forKey: "key")
		}

		AssertThrows {
			try self.rocks.merge("data", forKey:"key")
		}
	}

}
