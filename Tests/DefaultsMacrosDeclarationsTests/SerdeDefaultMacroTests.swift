import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import Defaults

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(DefaultsMacrosDeclarations)
	@testable import DefaultsMacros
	@testable import DefaultsMacrosDeclarations

	private let testMacros: [String: Macro.Type] = [
		"SerdeDefault": SerdeDefaultMacro.self,
		"serde": SerdeMacro.self
	]

	private enum Group {
		case standalone
	}

	private enum Role: String, Defaults.Serializable {
		case admin = "Admin"
		case guest = "Guest"
	}

	// @SerdeDefault
	// private struct User {
	// 	let name: String
	// 	let age: UInt?
	// 	let role: Role?
	// 	@serde(.skip)
	// 	let group: Group?
	// }
#else
	private let testMacros: [String: Macro.Type] = [:]
#endif

final class SerdeDefaultMacroTests: XCTestCase {
	private let suite = UserDefaults(suiteName: UUID().uuidString)!

	deinit {
		Defaults.removeAll(suite: suite)
	}

	func testExpansionWithMemberSyntax() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct User {
				var name: String
				var age: UInt
			}
			"""#,
			expandedSource: #"""
				struct User {
					var name: String
					var age: UInt
				}

				extension User: Defaults.Serializable {
					struct UserBridge: Defaults.Bridge, Sendable {
						typealias Value = User
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							let serialized: Serializable = ["name": value.name, "age": value.age]

							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							guard let name = __macro_local_10serializedfMu_["name"] as? String else {
								return nil
							}
							guard let age = __macro_local_10serializedfMu_["age"] as? UInt else {
								return nil
							}
							return User(name: name, age: age)
						}
					}
					static let bridge = UserBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionWithOptionalMemberType() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct User {
				var name: String
				var age: UInt?
			}
			"""#,
			expandedSource: #"""
				struct User {
					var name: String
					var age: UInt?
				}

				extension User: Defaults.Serializable {
					struct UserBridge: Defaults.Bridge, Sendable {
						typealias Value = User
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							var serialized: Serializable = ["name": value.name]
							if let __macro_local_3agefMu_ = value.age {
								serialized["age"] = __macro_local_3agefMu_
							}
							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							guard let name = __macro_local_10serializedfMu_["name"] as? String else {
								return nil
							}
							let age = __macro_local_10serializedfMu_["age"] as? UInt
							return User(name: name, age: age)
						}
					}
					static let bridge = UserBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionWithQualifiedSerdeAttribute() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct User {
				var name: String
				@DefaultsMacros.serde(.skip)
				var group: Group?
			}
			"""#,
			expandedSource: #"""
				struct User {
					var name: String
					@DefaultsMacros.serde(.skip)
					var group: Group?
				}

				extension User: Defaults.Serializable {
					struct UserBridge: Defaults.Bridge, Sendable {
						typealias Value = User
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							let serialized: Serializable = ["name": value.name]

							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							guard let name = __macro_local_10serializedfMu_["name"] as? String else {
								return nil
							}
							return User(name: name, group: nil)
						}
					}
					static let bridge = UserBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionWithQualifiedSerdeOptions() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct User {
				var name: String
				@serde(SerdeOption.skip)
				var group: Group?
				@serde(DefaultsMacros.SerdeOption.skip)
				var role: Role?
			}
			"""#,
			expandedSource: #"""
				struct User {
					var name: String
					var group: Group?
					var role: Role?
				}

				extension User: Defaults.Serializable {
					struct UserBridge: Defaults.Bridge, Sendable {
						typealias Value = User
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							let serialized: Serializable = ["name": value.name]

							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							guard let name = __macro_local_10serializedfMu_["name"] as? String else {
								return nil
							}
							return User(name: name, group: nil, role: nil)
						}
					}
					static let bridge = UserBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionKeepsDeserializeInitializerArgumentsTogether() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct User {
				var name: String
				@DefaultsMacros.serde(.skip)
				var group: Group?
				let version = 1
			}
			"""#,
			expandedSource: #"""
				struct User {
					var name: String
					@DefaultsMacros.serde(.skip)
					var group: Group?
					let version = 1
				}

				extension User: Defaults.Serializable {
					struct UserBridge: Defaults.Bridge, Sendable {
						typealias Value = User
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							let serialized: Serializable = ["name": value.name]

							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							guard let name = __macro_local_10serializedfMu_["name"] as? String else {
								return nil
							}
							return User(name: name, group: nil)
						}
					}
					static let bridge = UserBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionInfersLiteralMemberTypes() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct Settings {
				var name = "Alice"
				var isEnabled = true
				var count = 1
				var ratio = 0.5
			}
			"""#,
			expandedSource: #"""
				struct Settings {
					var name = "Alice"
					var isEnabled = true
					var count = 1
					var ratio = 0.5
				}

