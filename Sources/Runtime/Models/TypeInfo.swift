import Foundation

struct TypeInfo {
	var mangledName: String = ""
	var properties: [PropertyInfo] = []

	func property(named: String) -> PropertyInfo? {
		guard let prop = properties.first(where: { $0.name == named }) else {
			return nil
		}

		return prop
	}
}

func typeInfo(of type: Any.Type) -> TypeInfo? {
	let kind = Kind(type: type)

	var typeInfoConvertible: TypeInfoConvertible?

	switch kind {
	case .struct:
		typeInfoConvertible = StructMetadata(type: type)
	default:
		return nil
	}

	guard typeInfoConvertible != nil else {
		return nil
	}

	return typeInfoConvertible?.toTypeInfo()
}
