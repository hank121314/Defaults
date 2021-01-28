struct StructMetadata: NominalMetadataType {
	var pointer: UnsafeMutablePointer<StructMetadataLayout>

	mutating func toTypeInfo() -> TypeInfo {
		var info = TypeInfo()
		info.properties = properties()
		info.mangledName = mangledName()
		return info
	}
}
