import Defaults

/**
Supported arguments for `@serde`.
*/
public enum SerdeOption {
	case skip
}

/**
Attached macro that synthesizes `Defaults.Serializable` conformance for a struct.

This macro generates:

1. A nested `Bridge` type named `<TypeName>Bridge`.
2. `serialize(_:)` and `deserialize(_:)` implementations based on stored properties.
3. A static `bridge` instance used by `Defaults`.

For example, given:

```swift
@SerdeDefault
struct User {
	var name: String
	var age: UInt?
}
```

The macro generates an extension equivalent to:

```swift
extension User: Defaults.Serializable {
	struct UserBridge: Defaults.Bridge {
		typealias Value = User
		typealias Serializable = [String: Any]
		// serialize(_:) and deserialize(_:)
	}

	static let bridge = UserBridge()
}
```

- Important: In this stage, `@SerdeDefault` supports `struct` declarations only.
*/
@attached(extension, conformances: Defaults.Serializable, names: named(bridge), suffixed(Bridge))
public macro SerdeDefault() = #externalMacro(module: "DefaultsMacrosDeclarations", type: "SerdeDefaultMacro")

/**
Peer macro used on stored properties in `@SerdeDefault` structs to configure serde behavior.

Supported arguments:

1. `@serde(.skip)`: Excludes the property from serialization and deserialization.

- Important: `skip` is only valid on optional properties.
*/
@attached(peer)
public macro serde(_ options: SerdeOption...) = #externalMacro(
	module: "DefaultsMacrosDeclarations",
	type: "SerdeMacro"
)
