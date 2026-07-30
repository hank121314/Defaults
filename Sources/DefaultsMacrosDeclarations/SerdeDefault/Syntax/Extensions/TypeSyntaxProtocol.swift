import SwiftSyntax

extension TypeSyntaxProtocol {
	/**
	Returns generic arguments from either:

	- `IdentifierTypeSyntax` (for example, `Optional<UInt>`)
	- `MemberTypeSyntax` (for example, `Swift.Optional<UInt>`)

	Non-generic types return an empty array.
	*/
	func genericArguments() -> [GenericArgumentSyntax] {
		if let memberType = self.as(MemberTypeSyntax.self) {
			guard let genericArgumentClause = memberType.genericArgumentClause else {
				return []
			}
			return genericArgumentClause.arguments.map { GenericArgumentSyntax(argument: $0.argument) }
		}
		if let identifierType = self.as(IdentifierTypeSyntax.self) {
			guard let genericArgumentClause = identifierType.genericArgumentClause else {
				return []
			}
			return genericArgumentClause.arguments.map { GenericArgumentSyntax(argument: $0.argument) }
		}
		return []
	}

	/**
	Returns the wrapped type for any supported optional spelling:

	- `T?`
	- `Optional<T>`
	- `Swift.Optional<T>`
cv  
	Generated `toValue` calls use this to convert to `T` instead of producing nested optionals.
	*/
	func optionalWrappedType() -> (any TypeSyntaxProtocol)? {
		if let optionalType = self.as(OptionalTypeSyntax.self) {
			return optionalType.wrappedType
		}
		if self.isSwiftMemberGenericOptional() || self.isGenericOptional() {
			if let genericArgument = self.genericArguments().first {
				// `Optional<T>` should always carry a type argument.
				if case .type(let type) = genericArgument.argument {
					return type
				}
			}
		}

		return nil
	}

	/**
	Returns whether the type is exactly `Swift.Optional<T>`.

	This explicit check avoids accidentally matching unrelated `Optional` symbols
	from other modules or nested types.
	*/
	func isSwiftMemberGenericOptional() -> Bool {
		if let memberType = self.as(MemberTypeSyntax.self) {
			if let identifierType = memberType.baseType.as(IdentifierTypeSyntax.self) {
				return identifierType.name.text == IdentifierTypeSyntax.Swift.name.text
					&& memberType.name.text == IdentifierTypeSyntax.Optional.name.text
			}
		}
		return false
	}

	/**
	Returns whether the type is unqualified `Optional<T>`.
	*/
	func isGenericOptional() -> Bool {
		if let identifierType = self.as(IdentifierTypeSyntax.self) {
			if identifierType.name.text == IdentifierTypeSyntax.Optional.name.text {
				return true
			}
		}
		return false
	}

	/**
	Returns whether the type is any supported optional spelling.
	*/
	func isOptional() -> Bool {
		self.is(OptionalTypeSyntax.self) || self.isGenericOptional()
			|| self.isSwiftMemberGenericOptional()
	}

	/**
	Returns whether `Defaults` can store this type without a bridge.
	*/
	func isNativeSupportType() -> Bool {
		if let wrappedType = optionalWrappedType() {
			return wrappedType.isNativeSupportType()
		}

		switch TypeSyntax(self).as(TypeSyntaxEnum.self) {
		case .arrayType(let arrayType):
			return arrayType.element.isNativeSupportType()
		case .dictionaryType(let dictionaryType):
			guard
				let keyType = dictionaryType.key.as(IdentifierTypeSyntax.self),
				keyType.name.text == IdentifierTypeSyntax.String.name.text
			else {
				return false
			}
			return dictionaryType.value.isNativeSupportType()
		case .memberType(let memberType):
			return IdentifierTypeSyntax(name: memberType.name).isNativeSupportType()
		case .identifierType(let identifierType):
			return IdentifierTypeSyntax.nativeSupportedTypes.contains {
				$0.name.text == identifierType.name.text
			}
		default:
			return false
		}
	}
}
