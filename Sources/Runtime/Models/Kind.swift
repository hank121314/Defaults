enum Kind {
	case `struct`
	case `class`
	init(type: Any.Type) {
		let pointer = unsafeBitCast(type, to: UnsafeMutablePointer<Int>.self)
		let flag = pointer.pointee
		switch flag {
		case 0x200:
			self = .struct // 0 | nonHeap
		default:
			self = .class // 0
		}
	}
}
