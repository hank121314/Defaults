struct RelativePointer<Offset: FixedWidthInteger, Pointee> {
	var offset: Offset

	mutating func pointee() -> Pointee {
		advanced().pointee
	}

	mutating func advanced() -> UnsafeMutablePointer<Pointee> {
		withUnsafePointer(to: &self) { [offset] pointer in
			pointer.raw.advanced(by: numericCast(offset)).assumingMemoryBound(to: Pointee.self).mutable
		}
	}
}
