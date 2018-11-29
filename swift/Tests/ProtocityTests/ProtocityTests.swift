import XCTest
import Swinject
import SwinjectAutoregistration
import SwiftProtobuf
import NIO

@testable import Protocity

final class ProtocityTests: XCTestCase {
    var c: Container = Container()
    
    override func setUp() {
        c = Container()
        c.register(EventLoopGroup.self) { _ in MultiThreadedEventLoopGroup(numberOfThreads: 4) }
        c.autoregister(RawStorage.self, initializer: MemoryStorage.init)
        Example_Binder.bind(c)
    }
    
    override func tearDown() {
        try! c.resolve(RawStorage.self)!.shutdown()
        try! c.resolve(EventLoopGroup.self)!.syncShutdownGracefully()
    }
    
    func testCanBind() {
    }
    
    func testFindOne() throws {
        let repo = c.resolve(Example_User.repository())!
        let user = Example_User.with { $0.id = "kyle" }
        try repo.save(user).wait()
        let saved = try repo.findById("kyle").wait()
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
        try repo.save(a, b).wait()
        let saved = try repo.findById([a.id, b.id, "unknown"]).wait()
        XCTAssertEqual(saved, [a, b, nil])
    }
    
    func testFindBySecondary() throws {
        let repo = c.resolve(Example_User.repository())!
        let a = Example_User.with { $0.login = "kyle" }
        let b = Example_User.with { $0.login = "bob" }
        try repo.save(a, b).wait()
        let saved = try repo.findByLogin([a.login, b.login, "unknown"]).wait()
        XCTAssertEqual(saved, [a, b, nil])
    }
    
    func testUniqueConstraint() throws {
        let repo = c.resolve(Example_User.repository())!
        let a = Example_User.with { $0.login = "kyle" }
        let b = Example_User.with { $0.login = "kyle" }
        XCTAssertThrowsError(try repo.save(a,  b).wait())
    }
    
    func testCompositeKey() throws {
        let repo = c.resolve(Example_Message.repository())!
        let time = Google_Protobuf_Timestamp(date: Date())
        let message = Example_Message.with {
            $0.sentAt = time
            $0.fromUserID = "bob"
        }
        try repo.save(message).wait()
        let saved = try repo.findBySenderTime("bob", time).wait()
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
        try repo.save(message).wait()
        let saved = try repo.findBySenderTime(fromUserID: "bob").wait()
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].fromUserID, "bob")
    }
}
