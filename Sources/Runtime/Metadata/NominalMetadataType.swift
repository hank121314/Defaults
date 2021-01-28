protocol NominalMetadataType: MetadataType where Layout: NominalMetadataLayoutType {
	/// The offset of the generic type vector in pointer sized words from the
	/// start of the metadata record.
	var genericArgumentOffset: Int { get }
}

extension NominalMetadataType {
	var genericArgumentOffset: Int {
		// default to 2. This would put it right after the type descriptor which is valid
		// for all types except for classes
		2
	}

	var typeDescriptor: UnsafeMutablePointer<Layout.Descriptor> {
		pointer.pointee.typeDescriptor
	}

	mutating func mangledName() -> String {
		String(cString: typeDescriptor.pointee.mangledName.advanced())
	}

	mutating func numberOfFields() -> Int {
		Int(typeDescriptor.pointee.numberOfFields)
	}

	mutating func fieldOffsets() -> [Int] {
		typeDescriptor.pointee
			.offsetToTheFieldOffsetVector
			.vector(metadata: pointer.raw.assumingMemoryBound(to: Int.self), count: numberOfFields())
			.map(numericCast)
	}

	mutating func properties() -> [PropertyInfo] {
		let offsets = fieldOffsets()
		let fieldDescriptor = typeDescriptor.pointee
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
					genericContext: typeDescriptor,
					genericArguments: genericVector
				),
				isVar: record.pointee.isVar,
				offset: offsets[index],
				ownerType: unsafeBitCast(pointer, to: Any.Type.self)
			)
		}
	}

	func genericArgumentVector() -> UnsafeMutablePointer<Any.Type> {
		pointer
			.advanced(by: genericArgumentOffset, wordSize: MemoryLayout<UnsafeRawPointer>.size)
			.assumingMemoryBound(to: Any.Type.self)
	}
}
