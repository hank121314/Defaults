import Foundation

extension Defaults {
	/**
	This struct is trying to imitate `AnyCodable`.
	*/
	public struct AnySerializable: Defaults.Serializable {
		public let value: Any
		public static let bridge = AnyBridge()

		public init<T>(_ value: T?) {
			self.value = value ?? ()
		}
	}
}

extension Defaults.AnySerializable: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(value)
	}
}
extension Defaults.AnySerializable: ExpressibleByNilLiteral {
	public init(nilLiteral _: ()) {
		self.init(nil as Any?)
	}
}
extension Defaults.AnySerializable: ExpressibleByBooleanLiteral {
	public init(booleanLiteral value: Bool) {
		self.init(value)
	}
}
extension Defaults.AnySerializable: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: Int) {
		self.init(value)
	}
}
extension Defaults.AnySerializable: ExpressibleByFloatLiteral {
	public init(floatLiteral value: Double) {
		self.init(value)
	}
}
extension Defaults.AnySerializable: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Any...) {
		self.init(elements)
	}
}
extension Defaults.AnySerializable: ExpressibleByDictionaryLiteral {
	public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
		self.init([AnyHashable: Any](elements) { first, _ in first })
	}
}
