import SwiftSyntax

extension SwiftSyntax.MemberTypeSyntax {
	/**
	Type syntax for `DefaultsMacros.SerdeOption`.
	*/
	static let DefaultsMacrosSerdeOption = Self(
		baseType: SwiftSyntax.IdentifierTypeSyntax.DefaultsMacros,
		name: SwiftSyntax.IdentifierTypeSyntax.SerdeOption.name)
	/**
	Type syntax for `Defaults.Bridge`.
	*/
	static let DefaultsBridge = Self(
		baseType: SwiftSyntax.IdentifierTypeSyntax.Defaults,
		name: SwiftSyntax.IdentifierTypeSyntax.Bridge.name)
	/**
	Type syntax for `Defaults.Serializable`.
	*/
	static let DefaultsSerializable = Self(
		baseType: SwiftSyntax.IdentifierTypeSyntax.Defaults,
		name: SwiftSyntax.IdentifierTypeSyntax.Serializable.name)
}