				extension Settings: Defaults.Serializable {
					struct SettingsBridge: Defaults.Bridge, Sendable {
						typealias Value = Settings
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							let serialized: Serializable = ["name": value.name, "isEnabled": value.isEnabled, "count": value.count, "ratio": value.ratio]

							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							let name = __macro_local_10serializedfMu_["name"] as? String ?? "Alice"
							let isEnabled = __macro_local_10serializedfMu_["isEnabled"] as? Bool ?? true
							let count = __macro_local_10serializedfMu_["count"] as? Int ?? 1
							let ratio = __macro_local_10serializedfMu_["ratio"] as? Double ?? 0.5
							return Settings(name: name, isEnabled: isEnabled, count: count, ratio: ratio)
						}
					}
					static let bridge = SettingsBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionInfersWrappedAndSignedLiteralMemberTypes() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct Settings {
				var negativeCount = -1
				var positiveRatio = +0.5
				var parenthesizedName = ("Alice")
			}
			"""#,
			expandedSource: #"""
				struct Settings {
					var negativeCount = -1
					var positiveRatio = +0.5
					var parenthesizedName = ("Alice")
				}

				extension Settings: Defaults.Serializable {
					struct SettingsBridge: Defaults.Bridge, Sendable {
						typealias Value = Settings
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							let serialized: Serializable = ["negativeCount": value.negativeCount, "positiveRatio": value.positiveRatio, "parenthesizedName": value.parenthesizedName]

							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							let negativeCount = __macro_local_10serializedfMu_["negativeCount"] as? Int ?? -1
							let positiveRatio = __macro_local_10serializedfMu_["positiveRatio"] as? Double ?? +0.5
							let parenthesizedName = __macro_local_10serializedfMu_["parenthesizedName"] as? String ?? ("Alice")
							return Settings(negativeCount: negativeCount, positiveRatio: positiveRatio, parenthesizedName: parenthesizedName)
						}
					}
					static let bridge = SettingsBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionInfersCollectionLiteralMemberTypes() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct Settings {
				var tags = ["swift"]
				var scores = ["home": 1]
			}
			"""#,
			expandedSource: #"""
				struct Settings {
					var tags = ["swift"]
					var scores = ["home": 1]
				}

				extension Settings: Defaults.Serializable {
					struct SettingsBridge: Defaults.Bridge, Sendable {
						typealias Value = Settings
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							let serialized: Serializable = ["tags": value.tags, "scores": value.scores]

							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							let tags = __macro_local_10serializedfMu_["tags"] as? [String] ?? ["swift"]
							let scores = __macro_local_10serializedfMu_["scores"] as? [String: Int] ?? ["home": 1]
							return Settings(tags: tags, scores: scores)
						}
					}
					static let bridge = SettingsBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionWithNonNativeMemberType() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct Profile {
				var name: String
				var role: Role
			}
			"""#,
			expandedSource: #"""
				struct Profile {
					var name: String
					var role: Role
				}

				extension Profile: Defaults.Serializable {
					struct ProfileBridge: Defaults.Bridge, Sendable {
						typealias Value = Profile
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							var serialized: Serializable = ["name": value.name]
							guard let __macro_local_4rolefMu_ = Role.toSerializable(value.role) else {
								return nil
							}
							serialized["role"] = __macro_local_4rolefMu_
							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							guard let name = __macro_local_10serializedfMu_["name"] as? String else {
								return nil
							}
							guard let role = Role.toValue(__macro_local_10serializedfMu_["role"] as Any, type: Role.self) else {
								return nil
							}
							return Profile(name: name, role: role)
						}
					}
					static let bridge = ProfileBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionWithOptionalNonNativeMemberType() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct Profile {
				var name: String
				var role: Role?
			}
			"""#,
			expandedSource: #"""
				struct Profile {
					var name: String
					var role: Role?
				}

				extension Profile: Defaults.Serializable {
					struct ProfileBridge: Defaults.Bridge, Sendable {
						typealias Value = Profile
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							var serialized: Serializable = ["name": value.name]
							if let __macro_local_4rolefMu_ = Role.toSerializable(value.role) {
								serialized["role"] = __macro_local_4rolefMu_
							}
							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							guard let name = __macro_local_10serializedfMu_["name"] as? String else {
								return nil
							}
							let role = Role.toValue(__macro_local_10serializedfMu_["role"] as Any, type: Role.self)
							return Profile(name: name, role: role)
						}
					}
					static let bridge = ProfileBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionUsesMatchingInitializerForMultiBindingDeclaration() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct Pair {
				var first: Int, second: Int = 1
			}
			"""#,
			expandedSource: #"""
				struct Pair {
					var first: Int, second: Int = 1
				}

