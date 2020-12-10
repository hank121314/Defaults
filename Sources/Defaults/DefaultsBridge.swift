import Foundation

public protocol DefaultsBridgeSerializable {
	typealias T = Bridge.T
	associatedtype Bridge: DefaultsBridge
	static var _defaults: Bridge { get }
}

public protocol DefaultsBridge {
	associatedtype T
	func get(_ key: String, suite: UserDefaults) -> T?
	func set(_ key: String, to value: T?, suite: UserDefaults)
	func serialize(_ value: T?) -> Any?
	func deserialize(_ value: Any?) -> T?
}


extension Optional: DefaultsBridgeSerializable where Wrapped: DefaultsBridgeSerializable {
	public typealias Bridge = DefaultsOptionalBridge<Wrapped.Bridge>

	public static var _defaults: DefaultsOptionalBridge<Wrapped.Bridge> { return DefaultsOptionalBridge(bridge: Wrapped._defaults) }
}

extension String: DefaultsBridgeSerializable {
	public static var _defaults: DefaultsStringBridge { return DefaultsStringBridge() }
}

extension URL: DefaultsBridgeSerializable {
	public static var _defaults: DefaultURLBridge { return DefaultURLBridge() }
}

public struct DefaultURLBridge: DefaultsBridge {
	public init() {}

	public func get(_ key: String, suite: UserDefaults = .standard) -> URL? {
		return suite.url(forKey: key)
	}

	public func set(_ key: String, to value: URL?, suite: UserDefaults = .standard) {
		suite.set(value, forKey: key)
	}

	public func serialize(_ value: URL?) -> Any? {
		return value
	}

	public func deserialize(_ value: Any?) -> URL? {
		if let value = value as? URL {
			return value
		}

		// URL that observe by UserDefaults is represented with type Data, So we need to handle this case
		if let value = value as? Data {
			return NSKeyedUnarchiver.unarchiveObject(with: value) as? URL
		}

		if let value = value as? NSString {
			return URL(string: value.expandingTildeInPath)
		}

		return nil
	}
}

public struct DefaultsStringBridge: DefaultsBridge {
	public init() {}

	public func get(_ key: String, suite: UserDefaults = .standard) -> String? {
		return suite.string(forKey: key)
	}

	public func set(_ key: String, to value: String?, suite: UserDefaults = .standard) {
		suite.set(value, forKey: key)
	}

	public func serialize(_ value: String?) -> Any? {
		return value
	}

	public func deserialize(_ value: Any?) -> String? {
		return value as? String
	}
}


public struct DefaultsOptionalBridge<Bridge: DefaultsBridge>: DefaultsBridge {
	public typealias T = Bridge.T?

	private let bridge: Bridge

	init(bridge: Bridge) {
		self.bridge = bridge
	}

	public func get(_ key: String, suite: UserDefaults = .standard) -> T? {
		return bridge.get(key, suite: suite)
	}

	public func set(_ key: String, to value: T?, suite: UserDefaults = .standard) {
		bridge.set(key, to: value as? Bridge.T, suite: suite)
	}

	public func serialize<Value>(_ value: Bridge.T??) -> Value? {
		return bridge.serialize(value as? Bridge.T) as? Value
	}

	public func deserialize(_ value: Any?) -> Bridge.T?? {
		return bridge.deserialize(value)
	}
}
