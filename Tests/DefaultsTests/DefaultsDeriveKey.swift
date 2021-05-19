import Foundation
import XCTest
import Defaults

extension Defaults.Keys {
  static let name = Defaults.Key<String>("name", default: "hank121314")
  static let email = Defaults.Key<String>("email", default: "hank121314@gmail.com")
  static let hasFilledOutAllFields = Defaults.DeriveKey<Bool, String>(deriveFrom: .name, .email) { email, name in
    !email.isEmpty && !name.isEmpty
  }

}

final class DefaultsDeriveKeyTests: XCTestCase {
  override func setUp() {
    super.setUp()
    Defaults.removeAll()
  }

  override func tearDown() {
    super.tearDown()
    Defaults.removeAll()
  }

  func testKey() {
    struct User {
      let name: String
      let email: String
    }
    let name = Defaults.Key<String>("independentName", default: "hank121314")
    let email = Defaults.Key<String>("independentEmail", default: "hank121314@gmail.com")
    let user = Defaults.DeriveKey<User, String>(deriveFrom: name, email) { name, email in
      User(name: name, email: email)
    }
    XCTAssertEqual("hank121314", Defaults[user].name)
    XCTAssertEqual("hank121314@gmail.com", Defaults[user].email)
  }
}
