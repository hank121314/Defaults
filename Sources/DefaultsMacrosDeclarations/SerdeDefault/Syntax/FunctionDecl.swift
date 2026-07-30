import SwiftSyntax

extension SerdeDefault {
	struct FunctionDecl {
		let syntax: FunctionDeclSyntax

		class Builder {
			/**
			The generated function name.
			*/
			let name: TokenSyntax
			/**
			The generated function access level.
			*/
			var accessLevel: AccessLevel = .internal
			/**
			Parameters collected for the function signature.
			*/
			var parameters: [FunctionParameterSyntax] = []
			var codeBlockItems: [CodeBlockItemSyntax] = []
			var returnType: ReturnClauseSyntax?

			init(name: TokenSyntax) {
				self.name = name
			}

			func setAccessLevel(accessLevel: AccessLevel) -> Self {
				self.accessLevel = accessLevel
				return self
			}

			/**
			Adds a parameter to the function signature.

			- Parameter firstName: External parameter name.
			- Parameter secondName: Internal parameter name.
			- Parameter type: Parameter type.
			*/
			func addParameter(
				firstName: TokenSyntax = .wildcardToken(),
				secondName: TokenSyntax,
				type: some TypeSyntaxProtocol
			) -> Self {
				self.parameters.append(
					FunctionParameterSyntax(
						firstName: firstName,
						secondName: secondName,
						type: type
					))
				return self
			}

			/**
			Sets the return type for the function signature.

			- Parameter returnType: The return type syntax.
			*/
			func setReturnType(returnType: some TypeSyntaxProtocol) -> Self {
				self.returnType = ReturnClauseSyntax(type: returnType)
				return self
			}

			/**
			Builds the final function declaration.

			- Returns: The generated function declaration.
			*/
			func build(_ codeBlock: ([FunctionParameterSyntax]) -> CodeBlockSyntax)
				-> FunctionDeclSyntax {
				let functionParameters = FunctionParameterClauseSyntax(
					parameters: FunctionParameterListSyntax(parameters)
				)

				let body = codeBlock(parameters)
				let functionSignature = FunctionSignatureSyntax(
					parameterClause: functionParameters,
					returnClause: returnType
				)

				return FunctionDeclSyntax(
					modifiers: [accessLevel.declModifier],
					name: name,
					signature: functionSignature,
					body: body,
				)
			}
		}
	}
}
