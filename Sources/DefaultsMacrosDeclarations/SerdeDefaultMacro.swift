import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Macro declaration for the ``SerdeDefault`` macro.
public struct SerdeDefaultMacro {}

enum SerdeDefault {}

extension SerdeDefaultMacro: ExtensionMacro {
	/**
	Generates the extension declaration that adds `Defaults.Serializable` conformance.

	- Parameter declaration: The declaration annotated with `@SerdeDefault`.
	- Parameter type: The concrete type being extended.

	- Returns: The generated extension declaration.
	*/
	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
		providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
		conformingTo protocols: [SwiftSyntax.TypeSyntax],
		in context: some SwiftSyntaxMacros.MacroExpansionContext
	) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		let nominalDecl: SerdeDefault.NominalDecl
		do {
			nominalDecl = try SerdeDefault.NominalDecl(
				declaration: declaration, type: type, macroContext: context)
		} catch {
			context.diagnose(Diagnostic(node: Syntax(fromProtocol: error.syntax()), message: error))
			return []
		}
		let inheritanceClause = InheritanceClauseSyntax(
			inheritedTypes: InheritedTypeListSyntax([
				InheritedTypeSyntax(type: MemberTypeSyntax.DefaultsSerializable)
			])
		)

		// Generate the bridge type and store an instance on `static let bridge`.
		let bridgeStruct = nominalDecl.bridgeStructDecl()
		let bridgeVariable = nominalDecl.bridgeVariableDecl()

		let memberBlock = MemberBlockSyntax(
			members: MemberBlockItemListSyntax([
				MemberBlockItemSyntax(decl: DeclSyntax(bridgeStruct)),
				MemberBlockItemSyntax(decl: DeclSyntax(bridgeVariable))
			])
		)
		let extensionDecl = ExtensionDeclSyntax(
			extendedType: nominalDecl.typeSyntax,
			inheritanceClause: inheritanceClause,
			memberBlock: memberBlock
		)
		return [extensionDecl]
	}
}
