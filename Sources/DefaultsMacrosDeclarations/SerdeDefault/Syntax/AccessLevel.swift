import SwiftSyntax

/**
Swift access levels used for generated declarations.
*/
enum AccessLevel: CaseIterable, Comparable, Sendable {
	case `private`
	case `fileprivate`
	case `internal`
	case `package`
	case `public`

	init(modifiers: DeclModifierListSyntax) {
		for modifier in modifiers {
			if let accessLevel = Self.allCases.first(where: { $0.token.text == modifier.name.text }) {
				self = accessLevel
				return
			}
		}
		self = .internal
	}

	var declModifier: DeclModifierSyntax {
		DeclModifierSyntax(name: self.token)
	}

	/**
	The SwiftSyntax token for the access level.
	*/
	var token: TokenSyntax {
		switch self {
		case .`public`:
			return .keyword(.public)
		case .`package`:
			return .keyword(.package)
		case .`internal`:
			return .keyword(.internal)
		case .`fileprivate`:
			return .keyword(.fileprivate)
		case .`private`:
			return .keyword(.private)
		}
	}
}
