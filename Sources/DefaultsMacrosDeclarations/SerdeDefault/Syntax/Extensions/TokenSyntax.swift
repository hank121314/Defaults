import SwiftSyntax

extension TokenSyntax {
	/**
	Creates a declaration-reference expression from the token text.
	*/
	func declReference() -> DeclReferenceExprSyntax {
		DeclReferenceExprSyntax(leadingTrivia: nil, baseName: self.trimmed, trailingTrivia: nil)
	}

	func prefix(prefix: String) -> Self {
		TokenSyntax(stringLiteral: "\(prefix)\(self.text)")
	}

	/**
	Returns a token with `suffix` appended.

	- Parameter suffix: The suffix to append.
	*/
	func suffix(_ suffix: String) -> Self {
		TokenSyntax(stringLiteral: "\(self.text)\(suffix)")
	}
}
