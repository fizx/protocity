import Foundation
import NIO
import Protocity
import SwiftProtobuf
import Swinject
import SwinjectAutoregistration

class Example_UserRepository: Repository<Example_User> {
    override func constructor(data: Data) -> Example_User? {
        return try? Example_User(serializedData: data)
    }

    // Single
    func findById(_ key: String) -> EventLoopFuture<Example_User?> {
        return _find(Keys.make("Example_User", "id", string: key))
    }

    // Multi
    func findById(_ keys: [String]) -> EventLoopFuture<[Example_User?]> {
        return _find(keys.map { key in Keys.make("Example_User", "id", string: key) })
    }

    // Range
    func findByIds(_ range: Range<String>, limit: Int = Int.max) -> EventLoopFuture<[Example_User]> {
        let lb = Keys.make("Example_User", "id", string: range.lowerBound)
        let ub = Keys.make("Example_User", "id", string: range.upperBound)
        return _find(lb ..< ub, limit: limit)
    }

    // Single
    func findByLogin(_ key: String) -> EventLoopFuture<Example_User?> {
        return _indirectFind(Keys.make("Example_User", "login", string: key))
    }

    // Multi
    func findByLogin(_ keys: [String]) -> EventLoopFuture<[Example_User?]> {
        return _indirectFind(keys.map { key in Keys.make("Example_User", "login", string: key) })
    }

    // Range
    func findByLogins(_ range: Range<String>, limit: Int = Int.max) -> EventLoopFuture<[Example_User]> {
        let lb = Keys.make("Example_User", "login", string: range.lowerBound)
        let ub = Keys.make("Example_User", "login", string: range.upperBound)
        return _indirectFind(lb ..< ub, limit: limit)
    }
}

extension Example_User: StorageMappable {
    public static func with(
        _ populator: (inout Example_User) throws -> Void
    ) rethrows -> Example_User {
        var message = Example_User()
        message.id = UUID().uuidString
        try populator(&message)
        return message
    }

    func toValue() -> Data {
        return try! serializedData()
    }

    func primaryIndex() -> Protocity_StorageKey {
        return Keys.make("Example_User", "id", string: id)
    }

    func secondaryIndexes() -> [Protocity_StorageKey] {
        var indexes: [Protocity_StorageKey] = []

        indexes.append(Keys.make("Example_User", "login", string: login))

        return indexes
    }

    static func repository() -> Example_UserRepository.Type {
        return Example_UserRepository.self
    }
}

class Example_AccountRepository: Repository<Example_Account> {
    override func constructor(data: Data) -> Example_Account? {
        return try? Example_Account(serializedData: data)
    }

    // Single
    func findById(_ key: String) -> EventLoopFuture<Example_Account?> {
        return _find(Keys.make("Example_Account", "id", string: key))
    }

    // Multi
    func findById(_ keys: [String]) -> EventLoopFuture<[Example_Account?]> {
        return _find(keys.map { key in Keys.make("Example_Account", "id", string: key) })
    }

    // Range
    func findByIds(_ range: Range<String>, limit: Int = Int.max) -> EventLoopFuture<[Example_Account]> {
        let lb = Keys.make("Example_Account", "id", string: range.lowerBound)
        let ub = Keys.make("Example_Account", "id", string: range.upperBound)
        return _find(lb ..< ub, limit: limit)
    }
}

extension Example_Account: StorageMappable {
    public static func with(
        _ populator: (inout Example_Account) throws -> Void
    ) rethrows -> Example_Account {
        var message = Example_Account()
        message.id = UUID().uuidString
        try populator(&message)
        return message
    }

    func toValue() -> Data {
        return try! serializedData()
    }

    func primaryIndex() -> Protocity_StorageKey {
        return Keys.make("Example_Account", "id", string: id)
    }

    func secondaryIndexes() -> [Protocity_StorageKey] {
        var indexes: [Protocity_StorageKey] = []

        return indexes
    }

    static func repository() -> Example_AccountRepository.Type {
        return Example_AccountRepository.self
    }
}

class Example_MessageRepository: Repository<Example_Message> {
    override func constructor(data: Data) -> Example_Message? {
        return try? Example_Message(serializedData: data)
    }

    // Single
    func findById(_ key: String) -> EventLoopFuture<Example_Message?> {
        return _find(Keys.make("Example_Message", "id", string: key))
    }

    // Multi
    func findById(_ keys: [String]) -> EventLoopFuture<[Example_Message?]> {
        return _find(keys.map { key in Keys.make("Example_Message", "id", string: key) })
    }

    // Range
    func findByIds(_ range: Range<String>, limit: Int = Int.max) -> EventLoopFuture<[Example_Message]> {
        let lb = Keys.make("Example_Message", "id", string: range.lowerBound)
        let ub = Keys.make("Example_Message", "id", string: range.upperBound)
        return _find(lb ..< ub, limit: limit)
    }

