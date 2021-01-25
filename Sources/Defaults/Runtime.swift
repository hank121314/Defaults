import Foundation

public struct PropertyInfo {
	public let name: String
	public let type: Any.Type
	public let isVar: Bool
	public let offset: Int
	public let ownerType: Any.Type
}

func metadataPointer(type: Any.Type) -> UnsafeMutablePointer<Int> {
	return unsafeBitCast(type, to: UnsafeMutablePointer<Int>.self)
}

struct RelativePointer<Offset: FixedWidthInteger, Pointee> {
	var offset: Offset

	mutating func pointee() -> Pointee {
		return advanced().pointee
	}

	mutating func advanced() -> UnsafeMutablePointer<Pointee> {
		let offset = self.offset
		return withUnsafePointer(to: &self) { p in
			p.raw.advanced(by: numericCast(offset))
				.assumingMemoryBound(to: Pointee.self)
				.mutable
		}
	}
}

extension RelativePointer: CustomStringConvertible {
	var description: String {
		return "\(offset)"
	}
}

struct RelativeVectorPointer<Offset: FixedWidthInteger, Pointee> {
	var offset: Offset
	mutating func vector(metadata: UnsafePointer<Int>, n: Int) -> UnsafeBufferPointer<Pointee> {
		metadata.advanced(by: numericCast(offset)).raw.assumingMemoryBound(to: Pointee.self).buffer(n: n)
	}
}

extension RelativeVectorPointer: CustomStringConvertible {
	var description: String {
		return "\(offset)"
	}
}

struct StructMetadata {
	var kind: Int
	var ntd: RelativePointer<Int, StructTypeDescriptor>
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
		return (fieldRecordFlags & 0x2) == 0x2
	}

	mutating func fieldName() -> String {
		return String(cString: _fieldName.advanced())
	}

	mutating func type(genericContext: UnsafeRawPointer?,
	                   genericArguments: UnsafeRawPointer?) -> Any.Type
	{
		let typeName = _mangledTypeName.advanced()
		let metadataPtr = _getTypeByMangledNameInContext(
			typeName,
			getSymbolicMangledNameLength(typeName),
			genericContext: genericContext,
			genericArguments: genericArguments?.assumingMemoryBound(to: UnsafeRawPointer?.self))

		return unsafeBitCast(metadataPtr, to: Any.Type.self)
	}

	func getSymbolicMangledNameLength(_ base: UnsafeRawPointer) -> Int32 {
					var end = base
					while let current = Optional(end.load(as: UInt8.self)), current != 0 {
							end += 1
							if current >= 0x1 && current <= 0x17 {
									end += 4
							} else if current >= 0x18 && current <= 0x1F {
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
	var fields: [FieldRecord]
}

protocol MetadataType {
	associatedtype Layout: MetadataLayoutType

	var pointer: UnsafeMutablePointer<Layout> { get set }

	init(pointer: UnsafeMutablePointer<Layout>)
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
		return (pointer.pointee.typeDescriptor.pointee.flags & 0x80) != 0
	}

	mutating func mangledName() -> String {
		return String(cString: pointer.pointee.typeDescriptor.pointee.mangledName.advanced())
	}

	mutating func numberOfFields() -> Int {
		return Int(pointer.pointee.typeDescriptor.pointee.numberOfFields)
	}

	mutating func fieldOffsets() -> [Int] {
		return pointer.pointee.typeDescriptor.pointee
			.offsetToTheFieldOffsetVector
			.vector(metadata: pointer.raw.assumingMemoryBound(to: Int.self), n: numberOfFields())
			.map(numericCast)
	}

	mutating func properties() -> [PropertyInfo] {
		let offsets = fieldOffsets()
		let fieldDescriptor = pointer.pointee.typeDescriptor.pointee
			.fieldDescriptor
			.advanced()

		let genericVector = genericArgumentVector()

		return (0 ..< numberOfFields()).map { i in
			var record = fieldDescriptor
				.pointee
				.fields[i]

			return PropertyInfo(
				name: record.fieldName(),
				type: record.type(
					genericContext: pointer.pointee.typeDescriptor,
					genericArguments: genericVector
				),
				isVar: record.isVar,
				offset: offsets[i],
				ownerType: unsafeBitCast(pointer, to: Any.Type.self)
			)
		}
	}

	func genericArguments() -> UnsafeMutableBufferPointer<Any.Type> {
		guard isGeneric else { return .init(start: nil, count: 0) }

		let count = pointer.pointee
			.typeDescriptor
			.pointee
			.genericContextHeader
			.base
			.numberOfParams
		return genericArgumentVector().buffer(n: Int(count))
	}

	func genericArgumentVector() -> UnsafeMutablePointer<Any.Type> {
		return pointer
			.advanced(by: genericArgumentOffset, wordSize: MemoryLayout<UnsafeRawPointer>.size)
			.assumingMemoryBound(to: Any.Type.self)
	}
}
