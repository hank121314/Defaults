import SwiftSyntax

extension SerdeDefault {
	/**
	Stored property prepared for bridge generation.

	Conformers own the serialization and deserialization code generation for one kind of property, and know whether they apply to a given binding via `matches(binding:attribute:)`. Structure shared by every kind — skip and omission checks, optional handling, `guard` scaffolding — lives in the protocol extension below so conformers only provide what actually varies.
	*/
	protocol Property {
		/**
		The pattern binding this property was created from.
		*/
		var binding: PatternBinding { get }

		/**
		Parsed `@serde` attribute arguments for this property.
		*/
		var attribute: SerdeAttribute { get }

		init(binding: PatternBinding, attribute: SerdeAttribute)

		/**
		Returns whether this property kind applies to `binding`.

		- Parameter attribute: Parsed `@serde` arguments for `binding`, so a kind selected by an
		  attribute rather than by type can recognize itself.
		*/
		static func matches(binding: PatternBinding, attribute: SerdeAttribute) -> Bool

		/**
		Generates the serialization code contributed by this property.
		*/
		func serialize(in context: Serialize.Context) -> Serialize.CodeGenerated

		/**
		Generates the deserialization code contributed by this property.
		*/
		func deserialize(in context: Deserialize.Context) -> Deserialize.CodeGenerated
	}
}

extension SerdeDefault.Property {
	/**
	Property identifier used as the serialized key.
	*/
	var identifier: TokenSyntax { binding.identifier }

	/**
	Property type used to choose serialization behavior.
	*/
	var typeSyntax: TypeSyntax { binding.typeSyntax }

	/**
	Property type with any optional wrapper removed.

	Trimmed, since the type is interpolated into generated statements where leftover
	trivia from the source (for example, `Int ` in `var a: Int = 1`) would leak through.
	*/
	var unwrappedTypeSyntax: TypeSyntax {
		guard let wrappedType = typeSyntax.optionalWrappedType() else {
			return typeSyntax.trimmed
		}
		return TypeSyntax(fromProtocol: wrappedType).trimmed
	}

	/**
	Returns whether this property should be excluded from serialization and deserialization.

	Properties marked with `@serde(.skip)` or constants with default values are excluded, as they cannot be reliably deserialized.
	*/
	func isExcludedFromSerde() -> Bool {
		attribute.skip || !binding.isMemberwiseInitializable()
	}
}
