struct StructMetadata: NominalMetadataType {
	var pointer: UnsafeMutablePointer<StructMetadataLayout>

	mutating func getProperties() -> [PropertyInfo] {
		self.properties()
	}
}
