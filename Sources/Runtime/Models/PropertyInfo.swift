import Foundation

struct PropertyInfo {
	let name: String
	let type: Any.Type
	let isVar: Bool
	let offset: Int
	let ownerType: Any.Type
}
