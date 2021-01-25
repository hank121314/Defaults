import Foundation

struct ProtocolTypeContainer {
	let type: Any.Type
	let witnessTable: Int
}

struct AnyProtocol {
	let metadataAddress: Int
}

public struct PropertyInfo {
	public let name: String
	public let type: Any.Type
	public let isVar: Bool
	public let offset: Int
	public let ownerType: Any.Type
}

func metadataPointer(type: Any.Type) -> UnsafeMutablePointer<Int> {
	unsafeBitCast(type, to: UnsafeMutablePointer<Int>.self)
}

struct RelativePointer<Offset: FixedWidthInteger, Pointee> {
	var offset: Offset

	mutating func pointee() -> Pointee {
		advanced().pointee
	}

	mutating func advanced() -> UnsafeMutablePointer<Pointee> {
		let offset = self.offset
		return withUnsafePointer(to: &self) { pointer in
			pointer.raw.advanced(by: numericCast(offset))
				.assumingMemoryBound(to: Pointee.self)
				.mutable
		}
	}
}

extension RelativePointer: CustomStringConvertible {
	var description: String {
		"\(offset)"
	}
}

struct RelativeVectorPointer<Offset: FixedWidthInteger, Pointee> {
	var offset: Offset
	mutating func vector(metadata: UnsafePointer<Int>, count: Int) -> UnsafeBufferPointer<Pointee> {
		metadata.advanced(by: numericCast(offset)).raw.assumingMemoryBound(to: Pointee.self).buffer(count: count)
	}
}

extension RelativeVectorPointer: CustomStringConvertible {
	var description: String {
		"\(offset)"
	}
}

struct StructMetadata: NominalMetadataType {
	var pointer: UnsafeMutablePointer<StructMetadataLayout>
}

struct StructMetadataLayout: NominalMetadataLayoutType {
	var _kind: Int
	var typeDescriptor: UnsafeMutablePointer<StructTypeDescriptor>
}

typealias FieldTypeAccessor = @convention(c) (UnsafePointer<Int>) -> UnsafePointer<Int>

struct StructTypeDescriptor: TypeDescriptor {
	var flags: ContextDescriptorFlags
	var parent: Int32
	var mangledName: RelativePointer<Int32, CChar>
	var accessFunctionPtr: RelativePointer<Int32, UnsafeRawPointer>
	var fieldDescriptor: RelativePointer<Int32, FieldDescriptor>
	var numberOfFields: Int32
	var offsetToTheFieldOffsetVector: RelativeVectorPointer<Int32, Int32>
	var genericContextHeader: TargetTypeGenericContextDescriptorHeader
}

protocol TypeDescriptor {
	/// The offset type can differ between TypeDescriptors
	/// e.g. Struct are an Int32 and classes are an Int
	associatedtype FieldOffsetVectorOffsetType: FixedWidthInteger

	var flags: ContextDescriptorFlags { get set }
	var mangledName: RelativePointer<Int32, CChar> { get set }
	var fieldDescriptor: RelativePointer<Int32, FieldDescriptor> { get set }
	var numberOfFields: Int32 { get set }
	var offsetToTheFieldOffsetVector: RelativeVectorPointer<Int32, FieldOffsetVectorOffsetType> { get set }
	var genericContextHeader: TargetTypeGenericContextDescriptorHeader { get set }
}

typealias ContextDescriptorFlags = Int32

struct NominalTypeDescriptor {
	var mangledName: RelativePointer<Int32, CChar>
	var numberOfFields: Int32
	var offsetToTheFieldOffsets: RelativeVectorPointer<Int32, Int>
	var fieldNames: RelativePointer<Int32, CChar>
	var fieldTypeAccessor: RelativePointer<Int32, Int>
}

struct TargetTypeGenericContextDescriptorHeader {
	var instantiationCache: Int32
	var defaultInstantiationPattern: Int32
	var base: TargetGenericContextDescriptorHeader
}

struct TargetGenericContextDescriptorHeader {
	var numberOfParams: UInt16
	var numberOfRequirements: UInt16
	var numberOfKeyArguments: UInt16
	var numberOfExtraArguments: UInt16
}

struct FieldRecord {
	var fieldRecordFlags: Int32
	var _mangledTypeName: RelativePointer<Int32, Int8>
	var _fieldName: RelativePointer<Int32, UInt8>

	var isVar: Bool {
		(fieldRecordFlags & 0x2) == 0x2
	}

	mutating func fieldName() -> String {
		String(cString: _fieldName.advanced())
	}

	mutating func type(genericContext: UnsafeRawPointer?,
	                   genericArguments: UnsafeRawPointer?) -> Any.Type
	{
		let typeName = _mangledTypeName.advanced()
		let length = getSymbolicMangledNameLength(typeName)
		let arguments = genericArguments?.assumingMemoryBound(to: UnsafeRawPointer?.self)
		let metadataPtr = swift_getTypeByMangledNameInContext(typeName, length, genericContext, arguments)

		return unsafeBitCast(metadataPtr, to: Any.Type.self)
	}

