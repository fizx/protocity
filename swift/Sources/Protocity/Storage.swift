import Algorithm
import Foundation
import Promises

protocol StorageMappable {
    func toValue() -> Data
    func primaryIndex() -> Protocity_StorageKey
    func secondaryIndexes() -> [Protocity_StorageKey]
}

protocol RawStorage {
    func get(key: Protocity_StorageKey) -> Promise<Data?>
    func get(keys: [Protocity_StorageKey]) -> Promise<[Data?]>
    func range(from: Protocity_StorageKey, to: Protocity_StorageKey, limit: Int) -> Promise<[Data]>
    func put(pairs: [(Protocity_StorageKey, Data)]) -> Promise<Void>
    func put(key: Protocity_StorageKey, value: Data) -> Promise<Void>
    func remove(keys: [Protocity_StorageKey]) -> Promise<Void>
    func transactionally(transaction: @escaping (RawStorage) throws -> Promise<Void>) -> Promise<Void>
}

extension RawStorage {
    func put(key: Protocity_StorageKey, value: Data) -> Promise<Void> {
        return self.put(pairs: [(key, value)])
    }
    
    func get(key: Protocity_StorageKey) -> Promise<Data?> {
        return self.get(keys: [key]).then { $0[0] }
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
    let transactions = DispatchQueue(label: "memory_storage_transactions")
    var raw = SortedDictionary<Protocity_StorageKey, Data>()
    var version = 0
    var refCount: [Int: Int] = [:]
    var changedKeys: [Int: Set<Protocity_StorageKey>] = [:]
    
    func get(keys: [Protocity_StorageKey]) -> Promise<[Data?]> {
        return all(keys.map{ Promise(raw.findValue(for: $0)) })
    }
    
    func range(from: Protocity_StorageKey, to: Protocity_StorageKey, limit: Int) -> Promise<[Data]> {
        var answers: [Data] = []
        for key in raw.keys {
            if key < from || key >= to || answers.count == limit {
                continue
            }
            if let value = raw.findValue(for: key) {
                answers.append(value)
            }
        }
        return Promise(answers)
    }
    
    func put(pairs: [(Protocity_StorageKey, Data)]) -> Promise<Void> {
        return self.transactionally { transaction in
            return transaction.put(pairs: pairs)
        }
    }
    
    func remove(keys: [Protocity_StorageKey]) -> Promise<Void> {
        return self.transactionally { transaction in
            transaction.remove(keys: keys)
        }
    }
    
    func newTransactionStore() -> Promise<TransactionStore> {
        let p = Promise<TransactionStore>.pending()
        self.transactions.async {
            self.refCount[self.version] = (self.refCount[self.version] ?? 0) + 1
            var snapshot = SortedDictionary<Protocity_StorageKey, Data>()
            for (k, v) in self.raw {
                snapshot[k] = v
            }
            p.fulfill(TransactionStore(inner: self, snapshot: snapshot, readVersion: self.version))
        }
        return p
    }
    
    func transactionally(transaction: @escaping (RawStorage) throws -> Promise<Void>) -> Promise<Void> {
        return newTransactionStore().then { store -> Promise<Void> in
            try transaction(store).then { _ -> Promise<Void> in
                return store.commit()
            }.recover { e -> Promise<Void> in
                return store.rollback().then {
                    throw e
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

    struct RemoveOp: Op {
        var key: Protocity_StorageKey
    }
    
    func rollback() -> Promise<Void> {
        let p = Promise<Void>.pending()
        inner.transactions.async {
            self.inner.refCount[self.readVersion]! -= 1
            p.fulfill(())
        }
        return p
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
    
    func commit() -> Promise<Void> {
        let p = Promise<Void>.pending()
        inner.transactions.async {
            defer { self.inner.refCount[self.readVersion]! -= 1 }
            do {
                try self.checkForConflicts()
                p.fulfill(())
            } catch {
                p.reject(error)
            }
        }
        return p
    }

    init(inner: MemoryStorage, snapshot: SortedDictionary<Protocity_StorageKey, Data>, readVersion: Int) {
        self.inner = inner
        self.snapshot = snapshot
        self.readVersion = readVersion
    }
    
    func get(keys: [Protocity_StorageKey]) -> Promise<[Data?]>{
        return Promise(keys.map { snapshot.findValue(for: $0) })
    }
    
    func range(from: Protocity_StorageKey, to: Protocity_StorageKey, limit: Int) -> Promise<[Data]> {
        var answers: [Data] = []
        for key in snapshot.keys {
            if key < from || key >= to || answers.count == limit {
                continue
            }
            if let value = snapshot.findValue(for: key) {
                answers.append(value)
            }
        }
        return Promise(answers)
    }
    
    func put(pairs: [(Protocity_StorageKey, Data)]) -> Promise<Void> {
        for pair in pairs {
            writes.append(UpdateOp(key: pair.0, value: pair.1))
            snapshot.insert(value: pair.1, for: pair.0)
        }
        return Promise(())
    }
    
    func remove(keys: [Protocity_StorageKey]) -> Promise<Void> {
        for key in keys {
            writes.append(RemoveOp(key: key))
            snapshot.removeValue(for: key)
        }
        return Promise(())
    }
    
    func transactionally(transaction: @escaping (RawStorage) throws -> Promise<Void>) -> Promise<Void> {
        return Promise(AlreadyInTransactionBlock())
    }
}
struct Conflict: Error {
    
}
struct AlreadyInTransactionBlock: Error {
    
}
