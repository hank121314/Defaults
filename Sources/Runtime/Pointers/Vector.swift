import Foundation

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
