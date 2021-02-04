import Defaults
import Foundation
import XCTest

private struct UniqueID: LosslessStringConvertible, Defaults.Serializable, Defaults.NativeType, Hashable {
	typealias CodableForm = String

	var id: Int64

	var description: String {
		"\(id)"
	}

	init(id: Int64) {
		self.id = id
	}

	init?(_ description: String) {
		self.init(id: Int64(description) ?? 0)
	}

	static let bridge = UniqueIDBridge()
}

private struct UniqueIDBridge: Defaults.Bridge {
	typealias Value = UniqueID
	typealias Serializable = String

	func serialize(_ value: Value?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		return String(value)
	}

	func deserialize(_ object: String?) -> UniqueID? {
		guard
			let object = object,
			let id = UniqueID(object)
		else {
			return nil
		}

		return id
	}
}

private struct TimeZone: Defaults.Serializable & Defaults.NativeType, Hashable {
	/// Associated `CodableForm` to `CodableTimeZone`
	typealias CodableForm = CodableTimeZone

	var id: String
	var name: String

	static let bridge = TimeZoneBridge()
}

private struct CodableTimeZone: Defaults.Serializable & Defaults.CodableType {
	var id: String
	var name: String

	/// Convert from `Codable` to `Native`
	func toNative() -> TimeZone {
		TimeZone(id: id, name: name)
	}
}

private struct TimeZoneBridge: Defaults.Bridge {
	typealias Value = TimeZone
	typealias Serializable = [String: Any]

	func serialize(_ value: TimeZone?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		return ["id": value.id, "name": value.name]
	}

	func deserialize(_ object: Serializable?) -> TimeZone? {
		guard
			let dictionary = object,
			let id = dictionary["id"] as? String,
			let name = dictionary["name"] as? String
		else {
			return nil
		}

		return TimeZone(id: id, name: name)
	}
}

private protocol BagForm {
	associatedtype Element
	var items: [Element] { get set }
}

extension BagForm {
	var startIndex: Int {
		items.startIndex
	}

	var endIndex: Int {
		items.endIndex
	}

	mutating func insert(element: Element, at: Int) {
		items.insert(element, at: at)
	}

	func index(after index: Int) -> Int {
		items.index(after: index)
	}

	subscript(position: Int) -> Element {
		get { items[position] }
		set { items[position] = newValue }
	}
}

private struct MyBag<Element: Defaults.Serializable & Defaults.NativeType>: Defaults.CollectionSerializable & Defaults.NativeType, BagForm {
	typealias CodableForm = [Element.CodableForm]

	var items: [Element]

	init(_ elements: [Element]) {
		self.items = elements
	}
}

private enum EnumForm: String, Defaults.Serializable & Defaults.NativeType {
	typealias CodableForm = CodableEnumForm

	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

private enum CodableEnumForm: String, Defaults.Serializable & Defaults.CodableType {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"

	func toNative() -> EnumForm {
		switch self {
		case .tenMinutes:
			return .tenMinutes
		case .halfHour:
			return .halfHour
		case .oneHour:
			return .oneHour
		}
	}
}

private func setCodable<Value: Codable>(forKey keyName: String, data: Value) {
	guard
		let text = try? JSONEncoder().encode(data),
		let string = String(data: text, encoding: .utf8)
	else {
		XCTAssert(false)
		return
	}

	UserDefaults.standard.set(string, forKey: keyName)
}

extension Defaults.Keys {
	fileprivate static let nativeArray = Key<[String]?>("arrayToNativeStaticArrayKey")
}

final class DefaultsMigrationTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testDataToNativeData() {
		let answer = "Hello World!"
		let keyName = "dataToNativeData"
		let data = answer.data(using: .utf8)
		setCodable(forKey: keyName, data: data)
		let key = Defaults.Key<Data?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(answer, String(data: Defaults[key]!, encoding: .utf8))
		let newName = " Hank Chen"
		Defaults[key]?.append(newName.data(using: .utf8)!)
		XCTAssertEqual(answer + newName, String(data: Defaults[key]!, encoding: .utf8))
	}

