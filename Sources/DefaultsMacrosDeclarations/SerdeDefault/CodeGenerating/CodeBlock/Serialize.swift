import SwiftSyntax
import SwiftSyntaxMacros

extension SerdeDefault {
	/**
	Code generator for func serialize code blocks.

	For native properties:

	```swift
	serialized["property"] = value.property
	```

	For serializable properties:

	```swift
	guard let property = PropertyType.toSerializable(value.property) else { return nil }
	serialized["property"] = property
	```
	*/
	enum Serialize: CodeGenerating {
		struct Context {
			/**
			The value parameter identifier being serialized.
			*/
			let base: TokenSyntax
			/**
			The dictionary identifier that receives serialized values.
			*/
			let serialized: TokenSyntax
			/**
			The expansion context, used to mint collision-free identifiers.
			*/
			let macroContext: any MacroExpansionContext

			/**
			Returns a collision-free name for the temporary that holds `identifier`'s value.

			`base` and `serialized` are the only other identifiers declared in the generated
			function, and property names reach it only as member accesses (`value.name`) or
			dictionary keys. Minting the temporaries is therefore enough to keep the whole
			function hygienic — a property named `serialized` would otherwise shadow the
			dictionary it is being written into.
			*/
			func makeUniqueName(for identifier: TokenSyntax) -> TokenSyntax {
				macroContext.makeUniqueName(identifier.text)
			}
		}

		/**
		Generated serialization code for one property.

		- `omitted`: Property excluded from serialization (e.g. marked with `@serde(.skip)`).
		- `basic`: Direct dictionary entries for non-optional native values.
		- `optional`: Conditional assignments for optional values.
		- `serializable`: Conversion code for values backed by `Defaults.Serializable`.
		*/
		enum CodeGenerated {
			case omitted
			case basic(DictionaryElementSyntax)
			case optional(CodeBlockItemSyntax)
			case serializable(CodeBlockItemSyntax)
		}

		struct SerializedCodeGenerated {
			let codesGenerated: [CodeGenerated]

			var initializer: ExprSyntax {
				let initializerElements = codesGenerated.compactMap { code in
					if case .basic(let element) = code {
						return element
					}
					return nil
				}
				if initializerElements.isEmpty {
					return ExprSyntax("[:]")
				}
				return ExprSyntax(
					stringLiteral: "[\(initializerElements.map(\.description).joined(separator: ", "))]"
				)
			}

			var assignments: CodeBlockItemListSyntax {
				let assignments: [CodeBlockItemSyntax] = codesGenerated.compactMap { code in
					switch code {
					case .omitted, .basic:
						return nil
					case .optional(let code), .serializable(let code):
						return code
					}
				}
				return CodeBlockItemListSyntax(assignments)
			}
		}

		static func codeGeneratedBlock(
			from properties: [any Property],
			in context: Context
		) -> CodeBlockSyntax {
			let codesGenerated = properties.map { property in
				property.serialize(in: context)
			}
			let codeGenerated = SerializedCodeGenerated(codesGenerated: codesGenerated)
			// Only bind with `var` when something actually mutates the dictionary, otherwise
			// every expansion warns that it was never mutated.
			let bindingSpecifier: TokenSyntax =
				codeGenerated.assignments.isEmpty ? .keyword(.let) : .keyword(.var)

			return CodeBlockSyntax(
				"""
				{
					guard let \(context.base) else { return nil }
					\(bindingSpecifier) \(context.serialized): \(IdentifierTypeSyntax.Serializable) = \(codeGenerated.initializer)
					\(codeGenerated.assignments)
					return \(context.serialized)
				}
				"""
			)
		}
	}
}
