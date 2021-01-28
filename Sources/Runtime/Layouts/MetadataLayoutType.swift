import Foundation

protocol MetadataLayoutType {
	/// The kind field is a pointer-sized integer that describes the kind of type the metadata describes. This field is at offset 0 from the metadata pointer.
	var _kind: Int { get set }
}

protocol NominalMetadataLayoutType: MetadataLayoutType {
	associatedtype Descriptor: TypeDescriptor
	var typeDescriptor: UnsafeMutablePointer<Descriptor> { get set }
}