				extension Pair: Defaults.Serializable {
					struct PairBridge: Defaults.Bridge, Sendable {
						typealias Value = Pair
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							let serialized: Serializable = ["first": value.first, "second": value.second]

							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							guard let first = __macro_local_10serializedfMu_["first"] as? Int else {
								return nil
							}
							let second = __macro_local_10serializedfMu_["second"] as? Int ?? 1
							return Pair(first: first, second: second)
						}
					}
					static let bridge = PairBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionIgnoresComputedProperties() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct User {
				var name: String
				var displayName: String {
					name.uppercased()
				}
			}
			"""#,
			expandedSource: #"""
				struct User {
					var name: String
					var displayName: String {
						name.uppercased()
					}
				}

				extension User: Defaults.Serializable {
					struct UserBridge: Defaults.Bridge, Sendable {
						typealias Value = User
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							let serialized: Serializable = ["name": value.name]

							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							guard let name = __macro_local_10serializedfMu_["name"] as? String else {
								return nil
							}
							return User(name: name)
						}
					}
					static let bridge = UserBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionDiagnosesSkipOnNonOptionalProperty() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct User {
				@serde(.skip)
				var name: String
			}
			"""#,
			expandedSource: #"""
				struct User {
					var name: String
				}
				"""#,
			diagnostics: [
				DiagnosticSpec(
					message: "Non-optional property is marked with `@serde(.skip)`, which is not supported. Please remove the `skip` argument or make the property optional.",
					line: 4,
					column: 6
				)
			],
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionDiagnosesGenericStruct() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct Box<T> {
				var value: T
			}
			"""#,
			expandedSource: #"""
				struct Box<T> {
					var value: T
				}
				"""#,
			diagnostics: [
				DiagnosticSpec(
					message: "`@SerdeDefault` does not support generic types. Apply it to a concrete struct instead.",
					line: 2,
					column: 11
				)
			],
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	/**
	A property named after one of the identifiers the generated `serialize` declares would
	shadow it, so the temporaries it binds have to be unique names.
	*/
	func testExpansionKeepsSerializeHygienicForCollidingPropertyNames() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct User {
				var serialized: String?
				var name: String
			}
			"""#,
			expandedSource: #"""
				struct User {
					var serialized: String?
					var name: String
				}

				extension User: Defaults.Serializable {
					struct UserBridge: Defaults.Bridge, Sendable {
						typealias Value = User
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							var serialized: Serializable = ["name": value.name]
							if let __macro_local_10serializedfMu0_ = value.serialized {
								serialized["serialized"] = __macro_local_10serializedfMu0_
							}
							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							let serialized = __macro_local_10serializedfMu_["serialized"] as? String
							guard let name = __macro_local_10serializedfMu_["name"] as? String else {
								return nil
							}
							return User(serialized: serialized, name: name)
						}
					}
					static let bridge = UserBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	func testExpansionUsesPropertyDefaultsWhenDeserializationReturnsNil() throws {
		assertMacroExpansion(
			#"""
			@SerdeDefault
			struct User {
				var name: String = "Anonymous"
				var role: Role = .guest
			}
			"""#,
			expandedSource: #"""
				struct User {
					var name: String = "Anonymous"
					var role: Role = .guest
				}

				extension User: Defaults.Serializable {
					struct UserBridge: Defaults.Bridge, Sendable {
						typealias Value = User
						typealias Serializable = [String: Any]
						public func serialize(_ value: Value?) -> Serializable? {
							guard let value else {
								return nil
							}
							var serialized: Serializable = ["name": value.name]
							guard let __macro_local_4rolefMu_ = Role.toSerializable(value.role) else {
								return nil
							}
							serialized["role"] = __macro_local_4rolefMu_
							return serialized
						}
						public func deserialize(_ __macro_local_10serializedfMu_: Serializable?) -> Value? {
							guard let __macro_local_10serializedfMu_ else {
								return nil
							}
							let name = __macro_local_10serializedfMu_["name"] as? String ?? "Anonymous"
							let role = Role.toValue(__macro_local_10serializedfMu_["role"] as Any, type: Role.self) ?? .guest
							return User(name: name, role: role)
						}
					}
					static let bridge = UserBridge()
				}
				"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	// func testDefaultsKeyUsage() throws {
	// 	#if canImport(DefaultsMacrosDeclarations)
	// 		let defaultUser = User(name: "Alice", age: 30, role: .admin, group: .standalone)
	// 		let key = Defaults.Key<User>("serdeDefaultsKeyUsage", default: defaultUser, suite: suite)
	// 		XCTAssertEqual(Defaults[key].name, defaultUser.name)
	// 		let newUser = User(name: "Bob", age: nil, role: .guest, group: .standalone)
	// 		Defaults[key] = newUser
	// 		XCTAssertEqual(Defaults[key].name, newUser.name)
	// 		XCTAssertEqual(Defaults[key].age, newUser.age)
	// 		XCTAssertEqual(Defaults[key].role, newUser.role)
	// 	#else
	// 		throw XCTSkip("Macros are only supported when running tests for the host platform")
	// 	#endif
	// }
}
