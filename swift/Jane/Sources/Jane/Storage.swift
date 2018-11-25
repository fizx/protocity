import Algorithm
import Foundation
import Promises

struct Index: Hashable {
    var name: BytesWrapper
    var unique: Bool = false
}

protocol StorageMapper {
    associatedtype V
    func toValue(v: V) -> BytesWrapper
    func primaryIndex(v: V) -> BytesWrapper?
    func secondaryIndexes(v: V) -> [Index: BytesWrapper]
}

protocol StorageMappable {
    func toValue() -> BytesWrapper
    func primaryIndex() -> BytesWrapper?
    func secondaryIndexes() -> [Index: BytesWrapper]
}

protocol RawStorage {
    func get(key: BytesWrapper) -> Promise<BytesWrapper?>
    func range(from: BytesWrapper, to: BytesWrapper, inclusive: Bool) -> Promise<[BytesWrapper]>
    func put(key: BytesWrapper, value: BytesWrapper) -> Promise<Void>
    func remove(key: BytesWrapper) -> Promise<Void>
    func transactionally(transaction: @escaping (RawStorage) throws -> Promise<Void>) -> Promise<Void>
}

struct BytesWrapper: Comparable, Equatable, Hashable, Codable {
    let array: [UInt8]
    init(_ tableNS: String, _ fieldNS: String, _ key: Data) {
        self.array = Array(tableNS.utf8) + Array(fieldNS.utf8) + [UInt8](key)
    }
    init(_ tableNS: String, _ fieldNS: String, string: String) {
        self.array = Array(tableNS.utf8) + Array(fieldNS.utf8) + Array(string.utf8)
    }
    init(data: Data) {
        self.array = [UInt8](data)
    }
    init(array: [UInt8]) {
        self.array = array
    }
    init(string: String) {
        self.array = Array(string.utf8)
    }
    
    func toData() -> Data {
        return Data(self.array)
    }
    
    static func < (lhs: BytesWrapper, rhs: BytesWrapper) -> Bool {
        for (l, r) in zip(lhs.array, rhs.array) {
            if (l < r) {
                return true
            } else if (l > r) {
                return false
            }
        }
        return lhs.array.count < rhs.array.count
    }
    
}

class MemoryStorage: RawStorage {
    let transactions = DispatchQueue(label: "memory_storage_transactions")
    var raw = SortedDictionary<BytesWrapper, BytesWrapper>()
    var version = 0
    var refCount: [Int: Int] = [:]
    var changedKeys: [Int: Set<BytesWrapper>] = [:]
    
    func get(key: BytesWrapper) -> Promise<BytesWrapper?>{
        return Promise(raw.findValue(for: key))
    }
    
    func range(from: BytesWrapper, to: BytesWrapper, inclusive: Bool) -> Promise<[BytesWrapper]> {
        var answers: [BytesWrapper] = []
        for key in raw.keys {
            if key < from || key > to {
                continue
            }
            if (!inclusive && key == to) {
                continue
            }
            if let value = raw.findValue(for: key) {
                answers.append(value)
            }
        }
        return Promise(answers)
    }
    
    func put(key: BytesWrapper, value: BytesWrapper) -> Promise<Void> {
        return self.transactionally { transaction in
            transaction.put(key: key, value: value)
        }
    }
    
    func remove(key: BytesWrapper) -> Promise<Void> {
        return self.transactionally { transaction in
            transaction.remove(key: key)
        }
    }
    
    func newTransactionStore() -> Promise<TransactionStore> {
        let p = Promise<TransactionStore>.pending()
        self.transactions.async {
            self.refCount[self.version] = (self.refCount[self.version] ?? 0) + 1
            var snapshot = SortedDictionary<BytesWrapper, BytesWrapper>()
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
                print("COMMIT")
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
    var key: BytesWrapper { get set }
}

class TransactionStore: RawStorage {
    let inner: MemoryStorage
    var snapshot: SortedDictionary<BytesWrapper, BytesWrapper>
    let readVersion: Int
    var writes: [Op] = []
    
    struct UpdateOp: Op {
        var key: BytesWrapper
        var value: BytesWrapper
    }

    struct RemoveOp: Op {
        var key: BytesWrapper
    }
    
    func rollback() -> Promise<Void> {
        inner.refCount[readVersion]! -= 1
        return Promise(())
    }
    
    private func checkForConflicts() throws {
        var conflictableKeys: Set<BytesWrapper> = []
        
        for i in (readVersion + 1)..<(inner.version + 1) {
            for key in inner.changedKeys[i] ?? [] {
                conflictableKeys.insert(key)
            }
        }
        
        var newlyChangedKeys: Set<BytesWrapper> = []
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

    init(inner: MemoryStorage, snapshot: SortedDictionary<BytesWrapper, BytesWrapper>, readVersion: Int) {
        self.inner = inner
        self.snapshot = snapshot
        self.readVersion = readVersion
    }
    
    func get(key: BytesWrapper) -> Promise<BytesWrapper?>{
        return Promise(snapshot.findValue(for: key))
    }
    
    func range(from: BytesWrapper, to: BytesWrapper, inclusive: Bool) -> Promise<[BytesWrapper]> {
        var answers: [BytesWrapper] = []
        for key in snapshot.keys {
            if key < from || key > to {
                continue
            }
            if (!inclusive && key == to) {
                continue
            }
            if let value = snapshot.findValue(for: key) {
                answers.append(value)
            }
        }
        return Promise(answers)
    }
    
    func put(key: BytesWrapper, value: BytesWrapper) -> Promise<Void> {
        writes.append(UpdateOp(key: key, value: value))
        if snapshot.findValue(for: key) != nil {
            snapshot.update(value: value, for: key)
        } else {
            snapshot.insert(value: value, for: key)
        }
        return Promise(())
    }
    
    func remove(key: BytesWrapper) -> Promise<Void> {
        writes.append(RemoveOp(key: key))
        snapshot.removeValue(for: key)
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
