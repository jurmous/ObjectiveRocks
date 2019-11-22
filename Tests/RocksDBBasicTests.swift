//
//  RocksDBBasicTests.swift
//  ObjectiveRocks
//
//  Created by Iska on 11/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

import XCTest
import ObjectiveRocks

class RocksDBBasicTests : RocksDBTests {

	func testSwift_DB_Open_ErrorIfExists() {
		let options = RocksDBOptions();
		options.createIfMissing = true
		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)
		rocks.close()

		let options2 = RocksDBOptions();
		options2.errorIfExists = true
		let db = try? RocksDB.database(atPath: self.path, andOptions: options2)

		XCTAssertNil(db)
	}
    
    func testSwift_DB_IsClosed() {
		let options = RocksDBOptions();
		options.createIfMissing = true
        rocks = try! RocksDB.database(atPath: self.path, andOptions: options)
        XCTAssertFalse(rocks.isClosed())
        rocks.close()
        XCTAssertTrue(rocks.isClosed())
    }

	func testSwift_DB_CRUD() {
		let options = RocksDBOptions();
		options.createIfMissing = true
		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)

		let readOptions = RocksDBReadOptions()
		readOptions.fillCache = true
		readOptions.verifyChecksums = true

		let writeOptions = RocksDBWriteOptions()
		writeOptions.syncWrites = true

		rocks.setDefault(
			readOptions: readOptions,
			writeOptions: writeOptions
		)

		try! rocks.setData("value 1", forKey: "key 1")
		try! rocks.setData("value 2", forKey: "key 2")
		try! rocks.setData("value 3", forKey: "key 3")

		XCTAssertEqual(try! rocks.data(forKey: "key 1"), "value 1".data);
		XCTAssertEqual(try! rocks.data(forKey: "key 2"), "value 2".data);
		XCTAssertEqual(try! rocks.data(forKey: "key 3"), "value 3".data);

		try! rocks.deleteData(forKey: "key 2")
		XCTAssertNil(try? rocks.data(forKey: "key 2"));

		try! self.rocks.deleteData(forKey: "key 2")
	}
}
