//
//  RocksDBCheckpointTests.swift
//  ObjectiveRocks
//
//  Created by Iska on 11/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

import XCTest
import ObjectiveRocks

class RocksDBCheckpointTests : RocksDBTests {

	func testSwift_Checkpoint() {
		let options = RocksDBOptions()
		options.createIfMissing = true

		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)

		try! rocks.setData("value 1", forKey: "key 1")

		let checkpoint = RocksDBCheckpoint(database: rocks, error:nil)

		try! checkpoint.createCheckpoint(atPath: checkpointPath1)

		try! rocks.setData("value 2", forKey: "key 2")

		try! checkpoint.createCheckpoint(atPath: checkpointPath2)

		rocks.close()

		rocks = try! RocksDB.database(atPath: self.checkpointPath1, andOptions: options)

		XCTAssertEqual(try! rocks.data(forKey: "key 1"), "value 1".data)
		XCTAssertNil(try? rocks.data(forKey: "key 2"))

		rocks.close()

		rocks = try! RocksDB.database(atPath: self.checkpointPath2, andOptions: options)

		XCTAssertEqual(try! rocks.data(forKey: "key 1"), "value 1".data)
		XCTAssertEqual(try! rocks.data(forKey: "key 2"), "value 2".data)
	}
}
