import SwiftDiagnostics
import SwiftSyntax

extension SerdeDefault {
	/**
	Diagnostics emitted by `SerdeDefaultMacro`.
	*/
	enum Error: Swift.Error {
		/**
		The declaration is not a supported nominal type (`struct` only).
		*/
		case unexpectedNominalType(any SyntaxProtocol)
		/**
		The nominal declaration has generic parameters.
		*/
		case genericType(any SyntaxProtocol)
		/**
		The syntax node does not match the expected type.
		*/
		case mismatch(Any.Type, any SyntaxProtocol)
		/**
		The property binding is missing a type annotation.
		*/
		case missingType(any SyntaxProtocol)
		/**
		The stored property type could not be inferred from its initializer.
		*/
		case inferredType(any SyntaxProtocol)
		/**
		A non-optional property is marked with `@serde(.skip)`, which is unsupported.
		*/
		case skipOnNonOptional(any SyntaxProtocol)
		/**
		An attribute is not recognized.
		*/
		case unknownAttribute(any SyntaxProtocol, String)
		/**
		No registered `Property` strategy could resolve the binding.

		This should be unreachable while a catch-all strategy (`SerializableProperty`) is registered.
		*/
		case unresolvedProperty(any SyntaxProtocol)

		func syntax() -> any SyntaxProtocol {
			switch self {
			case .unexpectedNominalType(let got):
				got
			case .genericType(let got):
				got
			case .mismatch(_, let got):
				got
			case .missingType(let got):
				got
			case .inferredType(let got):
				got
			case .skipOnNonOptional(let got):
				got
			case .unknownAttribute(let got, _):
				got
			case .unresolvedProperty(let got):
				got
			}
		}

		var caseName: String {
			switch self {
			case .unexpectedNominalType:
				"unexpectedNominalType"
			case .genericType:
				"genericType"
			case .mismatch:
				"mismatch"
			case .missingType:
				"missingType"
			case .inferredType:
				"inferredType"
			case .skipOnNonOptional:
				"skipOnNonOptional"
			case .unknownAttribute:
				"unknownAttribute"
			case .unresolvedProperty:
				"unresolvedProperty"
			}
		}
	}
}

extension SerdeDefault.Error: DiagnosticMessage {
	var message: String {
		switch self {
		case .unexpectedNominalType(let got):
			"Expected a struct declaration. Received: \(got.syntaxNodeType)."
				+ " In this first-stage implementation, `@SerdeDefault` supports structs only."
		case .genericType:
			"`@SerdeDefault` does not support generic types. Apply it to a concrete struct instead."
		case .mismatch(let expected, let got):
			"Expected syntax node type: \(expected). Received: \(got.syntaxNodeType)."
		case .missingType:
			"Missing type annotation for `@SerdeDefault` stored property."
				+ " Add an explicit type annotation or use an initializer with a supported literal type."
		case .inferredType:
			"Could not infer the type of `@SerdeDefault` stored property initializer."
				+ " Add an explicit type annotation."
		case .skipOnNonOptional:
			"Non-optional property is marked with `@serde(.skip)`, which is not supported."
				+ " Please remove the `skip` argument or make the property optional."
		case .unknownAttribute(_, let name):
			"Unknown attribute found: \(name)."
		case .unresolvedProperty:
			"Could not resolve a serialization strategy for this property."
		}
	}

	var diagnosticID: SwiftDiagnostics.MessageID {
		MessageID(domain: "com.sindresorhus.SerdeDefaultMacro", id: "\(caseName)")
	}

	var severity: SwiftDiagnostics.DiagnosticSeverity {
		.error
	}
}
