import NIO
import SwiftProtobuf
import Dispatch
import Foundation

class Repository<V: StorageMappable> {
    let storage: RawStorage
    init(storage: RawStorage) {
        self.storage = storage
    }
    
    func constructor(data: Data) -> V? {
        return nil
    }
    func _indirectFind(_ key: Protocity_StorageKey) -> EventLoopFuture<V?> {
        return _indirectFind([key]).map { $0[0] }
    }

    func _indirectFind(_ keys: [Protocity_StorageKey]) -> EventLoopFuture<[V?]> {
        return storage.get(keys: keys).then { values in
            let newKeys = values.map { value -> Protocity_StorageKey? in
                if value == nil {
                    return nil
                } else {
                    return try! Protocity_StorageKey(serializedData: value!)
                }
            }
            return self._find(newKeys)
        }
    }

    func _indirectFind(_ range: Range<Protocity_StorageKey>, limit: Int = Int.max) -> EventLoopFuture<[V]> {
        return storage.range(from: range.lowerBound, to: range.upperBound, limit: limit).map { values in
            return values.map { try! Protocity_StorageKey(serializedData: $0) }
        }.then { keys in
            return self._find(keys)
        }.map { values in
            return values.compactMap{$0}
        }
    }

    func _find(_ key: Protocity_StorageKey) -> EventLoopFuture<V?> {
        return storage.get(key: key).map { value in
            value.flatMap {
                self.constructor(data: $0)
            }
        }
    }
    
    func _find(_ keys: [Protocity_StorageKey?]) -> EventLoopFuture<[V?]> {
        return _find(keys.compactMap{$0}).map { answers -> [V?] in
            var tmp = answers
            var padded: [V?] = []
            for key in keys {
                if key == nil {
                    padded.append(nil)
                } else {
                    padded.append(tmp.removeFirst())
                }
            }
            return padded
        }
    }
    
    func _find(_ keys: [Protocity_StorageKey]) -> EventLoopFuture<[V?]> {
        return storage.get(keys: keys).map { values in
            return values.map {
                $0.flatMap {
                    self.constructor(data: $0)
                }
            }
        }
    }
    
    func _find(_ range: Range<Protocity_StorageKey>, limit: Int = Int.max) -> EventLoopFuture<[V]> {
        return storage.range(from: range.lowerBound, to: range.upperBound, limit: limit).map { values in
            return values.map { self.constructor(data: $0)! }
        }
    }
    
    func save(_ objs: V...) -> EventLoopFuture<Void> {
        return self.storage.transactionally { t in
            var promises: [EventLoopFuture<Void>] = []
        
            for obj in objs {
                let key = obj.primaryIndex()
                let binaryKey = try! key.serializedData()
                let value = obj.toValue()
                promises += [t.put(key: key, value: value)]
                for index in obj.secondaryIndexes() {
                    promises += [t.get(key: index).then { (maybeData: Data?) -> EventLoopFuture<Void> in
                        if let data = maybeData {
                            let existingKey = try! Protocity_StorageKey(serializedData: data)
                            if existingKey == key {
                                return t.put(key: index, value: binaryKey)
                            } else {
                                return self.storage.loop().newFailedFuture(error: Conflict())
                            }
                        } else {
                            return t.put(key: index, value: binaryKey)
                        }
                    }]
                }
            }
        
            return EventLoopFuture<Void>.andAll(promises, eventLoop: self.storage.loop())
        }
    }
}
