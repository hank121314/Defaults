import Foundation

struct StructTypeDescriptor: TypeDescriptor {
	var flags: ContextDescriptorFlags
	var parent: Int32
	var mangledName: RelativePointer<Int32, CChar>
	var accessFunctionPtr: RelativePointer<Int32, UnsafeRawPointer>
	var fieldDescriptor: RelativePointer<Int32, FieldDescriptor>
	var numberOfFields: Int32
	var offsetToTheFieldOffsetVector: RelativeVectorPointer<Int32, Int32>
}
