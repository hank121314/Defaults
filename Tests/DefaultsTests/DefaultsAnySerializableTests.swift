import Defaults
import Foundation
import XCTest

extension Defaults.Keys {
	fileprivate static let anyKey = Key<Defaults.AnySerializable>("anyKey", default: "🦄")
	fileprivate static let anyArrayKey = Key<[Defaults.AnySerializable]>("anyArrayKey", default: ["No.1 🦄", "No.2 🦄"])
	fileprivate static let anyDictionaryKey = Key<[String: Defaults.AnySerializable]>("anyDictionaryKey", default: ["unicorn": "🦄"])
}

final class DefaultsAnySerializableTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		// Test Int
		let any = Defaults.Key<Defaults.AnySerializable>("independentAnyKey", default: 121_314)
		XCTAssertEqual(Defaults[any].value as? Int, 121_314)
		// Test Int8
		let int8 = Int8.max
		Defaults[any] = Defaults.AnySerializable(int8)
		XCTAssertEqual(Defaults[any].value as? Int8, int8)
		// Test Int16
		let int16 = Int16.max
		Defaults[any] = Defaults.AnySerializable(int16)
		XCTAssertEqual(Defaults[any].value as? Int16, int16)
		// Test Int32
		let int32 = Int32.max
		Defaults[any] = Defaults.AnySerializable(int32)
		XCTAssertEqual(Defaults[any].value as? Int32, int32)
		// Test Int64
		let int64 = Int64.max
		Defaults[any] = Defaults.AnySerializable(int64)
		XCTAssertEqual(Defaults[any].value as? Int64, int64)
		// Test UInt
		let uint = UInt.max
		Defaults[any] = Defaults.AnySerializable(uint)
		XCTAssertEqual(Defaults[any].value as? UInt, uint)
		// Test UInt8
		let uint8 = UInt8.max
		Defaults[any] = Defaults.AnySerializable(uint8)
		XCTAssertEqual(Defaults[any].value as? UInt8, uint8)
		// Test UInt16
		let uint16 = UInt16.max
		Defaults[any] = Defaults.AnySerializable(uint16)
		XCTAssertEqual(Defaults[any].value as? UInt16, uint16)
		// Test UInt32
		let uint32 = UInt32.max
		Defaults[any] = Defaults.AnySerializable(uint32)
		XCTAssertEqual(Defaults[any].value as? UInt32, uint32)
		// Test UInt64
		let uint64 = UInt64.max
		Defaults[any] = Defaults.AnySerializable(uint64)
		XCTAssertEqual(Defaults[any].value as? UInt64, uint64)
		// Test Double
		Defaults[any] = 12_131.4
		XCTAssertEqual(Defaults[any].value as? Double, 12_131.4)
		// Test Bool
		Defaults[any] = true
		XCTAssertTrue(Defaults[any].value as! Bool)
		// Test String
		Defaults[any] = "121314"
		XCTAssertEqual(Defaults[any].value as? String, "121314")
		// Test Float
		let float: Float = 12_131.4
		Defaults[any] = Defaults.AnySerializable(float)
		XCTAssertEqual(Defaults[any].value as? Float, float)
		// Test Date
		let date = Date()
		Defaults[any] = Defaults.AnySerializable(date)
		XCTAssertEqual(Defaults[any].value as? Date, date)
		// Test Data
		let data = "121314".data(using: .utf8)
		Defaults[any] = Defaults.AnySerializable(data)
		XCTAssertEqual(Defaults[any].value as? Data, data)
		// Test Array
		Defaults[any] = [1, 2, 3]
		if let array = Defaults[any].value as? [Int] {
			XCTAssertEqual(array[0], 1)
			XCTAssertEqual(array[1], 2)
			XCTAssertEqual(array[2], 3)
		}
		// Test Dictionary
		Defaults[any] = ["unicorn": "🦄", "boolean": true, "number": 3]
		if let dictionary = Defaults[any].value as? [String: Any] {
			XCTAssertEqual(dictionary["unicorn"] as? String, "🦄")
			XCTAssert(dictionary["boolean"] as! Bool)
			XCTAssertEqual(dictionary["number"] as? Int, 3)
		}
	}

	func testOptionalKey() {
		let key = Defaults.Key<Defaults.AnySerializable?>("independentOptionalAnyKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = 12_131.4
		XCTAssertEqual(Defaults[key]!.value as! Double, 12_131.4)
		Defaults[key] = nil
		XCTAssertNil(Defaults[key])
	}

	func testArrayKey() {
		let key = Defaults.Key<[Defaults.AnySerializable]>("independentArrayAnyKey", default: [123, 456])
		XCTAssertEqual(Defaults[key][0].value as! Int, 123)
		XCTAssertEqual(Defaults[key][1].value as! Int, 456)
		Defaults[key][0] = 12_131.4
		XCTAssertEqual(Defaults[key][0].value as! Double, 12_131.4)
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[Defaults.AnySerializable]?>("testArrayOptionalAnyKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [123]
		Defaults[key]?.append(456)
		XCTAssertEqual(Defaults[key]![0].value as! Int, 123)
		XCTAssertEqual(Defaults[key]![1].value as! Int, 456)
		Defaults[key]![0] = 12_131.4
		XCTAssertEqual(Defaults[key]![0].value as! Double, 12_131.4)
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[Defaults.AnySerializable]]>("testNestedArrayAnyKey", default: [[123]])
		Defaults[key][0].append(456)
		XCTAssertEqual(Defaults[key][0][0].value as! Int, 123)
		XCTAssertEqual(Defaults[key][0][1].value as! Int, 456)
		Defaults[key].append([12_131.4])
		XCTAssertEqual(Defaults[key][1][0].value as! Double, 12_131.4)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: Defaults.AnySerializable]>("independentDictionaryAnyKey", default: ["unicorn": ""])
		XCTAssertEqual(Defaults[key]["unicorn"]?.value as! String, "")
		Defaults[key]["unicorn"] = "🦄"
		XCTAssertEqual(Defaults[key]["unicorn"]?.value as! String, "🦄")
		Defaults[key]["number"] = 3
		Defaults[key]["boolean"] = true
		XCTAssertEqual(Defaults[key]["number"]?.value as! Int, 3)
		XCTAssertEqual(Defaults[key]["boolean"]?.value as! Bool, true)
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Defaults.AnySerializable]?>("independentDictionaryOptionalAnyKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["unicorn": "🦄"]
		XCTAssertEqual(Defaults[key]?["unicorn"]?.value as! String, "🦄")
		Defaults[key]?["number"] = 3
		Defaults[key]?["boolean"] = true
		XCTAssertEqual(Defaults[key]?["number"]?.value as! Int, 3)
		XCTAssertEqual(Defaults[key]?["boolean"]?.value as! Bool, true)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Defaults.AnySerializable]]>("independentDictionaryArrayAnyKey", default: ["number": [1]])
		XCTAssertEqual(Defaults[key]["number"]?[0].value as? Int, 1)
		Defaults[key]["number"]?.append(2)
		Defaults[key]["unicorn"] = ["No.1 🦄"]
		Defaults[key]["unicorn"]?.append("No.2 🦄")
		Defaults[key]["unicorn"]?.append("No.3 🦄")
		Defaults[key]["boolean"] = [true]
		Defaults[key]["boolean"]?.append(false)
		XCTAssertEqual(Defaults[key]["number"]?[1].value as? Int, 2)
		XCTAssertEqual(Defaults[key]["unicorn"]?[0].value as? String, "No.1 🦄")
		XCTAssertEqual(Defaults[key]["unicorn"]?[1].value as? String, "No.2 🦄")
		XCTAssertEqual(Defaults[key]["unicorn"]?[2].value as? String, "No.3 🦄")
		XCTAssert(Defaults[key]["boolean"]?[0].value as! Bool)
		XCTAssertFalse(Defaults[key]["boolean"]?[1].value as! Bool)
	}

	func testType() {
		XCTAssertEqual(Defaults[.anyKey].value as? String, "🦄")
		Defaults[.anyKey] = 123
		XCTAssertEqual(Defaults[.anyKey].value as? Int, 123)
	}

	func testArrayType() {
		XCTAssertEqual(Defaults[.anyArrayKey][0].value as? String, "No.1 🦄")
		XCTAssertEqual(Defaults[.anyArrayKey][1].value as? String, "No.2 🦄")
		Defaults[.anyArrayKey].append(123)
		XCTAssertEqual(Defaults[.anyArrayKey][2].value as? Int, 123)
	}

	func testDictionaryType() {
		XCTAssertEqual(Defaults[.anyDictionaryKey]["unicorn"]?.value as? String, "🦄")
		Defaults[.anyDictionaryKey]["number"] = 3
		XCTAssertEqual(Defaults[.anyDictionaryKey]["number"]?.value as? Int, 3)
		Defaults[.anyDictionaryKey]["boolean"] = true
		XCTAssert(Defaults[.anyDictionaryKey]["boolean"]!.value as! Bool)
		Defaults[.anyDictionaryKey]["array"] = [1, 2]
		if let array = Defaults[.anyDictionaryKey]["array"]?.value as? [Int] {
			XCTAssertEqual(array[0], 1)
			XCTAssertEqual(array[1], 2)
		}
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<Defaults.AnySerializable>("observeAnyKeyCombine", default: 123)
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(Defaults.AnySerializable, Defaults.AnySerializable)] = [(123, "🦄"), ("🦄", 123)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				if tuples[index].0.value is Int {
					XCTAssertEqual(expected.0.value as? Int, (tuples[index].0.value as! Int))
					XCTAssertEqual(expected.1.value as? String, (tuples[index].1.value as! String))
				} else {
					XCTAssertEqual(expected.0.value as? String, (tuples[index].0.value as! String))
					XCTAssertEqual(expected.1.value as? Int, (tuples[index].1.value as! Int))
				}
			}

			expect.fulfill()
		}

		Defaults[key] = "🦄"
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<Defaults.AnySerializable?>("observeAnyOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(Defaults.AnySerializable?, Defaults.AnySerializable?)] = [(nil, 123), (123, "🦄"), ("🦄", nil)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				if tuples[index].0?.value is Int {
					XCTAssertEqual(expected.0?.value as? Int, (tuples[index].0!.value as! Int))
					XCTAssertEqual(expected.1?.value as? String, (tuples[index].1!.value as! String))
				} else if tuples[index].0?.value is String {
					XCTAssertEqual(expected.0?.value as? String, (tuples[index].0!.value as! String))
					XCTAssertNil(tuples[index].1?.value)
				} else {
					XCTAssertNil(tuples[index].0?.value)
					XCTAssertEqual(expected.1?.value as? Int, (tuples[index].1!.value as! Int))
				}
			}

			expect.fulfill()
		}

		Defaults[key] = 123
		Defaults[key] = "🦄"
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<Defaults.AnySerializable>("observeAnyKey", default: 123)
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue.value as? Int, 123)
			XCTAssertEqual(change.newValue.value as? String, "🦄")
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = "🦄"
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<Defaults.AnySerializable?>("observeAnyOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue?.value as? String, "🦄")
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = "🦄"
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}
}
