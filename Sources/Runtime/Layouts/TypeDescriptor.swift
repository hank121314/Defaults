protocol TypeDescriptor {
	/// The offset type can differ between TypeDescriptors
	/// e.g. Struct are an Int32 and classes are an Int
	associatedtype FieldOffsetVectorOffsetType: FixedWidthInteger

	/// The kind of type is stored at offset 0
	var flags: ContextDescriptorFlags { get set }
	/// The mangled name is referenced as a null-terminated C string at offset 1. This name includes no bound generic parameters.
	var mangledName: RelativePointer<Int32, CChar> { get set }
	/**
	For a struct or class:
	The number of fields is stored at offset 2.This is the length of the field offset vector in the metadata record, if any.
	*/
	var numberOfFields: Int32 { get set }
	var offsetToTheFieldOffsetVector: RelativeVectorPointer<Int32, FieldOffsetVectorOffsetType> { get set }
	var fieldDescriptor: RelativePointer<Int32, FieldDescriptor> { get set }
}

typealias ContextDescriptorFlags = Int32