	func testArrayDataToNativeCollectionData() {
		let answer = "Hello World!"
		let keyName = "arrayDataToNativeCollectionData"
		let data = answer.data(using: .utf8)
		setCodable(forKey: keyName, data: [data])
		let key = Defaults.Key<MyBag<Data>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(answer, String(data: Defaults[key]!.first!, encoding: .utf8))
		let newName = " Hank Chen"
		Defaults[key]?[0].append(newName.data(using: .utf8)!)
		XCTAssertEqual(answer + newName, String(data: Defaults[key]!.first!, encoding: .utf8))
	}

	func testDateToNativeDate() {
		let date = Date()
		let keyName = "dateToNativeDate"
		setCodable(forKey: keyName, data: date)
		let key = Defaults.Key<Date?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(date, Defaults[key])
		let newDate = Date()
		Defaults[key] = newDate
		XCTAssertEqual(newDate, Defaults[key])
	}

	func testDateToNativeCollectionDate() {
		let date = Date()
		let keyName = "dateToNativeCollectionDate"
		setCodable(forKey: keyName, data: [date])
		let key = Defaults.Key<MyBag<Date>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(date, Defaults[key]!.first)
		let newDate = Date()
		Defaults[key]?[0] = newDate
		XCTAssertEqual(newDate, Defaults[key]!.first)
	}

