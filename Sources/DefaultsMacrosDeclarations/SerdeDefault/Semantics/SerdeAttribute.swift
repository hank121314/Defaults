import SwiftSyntax

extension SerdeDefault {
	/**
	Parsed arguments from the `@serde` attribute.
	*/
	struct SerdeAttribute {
		/**
		Name of the `@serde` attribute
		*/
		static let name = IdentifierTypeSyntax.serde.name

		/**
		Whether to skip the property during serialization and deserialization.
		*/
		let skip: Bool

		/**
		Parses and validates `@serde` arguments for a property binding.
		*/
		init(binding: PatternBinding) throws(Error) {
			try self.init(attributes: binding.attributes)
			if skip && !binding.typeSyntax.isOptional() {
				throw Error.skipOnNonOptional(binding.syntax)
			}
		}

		/**
		Parses `@serde` arguments from an attribute list.

		- Parameter attributes: Attributes to inspect.
		- Throws: `Error.mismatch` for invalid argument syntax, or
		  `Error.unknownAttribute` for unsupported arguments.
		- Returns: Parsed attribute values.
		*/
		init(attributes: AttributeListSyntax) throws(Error) {
			// Accumulates parsed `@serde` arguments before creating the immutable value.
			struct Builder {
				var skip: Bool = false
			}
			var builder = Builder()
			for attribute in attributes {
				guard
					let attribute = attribute.as(AttributeSyntax.self),
					case .argumentList(let arguments) = attribute.arguments
				else {
					continue
				}
				// Parse arguments only from `@serde(...)` and `@DefaultsMacros.serde(...)`.
				guard
					attribute.attributeName.isEqual(
						to: Self.name, inModule: IdentifierTypeSyntax.DefaultsMacros.name)
				else {
					continue
				}
				for argument in arguments {
					let name = try Self.findAttributeName(argument: argument)
					switch name.text {
					case IdentifierTypeSyntax.skip.name.text:
						builder.skip = true
					default:
						throw Error.unknownAttribute(argument.expression, name.text)
					}
				}
			}

			self.skip = builder.skip
		}

		/**
		Finds the attribute name from a labeled expression.
		Accepts `@serde(.skip)` and explicitly qualified `SerdeOption.skip` spellings.
		*/
		static func findAttributeName(argument: LabeledExprSyntax) throws(Error) -> TokenSyntax {
			let memberAccess: MemberAccessExprSyntax
			if let base = argument.expression.as(FunctionCallExprSyntax.self)?.calledExpression.as(
				MemberAccessExprSyntax.self
			) {
				memberAccess = base
			} else if let base = argument.expression.as(MemberAccessExprSyntax.self) {
				memberAccess = base
			} else {
				throw Error.mismatch(MemberAccessExprSyntax.self, argument.expression)
			}

			if let base = memberAccess.base {
				guard
					base.isEqual(
						to: IdentifierTypeSyntax.SerdeOption.name,
						inModule: IdentifierTypeSyntax.DefaultsMacros.name
					)
				else {
					throw Error.unknownAttribute(argument.expression, memberAccess.trimmedDescription)
				}
			}

			return memberAccess.declName.baseName
		}
	}
}
