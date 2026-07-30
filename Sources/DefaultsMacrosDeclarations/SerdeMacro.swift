import SwiftSyntax
import SwiftSyntaxMacros

/**
Macro declaration for the ``serde`` macro.
*/
public struct SerdeMacro {}

extension SerdeMacro: PeerMacro {
	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
		in context: some SwiftSyntaxMacros.MacroExpansionContext
	) throws -> [SwiftSyntax.DeclSyntax] {
		guard SerdeDefault.VariableDecl(declaration: declaration) != nil else {
			throw SerdeDefault.Error.mismatch(VariableDeclSyntax.self, declaration)
		}

		return []
	}
}
