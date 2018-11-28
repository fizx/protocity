import XCTest
import Swinject
import SwinjectAutoregistration
import Promises
import SwiftProtobuf
@testable import Protocity

final class ProtocityTests: XCTestCase {
    var c: Container = Container()
    
    override func setUp() {
        DispatchQueue.promises = .global()
        c.autoregister(RawStorage.self, initializer: MemoryStorage.init)
        Example_Binder.bind(c)
    }
    
    func testCanBind() {
    }
    
    func testFindOne() throws {
        let repo = c.resolve(Example_User.repository())!
        let user = Example_User.with { $0.id = "kyle" }
        try await(repo.save(user))
        let saved = try await(repo.findById("kyle"))
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.id, user.id)
    }
    
    func testUUID() throws {
        let a = Example_User.with {
            $0.login = "bob"
        }
        XCTAssertEqual(a.id.count, 36)
    }
    
    func testFindAll() throws {
        let repo = c.resolve(Example_User.repository())!
        let a = Example_User.with { $0.id = "kyle" }
        let b = Example_User.with { $0.id = "kyle" }
        try await(repo.save(a, b))
        let saved = try await(repo.findById([a.id, b.id, "unknown"]))
        XCTAssertEqual(saved, [a, b, nil])
    }
    
    func testFindBySecondary() throws {
        let repo = c.resolve(Example_User.repository())!
        let a = Example_User.with { $0.login = "kyle" }
        let b = Example_User.with { $0.login = "bob" }
        try await(repo.save(a, b))
        let saved = try await(repo.findByLogin([a.login, b.login, "unknown"]))
        XCTAssertEqual(saved, [a, b, nil])
    }
    
    func testUniqueConstraint() throws {
        let repo = c.resolve(Example_User.repository())!
        let a = Example_User.with { $0.login = "kyle" }
        let b = Example_User.with { $0.login = "kyle" }
        XCTAssertThrowsError(try await(repo.save(a,  b)))
    }
    
    func testCompositeKey() throws {
        let repo = c.resolve(Example_Message.repository())!
        let time = Google_Protobuf_Timestamp(date: Date())
        let message = Example_Message.with {
            $0.sentAt = time
            $0.fromUserID = "bob"
        }
        try await(repo.save(message))
        let saved = try await(repo.findBySenderTime("bob", time))
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.fromUserID, "bob")
    }
    func testPartialCompositeKey() throws {
        let repo = c.resolve(Example_Message.repository())!
        let time = Google_Protobuf_Timestamp(date: Date())
        let message = Example_Message.with {
            $0.sentAt = time
            $0.fromUserID = "bob"
        }
        try await(repo.save(message))
        let saved = try await(repo.findBySenderTime(fromUserID: "bob"))
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].fromUserID, "bob")
    }
}
