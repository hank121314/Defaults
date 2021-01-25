import Foundation

@_silgen_name("swift_getTypeByMangledNameInContext")
func swift_getTypeByMangledNameInContext(
		_ typeNameStart: UnsafeMutablePointer<Int8>,
		_ typeNameLength: Int32,
		_ context: UnsafeRawPointer?,
		_ genericArgs: UnsafePointer<UnsafeRawPointer?>?
) -> UnsafeRawPointer?
