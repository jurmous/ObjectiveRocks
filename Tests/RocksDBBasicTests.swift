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

		let existResult = NSMutableData()

		XCTAssertTrue(rocks.keyMayExist("key 1", value: existResult))
		XCTAssertEqual(existResult as Data, "value 1".data)
	}

	func testSwift_keyMayExist() {
		let options = RocksDBOptions();
		options.createIfMissing = true
		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)

		let readOptions = RocksDBReadOptions()

		let writeOptions = RocksDBWriteOptions()

		rocks.setDefault(
			readOptions: readOptions,
			writeOptions: writeOptions
		)

		let nonUtf8 = Data.init(bytes: [80])

		try! rocks.setData(nonUtf8, forKey: "key 1")
		try! rocks.setData("value 2", forKey: "key 2")

		XCTAssertEqual(try! rocks.data(forKey: "key 1"), nonUtf8);
		XCTAssertEqual(try! rocks.data(forKey: "key 2"), "value 2".data);

		let existResult = NSMutableData()
		XCTAssertTrue(rocks.keyMayExist("key 1", value: existResult))
		XCTAssertEqual(existResult as Data, nonUtf8)

		XCTAssertTrue(rocks.keyMayExist("key 1", value: nil))

		let existResult2 = NSMutableData()
		XCTAssertTrue(rocks.keyMayExist("key 2", value: existResult2))
		XCTAssertEqual(existResult2 as Data, "value 2".data)
	}
}
