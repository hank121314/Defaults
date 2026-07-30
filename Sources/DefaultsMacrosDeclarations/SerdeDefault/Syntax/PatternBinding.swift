import SwiftSyntax

extension SerdeDefault {
	struct PatternBinding {
		let specifier: TokenSyntax
		let syntax: PatternBindingSyntax
		let identifier: TokenSyntax
		let typeSyntax: TypeSyntax
		let attributes: AttributeListSyntax

		init(
			specifier: TokenSyntax,
			syntax: PatternBindingSyntax,
			type: some TypeSyntaxProtocol,
			attributes: AttributeListSyntax? = nil
		) throws(SerdeDefault.Error) {
			self.specifier = specifier
			self.syntax = syntax
			self.identifier = try Self.identifier(in: syntax)
			self.typeSyntax = TypeSyntax(fromProtocol: type)
			self.attributes = attributes ?? []
		}

		/**
		Extracts the identifier from a pattern binding.

		- Throws: `SerdeDefault.Error.mismatch` when the pattern is not an identifier.
		*/
		static func identifier(in syntax: PatternBindingSyntax) throws(SerdeDefault.Error)
			-> TokenSyntax {
			guard let pattern = syntax.pattern.as(IdentifierPatternSyntax.self) else {
				throw SerdeDefault.Error.mismatch(IdentifierPatternSyntax.self, syntax.pattern)
			}
			return pattern.identifier.trimmed
		}

		/**
		Returns whether this binding can be initialized with the memberwise initializer.
		*/
		func isMemberwiseInitializable() -> Bool {
			isStored()
				&& !(specifier.tokenKind == .keyword(.let) && syntax.initializer != nil)
		}

		/**
		Returns whether this binding represents a stored property.

		Computed properties with a getter are excluded.
		Observed properties (`willSet`/`didSet`) are treated as stored.
		*/
		func isStored() -> Bool {
			// Bindings without an accessor block are stored properties.
			guard let accessorBlock = self.syntax.accessorBlock else {
				return true
			}
			switch accessorBlock.accessors {
			case .getter:
				return false
			case .accessors(let accessors):
				return accessors.allSatisfy { accessor in
					switch accessor.accessorSpecifier.tokenKind {
					case .keyword(.willSet), .keyword(.didSet):
						return true
					default:
						return false
					}
				}
			}
		}
	}
}
