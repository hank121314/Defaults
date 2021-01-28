import Foundation

struct FieldDescriptor {
	var mangledTypeNameOffset: Int32
	var superClassOffset: Int32
	var _kind: UInt16
	var fieldRecordSize: Int16
	var numFields: Int32
	var fields: Vector<FieldRecord>

	var kind: FieldDescriptorKind {
		FieldDescriptorKind(rawValue: _kind)!
	}
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

	mutating func type(
		genericContext: UnsafeRawPointer?,
		genericArguments: UnsafeRawPointer?
	) -> Any.Type {
		let typeName = _mangledTypeName.advanced()
		let metadataPtr = swift_getTypeByMangledNameInContext(
			typeName,
			getSymbolicMangledNameLength(typeName),
			genericContext,
			genericArguments?.assumingMemoryBound(to: UnsafeRawPointer?.self)
		)!

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

enum FieldDescriptorKind: UInt16 {
	case `struct`
	case `class`
}
