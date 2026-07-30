import SwiftSyntax
import SwiftSyntaxMacros

extension SerdeDefault {
	/**
	Nominal declaration annotated with `@SerdeDefault`.
	*/
	struct NominalDecl {
		/**
		The nominal type name.
		*/
		let identifier: TokenSyntax
		/**
		The access level of the nominal type.

		If the declaration does not specify an access level, this defaults to `internal`.
		*/
		let accessLevel: AccessLevel
		/**
		The actual type syntax for the nominal type.
		*/
		let typeSyntax: TypeSyntax
		/**
		The properties of the nominal type.
		*/
		let properties: Properties
		/**
		The context for code generation of the `serialize` function.
		*/
		let serializeContext: SerdeDefault.Serialize.Context
		/**
		The context for code generation of the `deserialize` function.
		*/
		let deserializeContext: SerdeDefault.Deserialize.Context

		init(
			declaration: some SwiftSyntax.DeclGroupSyntax,
			type: some TypeSyntaxProtocol,
			macroContext: MacroExpansionContext
		) throws(SerdeDefault.Error) {
			// TODO: Support class declarations.
			guard let structDecl = declaration.as(StructDeclSyntax.self) else {
				throw SerdeDefault.Error.unexpectedNominalType(declaration)
			}
			try self.init(structDecl: structDecl, type: type, context: macroContext)
		}

		private init(
			structDecl: StructDeclSyntax,
			type: some TypeSyntaxProtocol,
			context: MacroExpansionContext
		) throws(SerdeDefault.Error) {
			// TODO: Support generic types. This needs the generated extension to carry the
			// right `where` clauses, so reject it outright instead of expanding to code that
			// fails with an unrelated error.
			if let genericParameterClause = structDecl.genericParameterClause {
				throw SerdeDefault.Error.genericType(genericParameterClause)
			}
			identifier = structDecl.name
			accessLevel = AccessLevel(modifiers: structDecl.modifiers)
			let typeSyntax = TypeSyntax(fromProtocol: type)
			self.typeSyntax = typeSyntax
			let variables = structDecl.memberBlock.members
				.compactMap {
					SerdeDefault.VariableDecl(declaration: $0.decl)
					// Ignore static properties, as they cannot be serialized or deserialized.
				}
				.filter { !$0.isStatic() }
			let bindings = try Self.bindings(variables: variables)
			properties = try Properties(bindings: bindings)
			// `base` and `serialized` can be spelled literally because property names reach the
			// generated function only as member accesses (`value.name`) or dictionary keys. The
			// temporaries the properties bind are the part that has to be unique.
			serializeContext = SerdeDefault.Serialize.Context(
				base: "value",
				serialized: IdentifierTypeSyntax.serialized.name,
				macroContext: context
			)
			deserializeContext = SerdeDefault.Deserialize.Context(
				base: context.makeUniqueName("serialized"),
				typeSyntax: typeSyntax
			)
		}

		/**
		Extracts stored bindings from the nominal type variables.
		*/
		static func bindings(variables: [VariableDecl]) throws(SerdeDefault.Error) -> [PatternBinding] {
			try variables
				.map { variable throws(Error) -> [PatternBinding] in
					try variable.typedBindings()
				}
				.flatMap { $0 }
				.filter { $0.isStored() }
		}
	}
}
