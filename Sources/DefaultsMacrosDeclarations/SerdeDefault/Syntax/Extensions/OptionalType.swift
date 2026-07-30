import SwiftSyntax

extension SerdeDefault {
	/**
	Supports wrapping syntax nodes in `OptionalTypeSyntax`.
	*/
	protocol OptionalType {
		/**
		Wraps the type in `OptionalTypeSyntax`.
		*/
		func optional() -> OptionalTypeSyntax
	}
}

extension SerdeDefault.OptionalType where Self: TypeSyntaxProtocol {
	func optional() -> OptionalTypeSyntax {
		OptionalTypeSyntax(wrappedType: self)
	}
}

/**
Allows identifier types such as `String` and `Int` to be wrapped in `OptionalTypeSyntax`.
*/
extension IdentifierTypeSyntax: SerdeDefault.OptionalType {}
