import SwiftSyntax

extension SerdeDefault {
	/**
	Protocol for property-code generators.
	*/
	protocol CodeGenerating {
		associatedtype Context
		associatedtype CodeGenerated

		/**
		Generates a code block for multiple properties from their generated code.
		*/
		static func codeGeneratedBlock(
			from properties: [any Property],
			in context: Context
		) -> CodeBlockSyntax
	}
}
