struct StructMetadataLayout: NominalMetadataLayoutType {
	var _kind: Int
	/// The nominal type descriptor is referenced at offset 1.
	var typeDescriptor: UnsafeMutablePointer<StructTypeDescriptor>
}
