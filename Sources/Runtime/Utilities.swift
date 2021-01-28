import Foundation

extension UnsafePointer {
	var raw: UnsafeRawPointer {
		UnsafeRawPointer(self)
	}

	var mutable: UnsafeMutablePointer<Pointee> {
		UnsafeMutablePointer<Pointee>(mutating: self)
	}

	func buffer(count: Int) -> UnsafeBufferPointer<Pointee> {
		UnsafeBufferPointer(start: self, count: count)
	}
}

extension UnsafeMutablePointer {
	var raw: UnsafeMutableRawPointer {
		UnsafeMutableRawPointer(self)
	}

	func buffer(count: Int) -> UnsafeMutableBufferPointer<Pointee> {
		UnsafeMutableBufferPointer(start: self, count: count)
	}

	func advanced(by count: Int, wordSize: Int) -> UnsafeMutableRawPointer {
		self.raw.advanced(by: count * wordSize)
	}
}
