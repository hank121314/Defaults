import Foundation

struct PropertyInfo {
	let name: String
	let type: Any.Type
	let isVar: Bool
	let offset: Int
	let ownerType: Any.Type
}

protocol PropertyInfoConvertible {
	mutating func getProperties() -> [PropertyInfo]
}

// swiftlint:disable discouraged_optional_collection
func propertyInfo(of type: Any.Type) -> [PropertyInfo]? {
	let kind = Kind(type: type)

	var propertyInfoConvertible: PropertyInfoConvertible?

	switch kind {
	case .struct:
		propertyInfoConvertible = StructMetadata(type: type)
	default:
		propertyInfoConvertible = nil
	}

	guard propertyInfoConvertible != nil else {
		return nil
	}

	return propertyInfoConvertible?.getProperties()
}
