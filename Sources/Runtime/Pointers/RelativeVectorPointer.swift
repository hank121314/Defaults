struct RelativeVectorPointer<Offset: FixedWidthInteger, Pointee> {
	var offset: Offset

	mutating func vector(metadata: UnsafePointer<Int>, count: Int) -> UnsafeBufferPointer<Pointee> {
		metadata.advanced(by: numericCast(offset))
			.raw.assumingMemoryBound(to: Pointee.self)
			.buffer(count: count)
	}
}
