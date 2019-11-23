import Foundation

class RocksCompactRangeTests : RocksDBTests {

	func testSwift_CompactRange_withKeysAndColumnFamily() {
		let opt = RocksDBDatabaseOptions()
		opt.createIfMissing = true
		opt.createMissingColumnFamilies = true

		let new_cf_opts = RocksDBColumnFamilyOptions()
		new_cf_opts.disableAutoCompactions = true
		new_cf_opts.compactionStyle = .level
		new_cf_opts.numLevels = 4
		new_cf_opts.writeBufferSize = 100 << 10
		new_cf_opts.level0FileNumCompactionTrigger = 3
		new_cf_opts.targetFileSizeBase = 200 << 10
		new_cf_opts.targetFileSizeMultiplier = 1
		new_cf_opts.maxBytesForLevelBase = 500 << 10
		new_cf_opts.maxBytesForLevelMultiplier = 1.0
		new_cf_opts.disableAutoCompactions = false

		let columnFamilyDescriptors = RocksDBColumnFamilyDescriptor()
		columnFamilyDescriptors.addDefaultColumnFamily(with: RocksDBColumnFamilyOptions())
		columnFamilyDescriptors.addColumnFamily(withName: "new_cf", andOptions: new_cf_opts)

		let options = RocksDBOptions(databaseOptions: opt, andColumnFamilyOptions: RocksDBColumnFamilyOptions())

		let db = try! RocksDB.database(atPath: self.path, columnFamilies: columnFamilyDescriptors, andOptions: options)

		// fill database with key/value pairs
		var b = Data(count: 10000)

		for i in 0...199 {
			_ = b.withUnsafeMutableBytes { (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
				SecRandomCopyBytes(kSecRandomDefault, 10000, mutableBytes)
			}
			try! db.setData(b, forKey: String(i).data, forColumnFamily: db.columnFamilies()[1])
		}
		let range = RocksDBKeyRange(
			start: "0".data,
			end: "201".data
		)

		try! db.compactRange(range, with: RocksDBCompactRangeOptions(), inColumnFamily: db.columnFamilies()[1])
	}
}
