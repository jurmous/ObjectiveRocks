//
//  RocksDBWriteBatchTests.swift
//  ObjectiveRocks
//
//  Created by Iska on 11/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

import XCTest
import ObjectiveRocks

class RocksDBWriteBatchTests : RocksDBTests {

	func testSwift_WriteBatch_Perform() {
		let options = RocksDBOptions()
		options.createIfMissing = true

		rocks = RocksDB.database(atPath: self.path, andOptions: options)

		try!  rocks.performWriteBatch { (batch, options) -> Void in
			batch.setData("value 1", forKey: "key 1")
			batch.setData("value 2", forKey: "key 2")
			batch.setData("value 3", forKey: "key 3")
		}

		XCTAssertEqual(try! rocks.data(forKey: "key 1"), "value 1".data);
		XCTAssertEqual(try! rocks.data(forKey: "key 2"), "value 2".data);
		XCTAssertEqual(try! rocks.data(forKey: "key 3"), "value 3".data);
		XCTAssertNil(try? rocks.data(forKey: "Key 4"))
	}

	func testSwift_WriteBatch_Perform_DeleteOps() {
		let options = RocksDBOptions()
		options.createIfMissing = true

		rocks = RocksDB.database(atPath: self.path, andOptions: options)

		try! rocks.setData("value 1", forKey: "key 1")

		try! rocks.performWriteBatch ({ (batch, options) -> Void in
			batch.deleteData(forKey: "key 1")
			batch.setData("value 2", forKey: "key 2")
			batch.setData("value 3", forKey: "key 3")
		})

		XCTAssertNil(try? rocks.data(forKey: "Key 1"))
		XCTAssertEqual(try! rocks.data(forKey: "key 2"), "value 2");
		XCTAssertEqual(try! rocks.data(forKey: "key 3"), "value 3");
		XCTAssertNil(try? rocks.data(forKey: "Key 4"))
	}

	func testSwift_WriteBatch_Perform_ClearOps() {
		let options = RocksDBOptions()
		options.createIfMissing = true

		rocks = RocksDB.database(atPath: self.path, andOptions: options)

		try! rocks.setData("value 1", forKey: "key 1")

		try! rocks.performWriteBatch ({ (batch, options) -> Void in
			batch.deleteData(forKey: "key 1")
			batch.setData("value 2", forKey: "key 2")
			batch.setData("value 3", forKey: "key 3")
			batch.clear()
			batch.setData("value 4", forKey: "key 4")
		})

		XCTAssertEqual(try! rocks.data(forKey: "key 1"), "value 1".data);
		XCTAssertNil(try? rocks.data(forKey: "Key 2"))
		XCTAssertNil(try? rocks.data(forKey: "Key 3"))
		XCTAssertEqual(try! rocks.data(forKey: "key 4"), "value 4".data);
	}

	func testSwift_WriteBatch_Apply() {
		let options = RocksDBOptions()
		options.createIfMissing = true

		rocks = RocksDB.database(atPath: self.path, andOptions: options)

		let batch = rocks.writeBatch()

		batch.setData("value 1", forKey: "key 1")
		batch.setData("value 2", forKey: "key 2")
		batch.setData("value 3", forKey: "key 3")

		let writeOptions = RocksDBWriteOptions()

		try! rocks.applyWriteBatch(batch, writeOptions: writeOptions)

		XCTAssertEqual(try! rocks.data(forKey: "key 1"), "value 1".data);
		XCTAssertEqual(try! rocks.data(forKey: "key 2"), "value 2".data);
		XCTAssertEqual(try! rocks.data(forKey: "key 3"), "value 3".data);
		XCTAssertNil(try? rocks.data(forKey: "Key 4"))
	}