	func getSymbolicMangledNameLength(_ base: UnsafeRawPointer) -> Int32 {
		var end = base
		while let current = Optional(end.load(as: UInt8.self)), current != 0 {
			end += 1
			if current >= 0x1, current <= 0x17 {
				end += 4
			} else if current >= 0x18, current <= 0x1f {
				end += MemoryLayout<Int>.size
			}
		}

		return Int32(end - base)
	}
}

struct FieldDescriptor {
	var mangledTypeNameOffset: Int32
	var superClassOffset: Int32
	var _kind: UInt16
	var fieldRecordSize: Int16
	var numFields: Int32
	var fields: Vector<FieldRecord>
}

protocol MetadataType {
	associatedtype Layout: MetadataLayoutType

	var pointer: UnsafeMutablePointer<Layout> { get set }

	init(pointer: UnsafeMutablePointer<Layout>)
}

extension MetadataType {
	init(type: Any.Type) {
		self = Self(pointer: unsafeBitCast(type, to: UnsafeMutablePointer<Layout>.self))
	}
}

protocol MetadataLayoutType {
	var _kind: Int { get set }
}

protocol NominalMetadataLayoutType: MetadataLayoutType {
	associatedtype Descriptor: TypeDescriptor
	var typeDescriptor: UnsafeMutablePointer<Descriptor> { get set }
}

protocol NominalMetadataType: MetadataType where Layout: NominalMetadataLayoutType {
	/// The offset of the generic type vector in pointer sized words from the
	/// start of the metadata record.
	var genericArgumentOffset: Int { get }
}

extension NominalMetadataType {
	var genericArgumentOffset: Int {
		// default to 2. This would put it right after the type descriptor which is valid
		// for all types except for classes
		return 2
	}

	var isGeneric: Bool {
		(pointer.pointee.typeDescriptor.pointee.flags & 0x80) != 0
	}

	mutating func mangledName() -> String {
		String(cString: pointer.pointee.typeDescriptor.pointee.mangledName.advanced())
	}

	mutating func numberOfFields() -> Int {
		Int(pointer.pointee.typeDescriptor.pointee.numberOfFields)
	}

	mutating func fieldOffsets() -> [Int] {
		pointer.pointee.typeDescriptor.pointee
			.offsetToTheFieldOffsetVector
			.vector(metadata: pointer.raw.assumingMemoryBound(to: Int.self), count: numberOfFields())
			.map(numericCast)
	}

	mutating func properties() -> [PropertyInfo] {
		let offsets = fieldOffsets()
		let fieldDescriptor = pointer.pointee.typeDescriptor.pointee
			.fieldDescriptor
			.advanced()

		let genericVector = genericArgumentVector()

		return (0 ..< numberOfFields()).map { index in
			let record = fieldDescriptor
				.pointee
				.fields
				.element(at: index)

			return PropertyInfo(
				name: record.pointee.fieldName(),
				type: record.pointee.type(
					genericContext: pointer.pointee.typeDescriptor,
					genericArguments: genericVector
				),
				isVar: record.pointee.isVar,
				offset: offsets[index],
				ownerType: unsafeBitCast(pointer, to: Any.Type.self)
			)
		}
	}

	func genericArguments() -> UnsafeMutableBufferPointer<Any.Type> {
		guard isGeneric else {
			return .init(start: nil, count: 0)
		}

		let count = pointer.pointee
			.typeDescriptor
			.pointee
			.genericContextHeader
			.base
			.numberOfParams
		return genericArgumentVector().buffer(count: Int(count))
	}

	func genericArgumentVector() -> UnsafeMutablePointer<Any.Type> {
		pointer
			.advanced(by: genericArgumentOffset, wordSize: MemoryLayout<UnsafeRawPointer>.size)
			.assumingMemoryBound(to: Any.Type.self)
	}
}

struct Vector<Element> {
	var element: Element

	mutating func vector(count: Int) -> UnsafeBufferPointer<Element> {
		withUnsafePointer(to: &self) {
			$0.withMemoryRebound(to: Element.self, capacity: 1) { start in
				start.buffer(count: count)
			}
		}
	}

	mutating func element(at index: Int) -> UnsafeMutablePointer<Element> {
		withUnsafePointer(to: &self) {
			$0.raw.assumingMemoryBound(to: Element.self).advanced(by: index).mutable
		}
	}
}

protocol Setters {}
extension Setters {
	static func set(value: Any, pointer: UnsafeMutableRawPointer, initialize: Bool = false) {
		if let value = value as? Self {
			let boundPointer = pointer.assumingMemoryBound(to: self)
			if initialize {
				boundPointer.initialize(to: value)
			} else {
				boundPointer.pointee = value
			}
		}
	}
}

func setters(type: Any.Type) -> Setters.Type {
	let container = ProtocolTypeContainer(type: type, witnessTable: 0)
	return unsafeBitCast(container, to: Setters.Type.self)
}
