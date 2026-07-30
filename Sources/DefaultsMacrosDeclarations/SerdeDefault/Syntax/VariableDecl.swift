import SwiftSyntax

extension SerdeDefault {
	struct VariableDecl {
		let syntax: VariableDeclSyntax

		init?(declaration: some DeclSyntaxProtocol) {
			guard let syntax = declaration.as(VariableDeclSyntax.self) else {
				return nil
			}
			self.syntax = syntax
		}

		/**
		Returns whether the variable declaration is static.
		*/
		func isStatic() -> Bool {
			syntax.modifiers.contains { modifier in
				modifier.name.text == DeclModifierSyntax.static.name.text
			}
		}

		/**
		Extracts typed bindings from the variable declaration.
		*/
		func typedBindings() throws(Error) -> [PatternBinding] {
			let specifier = self.syntax.bindingSpecifier
			let attributes = self.syntax.attributes

			return try self.syntax.bindings.enumerated().map { index, binding throws(Error) in
				let type = try self.type(for: binding, at: index)
				return try PatternBinding(
					specifier: specifier, syntax: binding, type: type, attributes: attributes
				)
			}
		}

		/**
		Resolves the type for the binding at `index`.

		If the binding has an initializer, simple literal types are inferred from it.
		Otherwise, this falls back to the next explicit type in the same declaration
		(for example, `var a, b: Int`).
		*/
		private func type(for binding: PatternBindingSyntax, at index: Int) throws(Error) -> TypeSyntax {
			if let typeSyntax = binding.typeAnnotation?.type {
				return typeSyntax
			}

			if let initializer = binding.initializer {
				guard let inferredType = initializer.value.inferredType() else {
					throw Error.inferredType(initializer.value)
				}

				return TypeSyntax(fromProtocol: inferredType)
			}

			guard
				let typeSyntax = self.syntax.bindings
					.map(\.typeAnnotation?.type)
					.dropFirst(index)
					.lazy
					.compactMap({ $0 })
					.first
			else {
				throw Error.missingType(binding)
			}

			return typeSyntax
		}
	}
}
