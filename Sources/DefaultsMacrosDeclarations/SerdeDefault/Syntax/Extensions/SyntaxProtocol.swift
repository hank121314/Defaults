import SwiftSyntax

extension SyntaxProtocol {
	/**
	Returns whether the syntax is equal to the given name and module.

	- Parameter name: The name to compare against.
	- Parameter module: The module to compare against.
	- Returns: `true` if the syntax is equal to the name and module,
		`false` otherwise.
	*/
	func isEqual(to name: TokenSyntax, inModule module: TokenSyntax) -> Bool {
		switch Syntax(self).as(SyntaxEnum.self) {
		case .identifierType(let identifier):
			return identifier.name.text == name.text
		case .declReferenceExpr(let reference):
			return reference.baseName.text == name.text
		case .memberType(let memberType):
			guard let baseType = memberType.baseType.as(IdentifierTypeSyntax.self) else {
				return false
			}

			return memberType.name.text == name.text
				&& baseType.name.text == module.text
		case .memberAccessExpr(let memberAccess):
			guard let moduleReference = memberAccess.base?.as(DeclReferenceExprSyntax.self) else {
				return false
			}

			return memberAccess.declName.baseName.text == name.text
				&& moduleReference.baseName.text == module.text
		default:
			return false
		}
	}
}
