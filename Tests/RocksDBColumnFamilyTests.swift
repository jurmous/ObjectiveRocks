//
//  RocksDBColumnFamilyTests.swift
//  ObjectiveRocks
//
//  Created by Iska on 17/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

import XCTest
import ObjectiveRocks

class RocksDBColumnFamilyTests : RocksDBTests {

	func testSwift_ColumnFamilies_List() {
		let options = RocksDBOptions()
		options.createIfMissing = true

		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)

		rocks.close()

		let names = RocksDB.listColumnFamiliesInDatabase(atPath: self.path, andOptions: options, error: nil)

		XCTAssertTrue(names.count == 1);
		XCTAssertEqual(names[0], "default")
	}

	func testSwift_ColumnFamilies_Create() {
		let options = RocksDBOptions()
		options.createIfMissing = true
		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)

		let columnFamily = try! rocks.createColumnFamily(withName: "new_cf", andOptions: RocksDBColumnFamilyOptions())

		XCTAssertNotNil(columnFamily)
		columnFamily.close()
		rocks.close()

		let names = RocksDB.listColumnFamiliesInDatabase(atPath: self.path, andOptions: options, error: nil)

		XCTAssertTrue(names.count == 2);
		XCTAssertEqual(names[0], "default")
		XCTAssertEqual(names[1], "new_cf")
	}

	func testSwift_ColumnFamilies_Drop() {
		let options = RocksDBOptions()
		options.createIfMissing = true

		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)
		
		let columnFamily = try! rocks.createColumnFamily(withName: "new_cf", andOptions: RocksDBColumnFamilyOptions())
		XCTAssertNotNil(columnFamily)
		try! rocks.dropColumnFamily(columnFamily)
		columnFamily.close()
		rocks.close()

		let names = RocksDB.listColumnFamiliesInDatabase(atPath: self.path, andOptions: options, error: nil)

		XCTAssertTrue(names.count == 1);
		XCTAssertEqual(names[0], "default")
	}

	func testSwift_ColumnFamilies_Open() {
		let options = RocksDBOptions()
		options.createIfMissing = true
		options.comparator = RocksDBComparator(type: .stringCompareAscending)
		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)

		let columnFamilyOptions = RocksDBColumnFamilyOptions()
		columnFamilyOptions.comparator = RocksDBComparator(type: .bytewiseDescending)

		let columnFamily = try! rocks.createColumnFamily(withName: "new_cf", andOptions: columnFamilyOptions)
		XCTAssertNotNil(columnFamily)
		columnFamily.close()
		rocks.close()

		let names = RocksDB.listColumnFamiliesInDatabase(atPath: self.path, andOptions: options, error: nil)

		XCTAssertTrue(names.count == 2)
		XCTAssertEqual(names[0], "default")
		XCTAssertEqual(names[1], "new_cf")

		let cfOption1 = RocksDBColumnFamilyOptions()
		cfOption1.comparator = RocksDBComparator(type: .stringCompareAscending)

		let cfOption2 = RocksDBColumnFamilyOptions()
		cfOption2.comparator = RocksDBComparator(type: .bytewiseDescending)

		let descriptor = RocksDBColumnFamilyDescriptor()
		descriptor.addDefaultColumnFamily(with: cfOption1)
		descriptor.addColumnFamily(withName: "new_cf", andOptions: cfOption2)

		let options2 = RocksDBOptions()
		options2.createIfMissing = true

		rocks = try! RocksDB.database(atPath: self.path, columnFamilies: descriptor, andOptions: options2)

		XCTAssertNotNil(rocks);

		XCTAssertTrue(rocks.columnFamilies().count == 2)

		let defaultColumnFamily = rocks.columnFamilies()[0]
		let newColumnFamily = rocks.columnFamilies()[1]

		XCTAssertNotNil(defaultColumnFamily)
		XCTAssertNotNil(newColumnFamily)
	}

	func testSwift_ColumnFamilies_Open_Bytes_And_Chinese_Families() {
		let options = RocksDBOptions()
		options.createIfMissing = true
		options.comparator = RocksDBComparator(type: .stringCompareAscending)
		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)

		let columnFamilyOptions = RocksDBColumnFamilyOptions()
		columnFamilyOptions.comparator = RocksDBComparator(type: .bytewiseDescending)

		let cfName1 = String(data: Data(bytes: [0, 0]), encoding: String.Encoding.nonLossyASCII)!
		let cfName2 = "简体字"

		let columnFamily1 = try! rocks.createColumnFamily(withName: cfName1, andOptions: columnFamilyOptions)
		XCTAssertNotNil(columnFamily1)
		columnFamily1.close()

		let columnFamily2 = try! rocks.createColumnFamily(withName: cfName2, andOptions: columnFamilyOptions)
		XCTAssertNotNil(columnFamily2)
		columnFamily2.close()
		rocks.close()

		let names = RocksDB.listColumnFamiliesInDatabase(atPath: self.path, andOptions: options, error: nil)

		XCTAssertTrue(names.count == 3)
		XCTAssertEqual(names[0], "default")
		XCTAssertEqual(names[1], cfName1.data)
		XCTAssertEqual(names[2], cfName2.data)

		let cfOption1 = RocksDBColumnFamilyOptions()
		cfOption1.comparator = RocksDBComparator(type: .stringCompareAscending)

		let cfOption2 = RocksDBColumnFamilyOptions()
		cfOption2.comparator = RocksDBComparator(type: .bytewiseDescending)

		let descriptor = RocksDBColumnFamilyDescriptor()
		descriptor.addDefaultColumnFamily(with: cfOption1)
		descriptor.addColumnFamily(withName: cfName1, andOptions: cfOption2)
		descriptor.addColumnFamily(withName: cfName2, andOptions: cfOption2)

		let options2 = RocksDBOptions()
		options2.createIfMissing = true

		rocks = try! RocksDB.database(atPath: self.path, columnFamilies: descriptor, andOptions: options2)

		XCTAssertNotNil(rocks);

		XCTAssertTrue(rocks.columnFamilies().count == 3)

		let defaultColumnFamily = rocks.columnFamilies()[0]
		let newColumnFamily1 = rocks.columnFamilies()[1]
		let newColumnFamily2 = rocks.columnFamilies()[2]

		XCTAssertNotNil(defaultColumnFamily)
		XCTAssertNotNil(newColumnFamily1)
		XCTAssertNotNil(newColumnFamily2)
	}

	func testSwift_ColumnFamilies_Open_ComparatorMismatch() {
		let options = RocksDBOptions()
		options.createIfMissing = true
		options.comparator = RocksDBComparator(type: .stringCompareAscending)

		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)

		let columnFamilyOptions = RocksDBColumnFamilyOptions()
		columnFamilyOptions.comparator = RocksDBComparator(type: .bytewiseDescending)

		let columnFamily = try! rocks.createColumnFamily(withName: "new_cf", andOptions: columnFamilyOptions)


		XCTAssertNotNil(columnFamily)
		columnFamily.close()
		rocks.close()

		let names = RocksDB.listColumnFamiliesInDatabase(atPath: self.path, andOptions: options, error: nil)

		XCTAssertTrue(names.count == 2)
		XCTAssertEqual(names[0], "default")
		XCTAssertEqual(names[1], "new_cf")

		let cfOptions1 = RocksDBColumnFamilyOptions()
		cfOptions1.comparator = RocksDBComparator(type: .stringCompareAscending)
		let cfOptions2 = RocksDBColumnFamilyOptions()
		cfOptions2.comparator = RocksDBComparator(type: .stringCompareAscending)

		let descriptor = RocksDBColumnFamilyDescriptor()
		descriptor.addDefaultColumnFamily(with: cfOptions1)
		descriptor.addColumnFamily(withName: "new_cf", andOptions: cfOptions2)

		let options2 = RocksDBOptions()
		options2.createIfMissing = true

		rocks = try? RocksDB.database(atPath: self.path, columnFamilies: descriptor, andOptions: options2)

		XCTAssertNil(rocks)
	}

	func testSwift_ColumnFamilies_CRUD() {
		let options = RocksDBOptions()
		options.createIfMissing = true

		rocks = try! RocksDB.database(atPath: self.path, andOptions: options)

		try! rocks.setData("df_value", forKey: "df_key1")
		try! rocks.setData("df_value", forKey: "df_key2")

		let columnFamily = try! rocks.createColumnFamily(withName: "new_cf", andOptions: RocksDBColumnFamilyOptions())
		XCTAssertNotNil(columnFamily)
		try! rocks.setData("cf_value", forKey: "cf_key1", forColumnFamily: columnFamily)
		try! rocks.setData("cf_value", forKey: "cf_key2", forColumnFamily: columnFamily)

		columnFamily.close()
		rocks.close()

		let descriptor = RocksDBColumnFamilyDescriptor()

		descriptor.addDefaultColumnFamily(with: RocksDBColumnFamilyOptions())
		descriptor.addColumnFamily(withName: "new_cf", andOptions: RocksDBColumnFamilyOptions())

		let options2 = RocksDBOptions()
		options2.createIfMissing = true
		options2.createMissingColumnFamilies = true

		rocks = try! RocksDB.database(atPath: self.path, columnFamilies: descriptor, andOptions: options2)

		let defaultColumnFamily = rocks.columnFamilies()[0]
		let newColumnFamily = rocks.columnFamilies()[1]

		XCTAssertEqual(try! rocks.data(forKey: "df_key1"), "df_value".data)
		XCTAssertEqual(try! rocks.data(forKey: "df_key2"), "df_value".data)
		XCTAssertNil(try? rocks.data(forKey: "cf_key1"))
		XCTAssertNil(try? rocks.data(forKey: "cf_key2"))

		XCTAssertEqual(try! rocks.data(forKey: "df_key1", inColumnFamily: defaultColumnFamily), "df_value".data)
		XCTAssertEqual(try! rocks.data(forKey: "df_key2", inColumnFamily: defaultColumnFamily), "df_value".data)

		XCTAssertNil(try? rocks.data(forKey: "cf_key1", inColumnFamily: defaultColumnFamily))
		XCTAssertNil(try? rocks.data(forKey: "cf_key2", inColumnFamily: defaultColumnFamily))

		XCTAssertEqual(try! rocks.data(forKey: "cf_key1", inColumnFamily: newColumnFamily), "cf_value".data)
		XCTAssertEqual(try! rocks.data(forKey: "cf_key2", inColumnFamily: newColumnFamily), "cf_value".data)

		XCTAssertNil(try? rocks.data(forKey: "df_key1", inColumnFamily: newColumnFamily))
		XCTAssertNil(try? rocks.data(forKey: "df_key2", inColumnFamily: newColumnFamily))

		try! rocks.deleteData(forKey: "cf_key1", forColumnFamily: newColumnFamily)
		XCTAssertNil(try? rocks.data(forKey: "cf_key1", inColumnFamily: newColumnFamily))

		try! rocks.deleteData(forKey: "cf_key1", forColumnFamily: newColumnFamily)
		XCTAssertNil(try? rocks.data(forKey: "cf_key1", inColumnFamily: newColumnFamily))
	}

	func testSwift_ColumnFamilies_WriteBatch() {
		let descriptor = RocksDBColumnFamilyDescriptor()

		descriptor.addDefaultColumnFamily(with: RocksDBColumnFamilyOptions())
		descriptor.addColumnFamily(withName: "new_cf", andOptions: RocksDBColumnFamilyOptions())

		let options = RocksDBOptions()
		options.createIfMissing = true
		options.createMissingColumnFamilies = true

		rocks = try! RocksDB.database(atPath: self.path, columnFamilies: descriptor, andOptions: options)

		let defaultColumnFamily = rocks.columnFamilies()[0]
		let newColumnFamily = rocks.columnFamilies()[1]

		try! rocks.setData("xyz_value", forKey: "xyz", forColumnFamily: newColumnFamily)

		let batch = RocksDBWriteBatch()
		try! batch.setData("cf_value1", forKey:"cf_key1", inColumnFamily:newColumnFamily)
		try! batch.setData("df_value", forKey:"df_key")
		try! batch.setData("cf_value2", forKey:"cf_key2", inColumnFamily:newColumnFamily)
		try! batch.deleteData(forKey: "xyz")
		try! batch.deleteData(forKey: "xyz", inColumnFamily:newColumnFamily)

		try! rocks.applyWriteBatch(batch, writeOptions:RocksDBWriteOptions())

		XCTAssertEqual(try! rocks.data(forKey: "df_key", inColumnFamily: defaultColumnFamily), "df_value".data)
		XCTAssertNil(try? rocks.data(forKey: "df_key1", inColumnFamily: defaultColumnFamily))
		XCTAssertNil(try? rocks.data(forKey: "df_key2", inColumnFamily: defaultColumnFamily))

		XCTAssertEqual(try! rocks.data(forKey: "cf_key1", inColumnFamily: newColumnFamily), "cf_value1".data)
		XCTAssertEqual(try! rocks.data(forKey: "cf_key2", inColumnFamily: newColumnFamily), "cf_value2".data)
		XCTAssertNil(try? rocks.data(forKey: "df_key", inColumnFamily: newColumnFamily))

		XCTAssertNil(try? rocks.data(forKey: "xyz", inColumnFamily: defaultColumnFamily))
		XCTAssertNil(try? rocks.data(forKey: "xyz", inColumnFamily: newColumnFamily))

		defaultColumnFamily.close()
		newColumnFamily.close()
	}

	func testSwift_ColumnFamilies_Iterator() {
		let descriptor = RocksDBColumnFamilyDescriptor()

		descriptor.addDefaultColumnFamily(with: RocksDBColumnFamilyOptions())
		descriptor.addColumnFamily(withName: "new_cf", andOptions: RocksDBColumnFamilyOptions())

		let options = RocksDBOptions()
		options.createIfMissing = true
		options.createMissingColumnFamilies = true

		rocks = try! RocksDB.database(atPath: self.path, columnFamilies: descriptor, andOptions: options)

		let defaultColumnFamily = rocks.columnFamilies()[0]
		let newColumnFamily = rocks.columnFamilies()[1]

		try! rocks.setData("df_value1", forKey: "df_key1", forColumnFamily: defaultColumnFamily)
		try! rocks.setData("df_value2", forKey: "df_key2", forColumnFamily: defaultColumnFamily)

		try! rocks.setData("cf_value1", forKey: "cf_key1", forColumnFamily: newColumnFamily)
		try! rocks.setData("cf_value2", forKey: "cf_key2", forColumnFamily: newColumnFamily)

		let dfIterator = rocks.iteratorOverColumnFamily(defaultColumnFamily)

		var actual = [String]()

		dfIterator.seekToFirst()
		while dfIterator.isValid() {
			actual.append(String(data: dfIterator.key(), encoding: .utf8)!)
			actual.append(String(data: dfIterator.value(), encoding: .utf8)!)
			dfIterator.next()
		}

		var expected = [ "df_key1", "df_value1", "df_key2", "df_value2" ]
		XCTAssertEqual(actual, expected);

		dfIterator.close()

		let cfIterator = rocks.iteratorOverColumnFamily(newColumnFamily)

		actual.removeAll()

		cfIterator.seekToFirst()
		while cfIterator.isValid() {
			actual.append(String(data: cfIterator.key(), encoding: .utf8)!)
			actual.append(String(data: cfIterator.value(), encoding: .utf8)!)
			cfIterator.next()
		}

		expected = [ "cf_key1", "cf_value1", "cf_key2", "cf_value2" ]
		XCTAssertEqual(actual, expected)

		cfIterator.close()
	}
}
