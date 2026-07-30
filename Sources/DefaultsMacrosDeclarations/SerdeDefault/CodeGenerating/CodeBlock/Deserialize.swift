import SwiftSyntax

extension SerdeDefault {
	/**
	Code generator for func deserialize code blocks.

	For native properties:

	```swift
	let property = base["property"] as? PropertyType
	```
	For serializable properties:

	```swift
	let property = PropertyType.toValue(base["property"] as Any, type: PropertyType.self)
	```
	*/
	enum Deserialize: CodeGenerating {
		struct Context {
			/**
			The serialized dictionary parameter identifier being deserialized.
			*/
			let base: TokenSyntax
			/**
			The nominal type being rebuilt.
			*/
			let typeSyntax: TypeSyntax
		}

		/**
		Generated deserialization code for one property.

		- `omitted`: Property not in the memberwise initializer — excluded entirely.
		- `skipped`: Property marked with `@serde(.skip)` — passed as `nil` in the initializer.
		- `assignment`: Normal property with a binding statement and an initializer argument.
		*/
		enum CodeGenerated {
			case omitted
			case skipped(identifier: TokenSyntax)
			case assignment(identifier: TokenSyntax, statement: CodeBlockItemSyntax)
		}

		struct DeserializedCodeGenerated {
			let codesGenerated: [CodeGenerated]
			let typeSyntax: TypeSyntax

			/**
			The list of statements for initializing the properties.
			*/
			var statements: CodeBlockItemListSyntax {
				let statements = codesGenerated.compactMap { code -> CodeBlockItemSyntax? in
					guard case .assignment(_, let statement) = code else {
						return nil
					}
					return statement
				}
				return CodeBlockItemListSyntax(
					statements.enumerated().map { index, statement in
						statement.with(\.leadingTrivia, index == 0 ? [] : .newline)
					}
				)
			}

			/**
			The initializer expression for the nominal type, using the generated arguments.


			*/
			var initializer: FunctionCallExprSyntax {
				let callee: ExprSyntax = "\(typeSyntax.trimmed)"
				let arguments = codesGenerated.compactMap { code -> (label: TokenSyntax, expression: ExprSyntax)? in
					switch code {
					case .omitted:
						return nil
					// Properties marked with `@serde(.skip)` are passed as `nil` in the initializer.
					case .skipped(let identifier):
						return (identifier, ExprSyntax(NilLiteralExprSyntax()))
					case .assignment(let identifier, _):
						return (identifier, ExprSyntax(identifier.declReference()))
					}
				}
				let labeled = arguments.enumerated().map { index, argument in
					LabeledExprSyntax(
						label: argument.label,
						colon: .colonToken(),
						expression: argument.expression,
						trailingComma: index < arguments.count - 1 ? .commaToken() : nil
					)
				}
				return FunctionCallExprSyntax(callee: callee) {
					LabeledExprListSyntax(labeled)
				}
			}
		}

		static func codeGeneratedBlock(
			from properties: [any Property],
			in context: Context
		) -> CodeBlockSyntax {
			let codesGenerated = properties.map { property in
				property.deserialize(in: context)
			}
			let codeGenerated = DeserializedCodeGenerated(
				codesGenerated: codesGenerated,
				typeSyntax: context.typeSyntax
			)

			return CodeBlockSyntax(
				"""
				{
					guard let \(context.base) else { return nil }
					\(codeGenerated.statements)
					return \(codeGenerated.initializer)
				}
				"""
			)
		}
	}
}
