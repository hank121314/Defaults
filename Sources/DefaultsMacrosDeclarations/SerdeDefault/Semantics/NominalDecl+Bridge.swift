import SwiftSyntax

extension SerdeDefault.NominalDecl {
	/**
	The generated bridge struct name.
	*/
	private var bridgeName: TokenSyntax {
		identifier.suffix(IdentifierTypeSyntax.Bridge.name.text)
	}

	/**
	The access level for generated bridge declarations.
	*/
	private var bridgeAccessLevel: AccessLevel? {
		accessLevel > .internal ? accessLevel : nil
	}

	/**
	Generates the stored bridge instance for the expanded extension.

	The generated member is `static let bridge = <BridgeType>()`. If the source
	nominal type is wider than `internal`, that access level is preserved.

	- Returns: The generated `bridge` declaration.
	*/
	func bridgeVariableDecl() -> VariableDeclSyntax {
		let modifiers = bridgeAccessLevel.map { [$0.declModifier, .static] } ?? [.static]
		let binding = PatternBindingSyntax(
			pattern: IdentifierPatternSyntax(identifier: IdentifierTypeSyntax.bridge.name),
			initializer: InitializerClauseSyntax(
				value: FunctionCallExprSyntax(callee: bridgeName.declReference())
			))
		return VariableDeclSyntax(
			modifiers: DeclModifierListSyntax(modifiers),
			bindingSpecifier: .keyword(.let),
			bindings: PatternBindingListSyntax([binding])
		)
	}

	/**
	Generates the nested `Defaults.Bridge` implementation.

	- Returns: The generated bridge type declaration.
	*/
	func bridgeStructDecl() -> StructDeclSyntax {
		let modifiers = DeclModifierListSyntax(bridgeAccessLevel.map { [$0.declModifier] } ?? [])
		let deserializeContext = self.deserializeContext
		let valueTypeAlias = TypeAliasDeclSyntax(
			modifiers: modifiers,
			name: IdentifierTypeSyntax.Value.name,
			initializer: TypeInitializerClauseSyntax(value: typeSyntax)
		)
		// TODO: Allow overriding this alias and keep this as the default.
		let serializableTypeAlias = TypeAliasDeclSyntax(
			modifiers: modifiers,
			name: IdentifierTypeSyntax.Serializable.name,
			initializer: TypeInitializerClauseSyntax(
				value: DictionaryTypeSyntax(
					key: IdentifierTypeSyntax.String,
					value: IdentifierTypeSyntax.Any,
				)
			)
		)

		// Generate `serialize` function.
		let serializeCodeBlock = properties.codeGenerated(
			using: SerdeDefault.Serialize.self,
			in: serializeContext
		)
		let serializeFunction = SerdeDefault.FunctionDecl.Builder(
			name: IdentifierTypeSyntax.serialize.name
		)
		.setAccessLevel(accessLevel: .public)
		.addParameter(secondName: serializeContext.base, type: IdentifierTypeSyntax.Value.optional())
		.setReturnType(returnType: IdentifierTypeSyntax.Serializable.optional())
		.build { _ in serializeCodeBlock }

		// Generate `deserialize` function.
		let deserializeCodeBlock = properties.codeGenerated(
			using: SerdeDefault.Deserialize.self,
			in: deserializeContext
		)
		let deserializeFunction = SerdeDefault.FunctionDecl.Builder(
			name: IdentifierTypeSyntax.deserialize.name
		)
		.setAccessLevel(accessLevel: .public)
		.addParameter(
			secondName: deserializeContext.base, type: IdentifierTypeSyntax.Serializable.optional()
		)
		.setReturnType(returnType: IdentifierTypeSyntax.Value.optional())
		.build { _ in deserializeCodeBlock }

		let memberBlock = MemberBlockSyntax(
			members: MemberBlockItemListSyntax([
				MemberBlockItemSyntax(decl: DeclSyntax(valueTypeAlias)),
				MemberBlockItemSyntax(decl: DeclSyntax(serializableTypeAlias)),
				MemberBlockItemSyntax(decl: DeclSyntax(serializeFunction)),
				MemberBlockItemSyntax(decl: DeclSyntax(deserializeFunction))
			])
		)

		return StructDeclSyntax(
			modifiers: modifiers,
			name: bridgeName,
				inheritanceClause: InheritanceClauseSyntax(
					inheritedTypes: InheritedTypeListSyntax([
						InheritedTypeSyntax(
							type: MemberTypeSyntax.DefaultsBridge,
							trailingComma: .commaToken()
						),
						InheritedTypeSyntax(
							type: IdentifierTypeSyntax.Sendable
						)
					])
				),
				memberBlock: memberBlock
			)
	}
}
