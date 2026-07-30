import SwiftSyntax

extension SerdeDefault {
	/**
	Resolves the `Property` implementation for a binding by trying registered strategies in order.
	*/
	struct StrategyFinder {
		/**
		Candidate strategies, tried in order. The first one that resolves wins.

		`SerializableProperty` is the catch-all and must stay last.
		*/
		static var strategies: [any Property.Type] {
			[
				BasicProperty.self,
				SerializableProperty.self
			]
		}

		/**
		Resolves the `Property` implementation for `binding`.

		The binding's `@serde` arguments are parsed once up front and handed to every candidate, so
		strategies selected by an attribute can recognize themselves without re-parsing.

		- Throws: `Error` if the `@serde` arguments are invalid, or `Error.unresolvedProperty` if no
		  registered strategy matches the binding. The latter should be unreachable while a catch-all
		  strategy is registered.
		*/
		static func resolve(binding: PatternBinding) throws(Error) -> any Property {
			let attribute = try SerdeAttribute(binding: binding)
			for strategy in strategies where strategy.matches(binding: binding, attribute: attribute) {
				return strategy.init(binding: binding, attribute: attribute)
			}
			throw Error.unresolvedProperty(binding.syntax)
		}

		/**
		Re-resolves `property` to the one strategy among `strategies` that matches it.

		Reuses the already-parsed binding and attribute, so — unlike `resolve(binding:attribute:)` —
		this cannot fail. `property` is returned unchanged when nothing matches.

		- Parameter strategies: Strategies to try, in order. A strategy that wraps the result has to
		  narrow this to the strategies after itself, or it matches its own binding and recurses.
		*/
		static func resolve(
			property: any Property,
			_ strategies: [any Property.Type] = strategies
		) -> any Property {
			for strategy in strategies
			where strategy.matches(binding: property.binding, attribute: property.attribute) {
				return strategy.init(binding: property.binding, attribute: property.attribute)
			}
			return property
		}
	}
}
