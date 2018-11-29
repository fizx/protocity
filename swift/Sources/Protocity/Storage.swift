import Algorithm
import Foundation
import NIO

protocol StorageMappable {
    func toValue() -> Data
    func primaryIndex() -> Protocity_StorageKey
    func secondaryIndexes() -> [Protocity_StorageKey]
}

protocol RawStorage {
    func loop() -> EventLoop
    func get(key: Protocity_StorageKey) -> EventLoopFuture<Data?>
    func get(keys: [Protocity_StorageKey]) -> EventLoopFuture<[Data?]>
    func range(from: Protocity_StorageKey, to: Protocity_StorageKey, limit: Int) -> EventLoopFuture<[Data]>
    func put(pairs: [(Protocity_StorageKey, Data)]) -> EventLoopFuture<Void>
    func put(key: Protocity_StorageKey, value: Data) -> EventLoopFuture<Void>
    func remove(keys: [Protocity_StorageKey]) -> EventLoopFuture<Void>
    func transactionally(transaction: @escaping (RawStorage) -> EventLoopFuture<Void>) -> EventLoopFuture<Void>
    func shutdown() throws -> ()
}

extension RawStorage {
    func put(key: Protocity_StorageKey, value: Data) -> EventLoopFuture<Void> {
        return self.put(pairs: [(key, value)])
    }
    
    func get(key: Protocity_StorageKey) -> EventLoopFuture<Data?> {
        return self.get(keys: [key]).map { $0[0] }
    }
}

struct Keys {
    static func make(_ namespace: String, _ subspace: String, string: String) -> Protocity_StorageKey {
        let key = Protocity_Key.with { $0.string = string }
        return make(namespace, subspace, key)
    }
    
    static func make(_ namespace: String, _ subspace: String, bytes: Data) -> Protocity_StorageKey {
        let key = Protocity_Key.with { $0.bytes = bytes }
        return make(namespace, subspace, key)
    }
    
    static func make(_ namespace: String, _ subspace: String, _ key: Protocity_Key...) -> Protocity_StorageKey {
        return Protocity_StorageKey.with{
            $0.namespace = namespace
            $0.subspace = subspace;
            $0.key = key
        }
    }
}


extension Protocity_StorageKey: Comparable {
    static func < (lhs: Protocity_StorageKey, rhs: Protocity_StorageKey) -> Bool {
        let a = [UInt8](try! lhs.serializedData())
        let b = [UInt8](try! rhs.serializedData())
        for (l, r) in zip(a, b) {
            if (l < r) {
                return true
            } else if (l > r) {
                return false
            }
        }
        return a.count < b.count
    }
}

class MemoryStorage: RawStorage {
    let transactions = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
    let loops: EventLoopGroup
    var raw = SortedDictionary<Protocity_StorageKey, Data>()
    var version = 0
    var refCount: [Int: Int] = [:]
    var changedKeys: [Int: Set<Protocity_StorageKey>] = [:]
    
    func shutdown() throws -> () {
        try transactions.syncShutdownGracefully()
    }
    
    init(loops: EventLoopGroup) {
        self.loops = loops
    }
    
    func loop() -> EventLoop {
        return self.loops.next()
    }
    
    func get(keys: [Protocity_StorageKey]) -> EventLoopFuture<[Data?]> {
        return loop().newSucceededFuture(result: keys.map { raw.findValue(for: $0) })
    }
    
    func range(from: Protocity_StorageKey, to: Protocity_StorageKey, limit: Int) -> EventLoopFuture<[Data]> {
        var answers: [Data] = []
        for key in raw.keys {
            if key < from || key >= to || answers.count == limit {
                continue
            }
            if let value = raw.findValue(for: key) {
                answers.append(value)
            }
        }
        return loop().newSucceededFuture(result: answers)
    }
    
    func put(pairs: [(Protocity_StorageKey, Data)]) -> EventLoopFuture<Void> {
        return self.transactionally { transaction in
            return transaction.put(pairs: pairs)
        }
    }
    
    func remove(keys: [Protocity_StorageKey]) -> EventLoopFuture<Void> {
        return self.transactionally { transaction in
            transaction.remove(keys: keys)
        }
    }
    
    func newTransactionStore() -> EventLoopFuture<TransactionStore> {
        let p: EventLoopPromise<TransactionStore> = loop().newPromise()
        self.transactions.submit {
            self.refCount[self.version] = (self.refCount[self.version] ?? 0) + 1
            var snapshot = SortedDictionary<Protocity_StorageKey, Data>()
            for (k, v) in self.raw {
                snapshot[k] = v
            }
            p.succeed(result: TransactionStore(inner: self, snapshot: snapshot, readVersion: self.version))
        }
        return p.futureResult
    }
    
