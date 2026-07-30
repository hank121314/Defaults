import SwiftSyntax

extension SwiftSyntax.DeclModifierSyntax {
	/**
	Reusable `public` modifier for generated declarations.
	*/
	static let `public` = Self(name: .keyword(.public))
	/**
	Reusable `static` modifier for generated declarations.
	*/
	static let `static` = Self(name: .keyword(.static))
}
