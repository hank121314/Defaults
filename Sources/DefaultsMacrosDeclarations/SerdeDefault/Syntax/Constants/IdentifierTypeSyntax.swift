import SwiftSyntax

extension SwiftSyntax.IdentifierTypeSyntax {
	// MARK: Identifiers for generated `Defaults.Serializable` conformance
	static let Defaults = Self(name: "Defaults")
	static let Serializable = Self(name: "Serializable")
	static let Bridge = Self(name: "Bridge")
	static let Value = Self(name: "Value")
	static let bridge = Self(name: "bridge")
	static let serialize = Self(name: "serialize")
	static let deserialize = Self(name: "deserialize")
	static let serialized = Self(name: "serialized")

	// MARK: Identifiers for Swift and Foundation types
	static let Swift = Self(name: "Swift")
	static let `Optional` = Self(name: "Optional")
	static let `Any` = Self(name: "Any")
	static let Sendable = Self(name: "Sendable")
	static let Bool = Self(name: "Bool")
	static let Int = Self(name: "Int")
	static let UInt = Self(name: "UInt")
	static let Double = Self(name: "Double")
	static let Float = Self(name: "Float")
	static let String = Self(name: "String")
	static let Data = Self(name: "Data")
	static let Date = Self(name: "Date")
	static let CGFloat = Self(name: "CGFloat")
	static let Int8 = Self(name: "Int8")
	static let UInt8 = Self(name: "UInt8")
	static let Int16 = Self(name: "Int16")
	static let UInt16 = Self(name: "UInt16")
	static let Int32 = Self(name: "Int32")
	static let UInt32 = Self(name: "UInt32")
	static let Int64 = Self(name: "Int64")
	static let UInt64 = Self(name: "UInt64")

	/**
	Identifier for the `@serde` attribute.
	*/
	static let serde = Self(name: "serde")
	/**
	Identifier for the `DefaultsMacros` module used to qualify `SerdeOption`.
	*/
	static let DefaultsMacros = Self(name: "DefaultsMacros")
	/**
	Identifier for the `SerdeOption` enum used by `@serde`.
	*/
	static let SerdeOption = Self(name: "SerdeOption")
	/**
	Identifier for the `skip` argument used in `@serde(.skip)`.
	*/
	static let skip = Self(name: "skip")

	/**
	Types that `Defaults` stores in `UserDefaults` without a bridge.

	Keep this in sync with the `isNativelySupportedType = true` declarations in `Defaults+Extensions.swift`.
	*/
	static let nativeSupportedTypes: [Self] = [
		.Bool,
		.Int,
		.UInt,
		.Double,
		.Float,
		.String,
		.Data,
		.Date,
		.CGFloat,
		.Int8,
		.UInt8,
		.Int16,
		.UInt16,
		.Int32,
		.UInt32,
		.Int64,
		.UInt64
	]
}
