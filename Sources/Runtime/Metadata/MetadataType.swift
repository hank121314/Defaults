import Foundation

protocol MetadataType: TypeInfoConvertible {
	associatedtype Layout: MetadataLayoutType

	var pointer: UnsafeMutablePointer<Layout> { get set }

	init(pointer: UnsafeMutablePointer<Layout>)
}

extension MetadataType {
	init(type: Any.Type) {
		self = Self(pointer: unsafeBitCast(type, to: UnsafeMutablePointer<Layout>.self))
	}
}
