import SwiftSyntax

extension SerdeDefault {
	/**
	Property that `Defaults` can serialize and deserialize directly, without a bridge.

	For serialization:

	```swift
	serialized["property"] = value.property
	```

	For deserialization:

	```swift
	let property = base["property"] as? PropertyType
	```
	*/
	struct BasicProperty: Property {
		let binding: PatternBinding
		let attribute: SerdeAttribute

		static func matches(binding: PatternBinding, attribute _: SerdeAttribute) -> Bool {
			binding.typeSyntax.isNativeSupportType()
		}

		func serialize(in context: Serialize.Context) -> Serialize.CodeGenerated {
			guard !isExcludedFromSerde() else {
				return .omitted
			}

			// Optional properties are only included in the serialized output if they have a value.
			if typeSyntax.isOptional() {
				let temporary = context.makeUniqueName(for: identifier)
				return .optional(
					"""
					if let \(temporary) = \(context.base).\(identifier) {
						\(context.serialized)["\(identifier)"] = \(temporary)
					}
					"""
				)
			}

			return .basic(
				DictionaryElementSyntax(
					key: StringLiteralExprSyntax(content: "\(identifier)"),
					value: MemberAccessExprSyntax(
						base: context.base.declReference(),
						name: identifier
					)
				)
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
			let value: ExprSyntax = "\(context.base)[\(literal: identifier.text)] as? \(type)"

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