    // full exact match
    func findBySenderTime(_ from_user_id: String, _ sent_at: Google_Protobuf_Timestamp) -> EventLoopFuture<Example_Message?> {
        return _indirectFind(Keys.make("Example_Message", "sender_time", Protocity_Key.with { $0.string = from_user_id }, Protocity_Key.with { $0.timestamp = sent_at }))
    }

    // full exact match
    func findByRecipientTime(_ to_user_id: String, _ sent_at: Google_Protobuf_Timestamp) -> EventLoopFuture<Example_Message?> {
        return _indirectFind(Keys.make("Example_Message", "recipient_time", Protocity_Key.with { $0.string = to_user_id }, Protocity_Key.with { $0.timestamp = sent_at }))
    }

    func findBySenderTime(fromUserID: String, limit: Int = Int.max) -> EventLoopFuture<[Example_Message]> {
        let lowerBound = Keys.make("Example_Message", "sender_time", Protocity_Key.with { $0.string = fromUserID })
        let upperBound = Keys.make("Example_Message", "sender_time", Protocity_Key.with { $0.string = fromUserID }
                                   ,
                                   Protocity_Key.with { $0.bytes = Data(repeating: 255, count: 16) })
        return _indirectFind(lowerBound ..< upperBound, limit: limit)
    }

    func findByRecipientTime(toUserID: String, limit: Int = Int.max) -> EventLoopFuture<[Example_Message]> {
        let lowerBound = Keys.make("Example_Message", "recipient_time", Protocity_Key.with { $0.string = toUserID })
        let upperBound = Keys.make("Example_Message", "recipient_time", Protocity_Key.with { $0.string = toUserID }
                                   ,
                                   Protocity_Key.with { $0.bytes = Data(repeating: 255, count: 16) })
        return _indirectFind(lowerBound ..< upperBound, limit: limit)
    }
}

extension Example_Message: StorageMappable {
    public static func with(
        _ populator: (inout Example_Message) throws -> Void
    ) rethrows -> Example_Message {
        var message = Example_Message()
        message.id = UUID().uuidString
        try populator(&message)
        return message
    }

    func toValue() -> Data {
        return try! serializedData()
    }

    func primaryIndex() -> Protocity_StorageKey {
        return Keys.make("Example_Message", "id", string: id)
    }

    func secondaryIndexes() -> [Protocity_StorageKey] {
        var indexes: [Protocity_StorageKey] = []

        indexes.append(Keys.make("Example_Message", "sender_time", Protocity_Key.with { $0.string = self.fromUserID }, Protocity_Key.with { $0.timestamp = self.sentAt }))

        indexes.append(Keys.make("Example_Message", "recipient_time", Protocity_Key.with { $0.string = self.toUserID }, Protocity_Key.with { $0.timestamp = self.sentAt }))

        return indexes
    }

    static func repository() -> Example_MessageRepository.Type {
        return Example_MessageRepository.self
    }
}

class Example_PhotoRepository: Repository<Example_Photo> {
    override func constructor(data: Data) -> Example_Photo? {
        return try? Example_Photo(serializedData: data)
    }

    // Single
    func findById(_ key: String) -> EventLoopFuture<Example_Photo?> {
        return _find(Keys.make("Example_Photo", "id", string: key))
    }

    // Multi
    func findById(_ keys: [String]) -> EventLoopFuture<[Example_Photo?]> {
        return _find(keys.map { key in Keys.make("Example_Photo", "id", string: key) })
    }

    // Range
    func findByIds(_ range: Range<String>, limit: Int = Int.max) -> EventLoopFuture<[Example_Photo]> {
        let lb = Keys.make("Example_Photo", "id", string: range.lowerBound)
        let ub = Keys.make("Example_Photo", "id", string: range.upperBound)
        return _find(lb ..< ub, limit: limit)
    }
}

extension Example_Photo: StorageMappable {
    public static func with(
        _ populator: (inout Example_Photo) throws -> Void
    ) rethrows -> Example_Photo {
        var message = Example_Photo()
        message.id = UUID().uuidString
        try populator(&message)
        return message
    }

    func toValue() -> Data {
        return try! serializedData()
    }

    func primaryIndex() -> Protocity_StorageKey {
        return Keys.make("Example_Photo", "id", string: id)
    }

    func secondaryIndexes() -> [Protocity_StorageKey] {
        var indexes: [Protocity_StorageKey] = []

        return indexes
    }

    static func repository() -> Example_PhotoRepository.Type {
        return Example_PhotoRepository.self
    }
}

class Example_Binder {
    static func bind(_ container: Container) {
        container.autoregister(Example_UserRepository.self, initializer: Example_UserRepository.init)

        container.autoregister(Example_AccountRepository.self, initializer: Example_AccountRepository.init)

        container.autoregister(Example_MessageRepository.self, initializer: Example_MessageRepository.init)

        container.autoregister(Example_PhotoRepository.self, initializer: Example_PhotoRepository.init)
    }
}
