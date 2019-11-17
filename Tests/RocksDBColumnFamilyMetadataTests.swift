//
//  RocksDBColumnFamilyMetadataTests.swift
//  ObjectiveRocks
//
//  Created by Iska on 17/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

import XCTest
import ObjectiveRocks

class RocksDBColumnFamilyMetadataTests : RocksDBTests {

	func testSwift_ColumnFamilies_Metadata() {
		let descriptor = RocksDBColumnFamilyDescriptor()
		descriptor.addDefaultColumnFamily(with: RocksDBColumnFamilyOptions())
		descriptor.addColumnFamily(withName: "new_cf", andOptions: RocksDBColumnFamilyOptions())

		let options = RocksDBOptions()
		options.createIfMissing = true
		options.createMissingColumnFamilies = true

		rocks = RocksDB.database(atPath: self.path, columnFamilies: descriptor, andOptions: options)

		let defaultColumnFamily = rocks.columnFamilies()[0]
		let newColumnFamily = rocks.columnFamilies()[1]

		try! rocks.setData("df_value1", forKey: "df_key1", forColumnFamily: defaultColumnFamily)
		try! rocks.setData("df_value2", forKey: "df_key2", forColumnFamily: defaultColumnFamily)

		try! rocks.setData("cf_value1", forKey: "cf_key1", forColumnFamily: newColumnFamily)
		try! rocks.setData("cf_value2", forKey: "cf_key2", forColumnFamily: newColumnFamily)

		let defaultMetadata = rocks.columnFamilyMetaData(defaultColumnFamily)
		XCTAssertNotNil(defaultMetadata);

		let newColumnFamilyMetadata = rocks.columnFamilyMetaData(newColumnFamily)
		XCTAssertNotNil(newColumnFamilyMetadata);
	}
}
