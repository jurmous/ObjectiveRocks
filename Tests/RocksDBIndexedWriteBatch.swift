//
//  RocksDBIndexedWriteBatch.swift
//  ObjectiveRocks
//

import XCTest
import ObjectiveRocks

class RocksDBIndexedWriteBatchTests : RocksDBTests {
	func testSwift_IndexedWriteBatch_Iterator() {
		let wbwi = RocksDBIndexedWriteBatch(true)
		let k1 = "key1"
		let v1 = "value1"
		let k2 = "key2"
		let v2 = "value2"
		let k3 = "key3"
		let v3 = "value3"
		let k4 = "key4"
		let k5 = "key5"
		let k6 = "key6"
		let k7 = "key7"
		let v8 = "value8"
		let k1b = k1.data
		let v1b = v1.data
		let k2b = k2.data
		let v2b = v2.data
		let k3b = k3.data
		let v3b = v3.data
		let k4b = k4.data
		let k5b = k5.data
		let k6b = k6.data
		let k7b = k7.data
		let v8b = v8.data

		try! wbwi.setData(v1b, forKey: k1b)
		try! wbwi.setData(v2b, forKey: k2b)
		try! wbwi.setData(v3b, forKey: k3b)

		// add a deletion record
		try! wbwi.deleteData(forKey: k4b)

		// add a single deletion record
		try! wbwi.singleDelete(k5b)

		// add a delete range record
		try! wbwi.delete(RocksDBKeyRange(start: k6b, end: k7b))

		// add a log record
		try! wbwi.putLogData(v8b)

		let expected = [
			RocksDBWriteBatchEntry(
				type: .putRecord,
				key: RocksDBSlice(string: k1), value: RocksDBSlice(string: v1)
			),
			RocksDBWriteBatchEntry(
				type: .putRecord,
				key: RocksDBSlice(string: k2), value: RocksDBSlice(string: v2)
			),
			RocksDBWriteBatchEntry(
				type: .putRecord,
				key: RocksDBSlice(string: k3), value: RocksDBSlice(string: v3)
			),
			RocksDBWriteBatchEntry(
				type: .deleteRecord,
				key: RocksDBSlice(string: k4), value: RocksDBSlice()
			),
			RocksDBWriteBatchEntry(
				type: .singleDeleteRecord,
				key: RocksDBSlice(string: k5), value: RocksDBSlice()
			),
			RocksDBWriteBatchEntry(
				type: .deleteRangeRecord,
				key: RocksDBSlice(string: k6), value: RocksDBSlice(string: k7)
			)
		]

		let it = wbwi.iterator()

		// direct access - seek to key offsets
		let testOffsets = [2, 0, 3, 4, 1, 5]

		for i in testOffsets {
			let testOffset = testOffsets[i]
			let keySlice = expected[testOffset].key
			let key = Data(bytes: keySlice.data(), count:keySlice.size());

			it.seek(toKey: key)

			XCTAssert(it.isValid())

			let entry = it.entry()
			XCTAssertEqual(expected[testOffset].type, entry.type)
			XCTAssert(expected[testOffset].key.compare(entry.key) == 0)
			XCTAssert(expected[testOffset].value.compare(entry.value) == 0)
		}

		// forward iterative access
		var i = 0
		it.seekToFirst()
		while (it.isValid()) {
			XCTAssertEqual(expected[i].type, it.entry().type)
			XCTAssert(expected[i].key.compare(it.entry().key) == 0)
			XCTAssert(expected[i].value.compare(it.entry().value) == 0)
			i += 1
			it.next()
		}

		// reverse iterative access
		i = expected.count - 1
		it.seekToLast()
		while (it.isValid()) {
			XCTAssertEqual(expected[i].type, it.entry().type)
			XCTAssert(expected[i].key.compare(it.entry().key) == 0)
			XCTAssert(expected[i].value.compare(it.entry().value) == 0)
			i -= 1
			it.previous()
		}
	}

	func testSwift_IndexedWriteBatch_restorePoints() {
		let wbwi = RocksDBIndexedWriteBatch()

		try! wbwi.setData("v1".data, forKey: "k1".data)
		try! wbwi.setData("v2".data, forKey: "k2".data)

		wbwi.setSavePoint()

		try! wbwi.setData("123456789".data, forKey: "k1".data)
		try! wbwi.deleteData(forKey: "k2".data)

		try! wbwi.rollbackToSavePoint()

		let options = RocksDBDatabaseOptions()

		XCTAssertEqual("v1".data, wbwi.getFromBatch(options, key: "k1".data, error: nil))
		XCTAssertEqual("v2".data, wbwi.getFromBatch(options, key: "k2".data, error: nil))
	}
}