	func testBoolToNativeBool() {
		let bool = false
		let keyName = "boolToNativeBool"
		setCodable(forKey: keyName, data: bool)
		let key = Defaults.Key<Bool?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], bool)
		let newBool = true
		Defaults[key] = newBool
		XCTAssertEqual(Defaults[key], newBool)
	}

	func testBoolToNativeCollectionBool() {
		let bool = false
		let keyName = "boolToNativeCollectionBool"
		setCodable(forKey: keyName, data: [bool])
		let key = Defaults.Key<MyBag<Bool>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], bool)
		let newBool = true
		Defaults[key]?[0] = newBool
		XCTAssertEqual(Defaults[key]?[0], newBool)
	}

	func testIntToNativeInt() {
		let int = Int.min
		let keyName = "intToNativeInt"
		setCodable(forKey: keyName, data: int)
		let key = Defaults.Key<Int?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], int)
		let newInt = Int.max
		Defaults[key] = newInt
		XCTAssertEqual(Defaults[key], newInt)
	}

	func testIntToNativeCollectionInt() {
		let int = Int.min
		let keyName = "intToNativeCollectionInt"
		setCodable(forKey: keyName, data: [int])
		let key = Defaults.Key<MyBag<Int>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], int)
		let newInt = Int.max
		Defaults[key]?[0] = newInt
		XCTAssertEqual(Defaults[key]?[0], newInt)
	}

	func testUIntToNativeUInt() {
		let uInt = UInt.min
		let keyName = "uIntToNativeUInt"
		setCodable(forKey: keyName, data: uInt)
		let key = Defaults.Key<UInt?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], uInt)
		let newUInt = UInt.max
		Defaults[key] = newUInt
		XCTAssertEqual(Defaults[key], newUInt)
	}

	func testUIntToNativeCollectionUInt() {
		let uInt = UInt.min
		let keyName = "uIntToNativeCollectionUInt"
		setCodable(forKey: keyName, data: [uInt])
		let key = Defaults.Key<MyBag<UInt>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], uInt)
		let newUInt = UInt.max
		Defaults[key]?[0] = newUInt
		XCTAssertEqual(Defaults[key]?[0], newUInt)
	}

	func testDoubleToNativeDouble() {
		let double = Double.zero
		let keyName = "doubleToNativeDouble"
		setCodable(forKey: keyName, data: double)
		let key = Defaults.Key<Double?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], double)
		let newDouble = Double.infinity
		Defaults[key] = newDouble
		XCTAssertEqual(Defaults[key], newDouble)
	}

	func testDoubleToNativeCollectionDouble() {
		let double = Double.zero
		let keyName = "doubleToNativeCollectionDouble"
		setCodable(forKey: keyName, data: [double])
		let key = Defaults.Key<MyBag<Double>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], double)
		let newDouble = Double.infinity
		Defaults[key]?[0] = newDouble
		XCTAssertEqual(Defaults[key]?[0], newDouble)
	}

	func testFloatToNativeFloat() {
		let float = Float.zero
		let keyName = "floatToNativeFloat"
		setCodable(forKey: keyName, data: float)
		let key = Defaults.Key<Float?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], float)
		let newFloat = Float.infinity
		Defaults[key] = newFloat
		XCTAssertEqual(Defaults[key], newFloat)
	}

	func testFloatToNativeCollectionFloat() {
		let float = Float.zero
		let keyName = "floatToNativeCollectionFloat"
		setCodable(forKey: keyName, data: [float])
		let key = Defaults.Key<MyBag<Float>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], float)
		let newFloat = Float.infinity
		Defaults[key]?[0] = newFloat
		XCTAssertEqual(Defaults[key]?[0], newFloat)
	}

	func testCGFloatToNativeCGFloat() {
		let cgFloat = CGFloat.zero
		let keyName = "cgFloatToNativeCGFloat"
		setCodable(forKey: keyName, data: cgFloat)
		let key = Defaults.Key<CGFloat?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], cgFloat)
		let newCGFloat = CGFloat.infinity
		Defaults[key] = newCGFloat
		XCTAssertEqual(Defaults[key], newCGFloat)
	}

	func testCGFloatToNativeCollectionCGFloat() {
		let cgFloat = CGFloat.zero
		let keyName = "cgFloatToNativeCollectionCGFloat"
		setCodable(forKey: keyName, data: [cgFloat])
		let key = Defaults.Key<MyBag<CGFloat>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], cgFloat)
		let newCGFloat = CGFloat.infinity
		Defaults[key]?[0] = newCGFloat
		XCTAssertEqual(Defaults[key]?[0], newCGFloat)
	}

	func testInt8ToNativeInt8() {
		let int8 = Int8.min
		let keyName = "int8ToNativeInt8"
		setCodable(forKey: keyName, data: int8)
		let key = Defaults.Key<Int8?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], int8)
		let newInt8 = Int8.max
		Defaults[key] = newInt8
		XCTAssertEqual(Defaults[key], newInt8)
	}

	func testInt8ToNativeCollectionInt8() {
		let int8 = Int8.min
		let keyName = "int8ToNativeCollectionInt8"
		setCodable(forKey: keyName, data: [int8])
		let key = Defaults.Key<MyBag<Int8>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], int8)
		let newInt8 = Int8.max
		Defaults[key]?[0] = newInt8
		XCTAssertEqual(Defaults[key]?[0], newInt8)
	}

	func testUInt8ToNativeUInt8() {
		let uInt8 = UInt8.min
		let keyName = "uInt8ToNativeUInt8"
		setCodable(forKey: keyName, data: uInt8)
		let key = Defaults.Key<UInt8?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], uInt8)
		let newUInt8 = UInt8.max
		Defaults[key] = newUInt8
		XCTAssertEqual(Defaults[key], newUInt8)
	}

	func testUInt8ToNativeCollectionUInt8() {
		let uInt8 = UInt8.min
		let keyName = "uInt8ToNativeCollectionUInt8"
		setCodable(forKey: keyName, data: [uInt8])
		let key = Defaults.Key<MyBag<UInt8>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], uInt8)
		let newUInt8 = UInt8.max
		Defaults[key]?[0] = newUInt8
		XCTAssertEqual(Defaults[key]?[0], newUInt8)
	}

	func testInt16ToNativeInt16() {
		let int16 = Int16.min
		let keyName = "int16ToNativeInt16"
		setCodable(forKey: keyName, data: int16)
		let key = Defaults.Key<Int16?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], int16)
		let newInt16 = Int16.max
		Defaults[key] = newInt16
		XCTAssertEqual(Defaults[key], newInt16)
	}

	func testInt16ToNativeCollectionInt16() {
		let int16 = Int16.min
		let keyName = "int16ToNativeCollectionInt16"
		setCodable(forKey: keyName, data: [int16])
		let key = Defaults.Key<MyBag<Int16>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], int16)
		let newInt16 = Int16.max
		Defaults[key]?[0] = newInt16
		XCTAssertEqual(Defaults[key]?[0], newInt16)
	}

	func testUInt16ToNativeUInt16() {
		let uInt16 = UInt16.min
		let keyName = "uInt16ToNativeUInt16"
		setCodable(forKey: keyName, data: uInt16)
		let key = Defaults.Key<UInt16?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], uInt16)
		let newUInt16 = UInt16.max
		Defaults[key] = newUInt16
		XCTAssertEqual(Defaults[key], newUInt16)
	}

	func testUInt16ToNativeCollectionUInt16() {
		let uInt16 = UInt16.min
		let keyName = "uInt16ToNativeCollectionUInt16"
		setCodable(forKey: keyName, data: [uInt16])
		let key = Defaults.Key<MyBag<UInt16>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], uInt16)
		let newUInt16 = UInt16.max
		Defaults[key]?[0] = newUInt16
		XCTAssertEqual(Defaults[key]?[0], newUInt16)
	}

	func testInt32ToNativeInt32() {
		let int32 = Int32.min
		let keyName = "int32ToNativeInt32"
		setCodable(forKey: keyName, data: int32)
		let key = Defaults.Key<Int32?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], int32)
		let newInt32 = Int32.max
		Defaults[key] = newInt32
		XCTAssertEqual(Defaults[key], newInt32)
	}

	func testInt32ToNativeCollectionInt32() {
		let int32 = Int32.min
		let keyName = "int32ToNativeCollectionInt32"
		setCodable(forKey: keyName, data: [int32])
		let key = Defaults.Key<MyBag<Int32>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], int32)
		let newInt32 = Int32.max
		Defaults[key]?[0] = newInt32
		XCTAssertEqual(Defaults[key]?[0], newInt32)
	}

	func testUInt32ToNativeUInt32() {
		let uInt32 = UInt32.min
		let keyName = "uInt32ToNativeUInt32"
		setCodable(forKey: keyName, data: uInt32)
		let key = Defaults.Key<UInt32?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], uInt32)
		let newUInt32 = UInt32.max
		Defaults[key] = newUInt32
		XCTAssertEqual(Defaults[key], newUInt32)
	}

	func testUInt32ToNativeCollectionUInt32() {
		let uInt32 = UInt32.min
		let keyName = "uInt32ToNativeCollectionUInt32"
		setCodable(forKey: keyName, data: [uInt32])
		let key = Defaults.Key<MyBag<UInt32>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], uInt32)
		let newUInt32 = UInt32.max
		Defaults[key]?[0] = newUInt32
		XCTAssertEqual(Defaults[key]?[0], newUInt32)
	}

	func testInt64ToNativeInt64() {
		let int64 = Int64.min
		let keyName = "int64ToNativeInt64"
		setCodable(forKey: keyName, data: int64)
		let key = Defaults.Key<Int64?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], int64)
		let newInt64 = Int64.max
		Defaults[key] = newInt64
		XCTAssertEqual(Defaults[key], newInt64)
	}

	func testInt64ToNativeCollectionInt64() {
		let int64 = Int64.min
		let keyName = "int64ToNativeCollectionInt64"
		setCodable(forKey: keyName, data: [int64])
		let key = Defaults.Key<MyBag<Int64>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], int64)
		let newInt64 = Int64.max
		Defaults[key]?[0] = newInt64
		XCTAssertEqual(Defaults[key]?[0], newInt64)
	}

	func testUInt64ToNativeUInt64() {
		let uInt64 = UInt64.min
		let keyName = "uInt64ToNativeUInt64"
		setCodable(forKey: keyName, data: uInt64)
		let key = Defaults.Key<UInt64?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], uInt64)
		let newUInt64 = UInt64.max
		Defaults[key] = newUInt64
		XCTAssertEqual(Defaults[key], newUInt64)
	}

	func testUInt64ToNativeCollectionUInt64() {
		let uInt64 = UInt64.min
		let keyName = "uInt64ToNativeCollectionUInt64"
		setCodable(forKey: keyName, data: [uInt64])
		let key = Defaults.Key<MyBag<UInt64>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], uInt64)
		let newUInt64 = UInt64.max
		Defaults[key]?[0] = newUInt64
		XCTAssertEqual(Defaults[key]?[0], newUInt64)
	}

	func testArrayURLToNativeCollectionURL() {
		let url = URL(string: "https://sindresorhus.com")!
		let keyName = "arrayURLToNativeCollectionURL"
		setCodable(forKey: keyName, data: [url])
		let key = Defaults.Key<[URL]?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], url)
		let newURL = URL(string: "https://example.com")!
		Defaults[key]?.append(newURL)
		XCTAssertEqual(Defaults[key]?[1], newURL)
	}

	func testArrayToNativeArray() {
		let keyName = "arrayToNativeArrayKey"
		setCodable(forKey: keyName, data: ["a", "b", "c"])
		let key = Defaults.Key<[String]>(keyName, default: [])
		Defaults.migration(key)
		let newValue = "d"
		Defaults[key].append(newValue)
		XCTAssertEqual(Defaults[key][0], "a")
		XCTAssertEqual(Defaults[key][1], "b")
		XCTAssertEqual(Defaults[key][2], "c")
		XCTAssertEqual(Defaults[key][3], newValue)
	}

	func testArrayToNativeStaticOptionalArray() {
		let keyName = "arrayToNativeStaticArrayKey"
		setCodable(forKey: keyName, data: ["a", "b", "c"])
		Defaults.migration(.nativeArray)
		let newValue = "d"
		Defaults[.nativeArray]?.append(newValue)
		XCTAssertEqual(Defaults[.nativeArray]?[0], "a")
		XCTAssertEqual(Defaults[.nativeArray]?[1], "b")
		XCTAssertEqual(Defaults[.nativeArray]?[2], "c")
		XCTAssertEqual(Defaults[.nativeArray]?[3], newValue)
	}

	func testArrayToNativeOptionalArray() {
		let keyName = "arrayToNativeArrayKey"
		setCodable(forKey: keyName, data: ["a", "b", "c"])
		let key = Defaults.Key<[String]?>(keyName)
		Defaults.migration(key)
		let newValue = "d"
		Defaults[key]?.append(newValue)
		XCTAssertEqual(Defaults[key]?[0], "a")
		XCTAssertEqual(Defaults[key]?[1], "b")
		XCTAssertEqual(Defaults[key]?[2], "c")
		XCTAssertEqual(Defaults[key]?[3], newValue)
	}

	func testArrayToNativeSet() {
		let keyName = "arrayToNativeSet"
		setCodable(forKey: keyName, data: ["a", "b", "c"])
		let key = Defaults.Key<Set<String>?>(keyName)
		Defaults.migration(key)
		let newValue = "d"
		Defaults[key]?.insert(newValue)
		XCTAssertEqual(Defaults[key], Set(["a", "b", "c", "d"]))
	}

	func testArrayToNativeCollectionType() {
		let keyName = "arrayToNativeCollectionType"
		setCodable(forKey: keyName, data: ["a", "b", "c"])
		let key = Defaults.Key<MyBag<String>?>(keyName)
		Defaults.migration(key)
		let newValue = "d"
		Defaults[key]?.insert(element: newValue, at: 3)
		XCTAssertEqual(Defaults[key]?[0], "a")
		XCTAssertEqual(Defaults[key]?[1], "b")
		XCTAssertEqual(Defaults[key]?[2], "c")
		XCTAssertEqual(Defaults[key]?[3], newValue)
	}

	func testArrayAndCodableElementToNativeCollectionType() {
		let keyName = "arrayAndCodableElementToNativeCollectionType"
		setCodable(forKey: keyName, data: [CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<MyBag<TimeZone>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?.insert(element: .init(id: "1", name: newName), at: 1)
		XCTAssertEqual(Defaults[key]?[1].name, newName)
	}

	func testCodableToNativeType() {
		let keyName = "codableCodableToNativeType"
		setCodable(forKey: keyName, data: CodableTimeZone(id: "0", name: "Asia/Taipei"))
		let key = Defaults.Key<TimeZone>(keyName, default: .init(id: "1", name: "Asia/Tokio"))
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key].name = newName
		XCTAssertEqual(Defaults[key].name, newName)
	}

	func testCodableToNativeOptionalType() {
		let keyName = "codableCodableToNativeOptionalType"
		setCodable(forKey: keyName, data: CodableTimeZone(id: "0", name: "Asia/Taipei"))
		let key = Defaults.Key<TimeZone?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?.name = newName
		XCTAssertEqual(Defaults[key]?.name, newName)
	}

	func testArrayAndCodableElementToNativeArray() {
		let keyName = "codableArrayAndCodableElementToNativeArray"
		setCodable(forKey: keyName, data: [CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<[TimeZone]?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?[0].name = newName
		XCTAssertEqual(Defaults[key]?[0].name, newName)
	}

	func testArrayAndCodableElementToNativeSet() {
		let keyName = "arrayAndCodableElementToNativeSet"
		setCodable(forKey: keyName, data: [CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<Set<TimeZone>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], Set([TimeZone(id: "0", name: "Asia/Taipei")]))
		let newId = "1"
		let newName = "Asia/Tokyo"
		Defaults[key]?.insert(.init(id: newId, name: newName))
		XCTAssertEqual(Defaults[key], Set([TimeZone(id: "0", name: "Asia/Taipei"), TimeZone(id: newId, name: newName)]))
	}

	func testDictionaryToNativelyDictionary() {
		let keyName = "codableDictionaryToNativelyDictionary"
		setCodable(forKey: keyName, data: ["Hank": "Chen"])
		let key = Defaults.Key<[String: String]?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?["Hank"], "Chen")
	}

	func testDictionaryAndCodableValueToNativeDictionary() {
		let keyName = "codableArrayAndCodableElementToNativeArray"
		setCodable(forKey: keyName, data: ["0": CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<[String: TimeZone]?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?["0"]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?["0"]?.name = newName
		XCTAssertEqual(Defaults[key]?["0"]?.name, newName)
	}

	func testDictionaryCodableKeyAndCodableValueToNativeDictionary() {
		let keyName = "dictionaryCodableKeyAndCodableValueToNativeDictionary"
		setCodable(forKey: keyName, data: [123: CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<[UInt32: TimeZone]?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[123]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?[123]?.name = newName
		XCTAssertEqual(Defaults[key]?[123]?.name, newName)
	}

	func testDictionaryCustomKeyAndCodableValueToNativeDictionary() {
		let keyName = "dictionaryCustomAndCodableValueToNativeDictionary"
		setCodable(forKey: keyName, data: [1234: CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<[UniqueID: TimeZone]?>(keyName)
		Defaults.migration(key)
		let id = UniqueID(id: 1234)
		XCTAssertEqual(Defaults[key]?[id]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?[id]?.name = newName
		XCTAssertEqual(Defaults[key]?[id]?.name, newName)
	}

	func testEnumToNativeEnum() {
		let keyName = "enumToNativeEnum"
		setCodable(forKey: keyName, data: CodableEnumForm.tenMinutes)
		let key = Defaults.Key<EnumForm?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], .tenMinutes)
		Defaults[key] = .halfHour
		XCTAssertEqual(Defaults[key], .halfHour)
	}

	func testArrayEnumToNativeArrayEnum() {
		let keyName = "arrayEnumToNativeArrayEnum"
		setCodable(forKey: keyName, data: [CodableEnumForm.tenMinutes])
		let key = Defaults.Key<[EnumForm]?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], .tenMinutes)
		Defaults[key]?.append(.halfHour)
		XCTAssertEqual(Defaults[key]?[1], .halfHour)
	}

	func testArrayEnumToNativeSetEnum() {
		let keyName = "arrayEnumToNativeSetEnum"
		setCodable(forKey: keyName, data: Set([CodableEnumForm.tenMinutes]))
		let key = Defaults.Key<Set<EnumForm>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?.first, .tenMinutes)
		Defaults[key]?.insert(.halfHour)
		XCTAssertEqual(Defaults[key], Set([.tenMinutes, .halfHour]))
	}
}
