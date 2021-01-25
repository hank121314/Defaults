import Foundation

@_silgen_name("swift_getTypeByMangledNameInContext")
public func _getTypeByMangledNameInContext(
		_ name: UnsafePointer<UInt8>,
		_ nameLength: Int,
		genericContext: UnsafeRawPointer?,
		genericArguments: UnsafeRawPointer?)
		-> Any.Type?