    func transactionally(transaction: @escaping (RawStorage) -> EventLoopFuture<Void>) -> EventLoopFuture<Void> {
        return newTransactionStore().then { store -> EventLoopFuture<Void> in
            return transaction(store).then { _ -> EventLoopFuture<Void> in
                return store.commit()
            }.thenIfError { e -> EventLoopFuture<Void> in
                return store.rollback().then { x in
                    self.loop().newFailedFuture(error: e)
                }
            }
        }
    }
}

protocol Op {
    var key: Protocity_StorageKey { get set }
}

class TransactionStore: RawStorage {
    let inner: MemoryStorage
    var snapshot: SortedDictionary<Protocity_StorageKey, Data>
    let readVersion: Int
    var writes: [Op] = []
    
    struct UpdateOp: Op {
        var key: Protocity_StorageKey
        var value: Data
    }
    
    func shutdown() throws -> () {
    }

    struct RemoveOp: Op {
        var key: Protocity_StorageKey
    }
    
    func loop() -> EventLoop {
        return inner.loop()
    }
    
    func rollback() -> EventLoopFuture<Void> {
        let p: EventLoopPromise<Void> = inner.loop().newPromise()
        inner.transactions.submit {
            self.inner.refCount[self.readVersion]! -= 1
            p.succeed(result: ())
        }
        return p.futureResult
    }
    
    private func checkForConflicts() throws {
        var conflictableKeys: Set<Protocity_StorageKey> = []
        
        for i in (readVersion + 1)..<(inner.version + 1) {
            for key in inner.changedKeys[i] ?? [] {
                conflictableKeys.insert(key)
            }
        }
        
        var newlyChangedKeys: Set<Protocity_StorageKey> = []
        for op in writes {
            newlyChangedKeys.insert(op.key)
        }
        if conflictableKeys.intersection(newlyChangedKeys).count > 0 {
            throw Conflict()
        }
        inner.version += 1
        inner.changedKeys[inner.version] = newlyChangedKeys
        for op in writes {
            if let update = op as? UpdateOp {
                inner.raw.insert(value: update.value, for: update.key)
            } else if op is RemoveOp {
                inner.raw.removeValue(for: op.key)
            }
        }
        cleanup()
    }
    
    private func cleanup() {
        var minVersion = Int.max
        for (k, v) in inner.refCount {
            if v == 0 {
                inner.refCount.removeValue(forKey: k)
            } else {
                if k < minVersion {
                    minVersion = k
                }
            }
        }
        for (k, _) in inner.changedKeys {
            if k < minVersion {
                inner.changedKeys.removeValue(forKey: k)
            }
        }
    }
    
    func commit() -> EventLoopFuture<Void> {
        let p: EventLoopPromise<Void> = inner.loop().newPromise()
        inner.transactions.submit {
            defer { self.inner.refCount[self.readVersion]! -= 1 }
            do {
                try self.checkForConflicts()
                p.succeed(result: ())
            } catch {
                p.fail(error: error)
            }
        }
        return p.futureResult
    }

    init(inner: MemoryStorage, snapshot: SortedDictionary<Protocity_StorageKey, Data>, readVersion: Int) {
        self.inner = inner
        self.snapshot = snapshot
        self.readVersion = readVersion
    }
    
    func get(keys: [Protocity_StorageKey]) -> EventLoopFuture<[Data?]>{
        return inner.loop().newSucceededFuture(result: keys.map { snapshot.findValue(for: $0) })
    }
    
    func range(from: Protocity_StorageKey, to: Protocity_StorageKey, limit: Int) -> EventLoopFuture<[Data]> {
        var answers: [Data] = []
        for key in snapshot.keys {
            if key < from || key >= to || answers.count == limit {
                continue
            }
            if let value = snapshot.findValue(for: key) {
                answers.append(value)
            }
        }
        return inner.loop().newSucceededFuture(result: answers)
    }
    
    func put(pairs: [(Protocity_StorageKey, Data)]) -> EventLoopFuture<Void> {
        for pair in pairs {
            writes.append(UpdateOp(key: pair.0, value: pair.1))
            snapshot.insert(value: pair.1, for: pair.0)
        }
        return inner.loop().newSucceededFuture(result: ())
    }
    
    func remove(keys: [Protocity_StorageKey]) -> EventLoopFuture<Void> {
        for key in keys {
            writes.append(RemoveOp(key: key))
            snapshot.removeValue(for: key)
        }
        return inner.loop().newSucceededFuture(result: ())
    }
    
    func transactionally(transaction: @escaping (RawStorage) -> EventLoopFuture<Void>) -> EventLoopFuture<Void> {
        return inner.loop().newFailedFuture(error: AlreadyInTransactionBlock())
    }
}
struct Conflict: Error {
    
}
struct AlreadyInTransactionBlock: Error {
    
}
