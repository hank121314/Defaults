import SwiftSyntax

extension SerdeDefault {
	struct Properties {
		let properties: [any Property]

		/**
		Initializes properties from the nominal type bindings.

		- Parameter bindings: Pattern bindings from the nominal type.
		*/
		init(bindings: [PatternBinding]) throws(Error) {
			properties = try bindings.map { binding throws(Error) -> any Property in
				try StrategyFinder.resolve(binding: binding)
			}
		}

		/**
		Generates a code block for these properties using the given generator.

		- Parameter generator: The property-code generator to use.
		- Parameter context: Context passed through to the generator.
		*/
		func codeGenerated<Generator: SerdeDefault.CodeGenerating>(
			using generator: Generator.Type,
			in context: Generator.Context
		) -> CodeBlockSyntax {
			generator.codeGeneratedBlock(from: properties, in: context)
		}
	}
}
