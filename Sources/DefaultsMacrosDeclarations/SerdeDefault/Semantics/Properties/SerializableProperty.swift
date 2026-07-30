import SwiftSyntax

extension SerdeDefault {
	/**
	Property that needs `Defaults.Serializable` conversion through its bridge.

	This is the catch-all strategy: `resolve(binding:)` always succeeds, so it must stay
	registered last in `StrategyFinder`.

	For serialization:

	```swift
	guard let property = PropertyType.toSerializable(value.property) else { return nil }
	serialized["property"] = property
	```

	For deserialization:

	```swift
	let property = PropertyType.toValue(base["property"] as Any, type: PropertyType.self)
	```
	*/
	struct SerializableProperty: Property {
		let binding: PatternBinding
		let attribute: SerdeAttribute

		static func matches(binding: PatternBinding, attribute _: SerdeAttribute) -> Bool {
			!binding.typeSyntax.isNativeSupportType()
		}

		func serialize(in context: Serialize.Context) -> Serialize.CodeGenerated {
			guard !isExcludedFromSerde() else {
				return .omitted
			}

			let type = unwrappedTypeSyntax
			let temporary = context.makeUniqueName(for: identifier)
			if typeSyntax.isOptional() {
				return .optional(
					"""
					if let \(temporary) = \(type).toSerializable(\(context.base).\(identifier)) {
						\(context.serialized)["\(identifier)"] = \(temporary)
					}
					"""
				)
			}

			return .serializable(
				"""
				guard let \(temporary) = \(type).toSerializable(\(context.base).\(identifier)) else { return nil }
				\(context.serialized)["\(identifier)"] = \(temporary)
				"""
			)
		}

		func deserialize(in context: Deserialize.Context) -> Deserialize.CodeGenerated {
			guard binding.isMemberwiseInitializable() else {
				return .omitted
			}

			if isExcludedFromSerde() {
				return .skipped(identifier: identifier)
			}

			let type = unwrappedTypeSyntax
			let value: ExprSyntax =
				"\(type).toValue(\(context.base)[\(literal: identifier.text)] as Any, type: \(type).self)"

			// A default value wins over optionality, so an optional property with an initializer
			// falls back to that initializer rather than to `nil`.
			let statement: CodeBlockItemSyntax
			if let initializer = binding.syntax.initializer {
				statement = "let \(identifier) = \(value) ?? \(initializer.value.trimmed)"
			} else if typeSyntax.isOptional() {
				statement = "let \(identifier) = \(value)"
			} else {
				statement = """
					guard let \(identifier) = \(value) else {
						return nil
					}
					"""
			}

			return .assignment(identifier: identifier, statement: statement)
		}
	}
}
