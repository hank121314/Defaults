import SwiftSyntax

extension ExprSyntax {
	/**
	Infers a Swift type from simple literals and type expressions.
	*/
	func inferredType() -> (any TypeSyntaxProtocol)? {
		switch self.as(ExprSyntaxEnum.self) {
		case .prefixOperatorExpr(let prefixExpr):
			switch prefixExpr.operator.text {
			case "+", "-":
				return prefixExpr.expression.inferredType()
			default:
				return nil
			}

		case .tupleExpr(let tupleExpr):
			guard
				tupleExpr.elements.count == 1,
				let element = tupleExpr.elements.first,
				element.label == nil
			else {
				return nil
			}

			return element.expression.inferredType()

		case .booleanLiteralExpr:
			return IdentifierTypeSyntax.Bool

		case .integerLiteralExpr:
			return IdentifierTypeSyntax.Int

		case .floatLiteralExpr:
			return IdentifierTypeSyntax.Double

		case .stringLiteralExpr:
			return IdentifierTypeSyntax.String

		case .typeExpr(let typeExpr):
			return typeExpr.type

		case .arrayExpr(let arrayExpr):
			guard
				let firstElement = arrayExpr.elements.first,
				let type = firstElement.expression.inferredType()
			else {
				return nil
			}

			return ArrayTypeSyntax(element: TypeSyntax(fromProtocol: type))

		case .dictionaryExpr(let dictionaryExpr):
			guard
				case .elements(let elements) = dictionaryExpr.content,
				let firstElement = elements.first,
				let keyType = firstElement.key.inferredType(),
				let valueType = firstElement.value.inferredType()
			else {
				return nil
			}

			return DictionaryTypeSyntax(
				key: TypeSyntax(fromProtocol: keyType),
				value: TypeSyntax(fromProtocol: valueType)
			)

		default:
			return nil
		}
	}
}