	func testSwift_WriteBatch_Apply_DeleteOps() {
		let options = RocksDBOptions()
		options.createIfMissing = true

		rocks = RocksDB.database(atPath: self.path, andOptions: options)

		try! rocks.setData("value 1", forKey: "key 1")

		let batch = rocks.writeBatch()

		batch.deleteData(forKey: "key 1")
		batch.setData("value 2", forKey: "key 2")
		batch.setData("value 3", forKey: "key 3")

		let writeOptions = RocksDBWriteOptions()
		try! rocks.applyWriteBatch(batch, writeOptions: writeOptions)

		XCTAssertNil(try? rocks.data(forKey: "Key 1"))
		XCTAssertEqual(try! rocks.data(forKey: "key 2"), "value 2".data);
		XCTAssertEqual(try! rocks.data(forKey: "key 3"), "value 3".data);
		XCTAssertNil(try? rocks.data(forKey: "Key 4"))
	}

	func testSwift_WriteBatch_Apply_MergeOps() {
		let options = RocksDBOptions()
		options.createIfMissing = true
		options.mergeOperator = RocksDBMergeOperator(name: "merge") { (key, existing, value) -> Data in
			var result: String = ""
			if let existing = existing, let existingString = String(data: existing, encoding: .utf8) {
				result = existingString
			}
			result.append(",")
			if let value = String(data: value, encoding: .utf8) {
				result.append(value)
			}
			return result.data(using: .utf8)!
		}

		rocks = RocksDB.database(atPath: self.path, andOptions: options)

		try! rocks.setData("value 1", forKey: "key 1")

		let batch = rocks.writeBatch()

		batch.deleteData(forKey: "key 1")
		batch.setData("value 2", forKey: "key 2")
		batch.setData("value 3", forKey: "key 3")
		batch.mergeData("value 2 new", forKey: "key 2")

		let writeOptions = RocksDBWriteOptions()
		try!  rocks.applyWriteBatch(batch, writeOptions: writeOptions)

		XCTAssertEqual(try! rocks.data(forKey: "key 2"), "value 2,value 2 new");
	}

	func testSwift_WriteBatch_Apply_ClearOps() {
		let options = RocksDBOptions()
		options.createIfMissing = true
		rocks = RocksDB.database(atPath: self.path, andOptions: options)

		try! rocks.setData("value 1", forKey: "key 1")

		let batch = rocks.writeBatch()

		batch.deleteData(forKey: "key 1")
		batch.setData("value 2", forKey: "key 2")
		batch.setData("value 3", forKey: "key 3")
		batch.clear()
		batch.setData("value 4", forKey: "key 4")

		let writeOptions = RocksDBWriteOptions()
		try! rocks.applyWriteBatch(batch, writeOptions: writeOptions)

		XCTAssertEqual(try! rocks.data(forKey: "key 1"), "value 1");
		XCTAssertNil(try? rocks.data(forKey: "Key 2"))
		XCTAssertNil(try? rocks.data(forKey: "Key 3"))
		XCTAssertEqual(try! rocks.data(forKey: "key 4"), "value 4");
	}

	func testSwift_WriteBatch_Count() {
		let options = RocksDBOptions();
		options.createIfMissing = true;

		rocks = RocksDB.database(atPath: self.path, andOptions: options)

		try! rocks.setData("value 1", forKey: "key 1")

		let batch = rocks.writeBatch()

		batch.deleteData(forKey: "key 1")

		XCTAssertEqual(batch.count(), 1 as Int32);

		batch.setData("value 2", forKey: "key 2")
		batch.setData("value 3", forKey: "key 3")

		XCTAssertEqual(batch.count(), 3 as Int32);

		batch.clear()

		XCTAssertEqual(batch.count(), 0 as Int32);

		batch.setData("value 4", forKey: "key 3")
		batch.setData("value 5", forKey: "key 4")

		XCTAssertEqual(batch.count(), 2 as Int32);

		batch.deleteData(forKey: "key 4")

		XCTAssertEqual(batch.count(), 3 as Int32);
	}
}
