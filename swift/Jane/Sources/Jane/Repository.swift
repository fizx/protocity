import Promises
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
    func _indirectFind(_ key: Jane_StorageKey) -> Promise<V?> {
        return _indirectFind([key]).then { $0[0] }
    }
    
    func _indirectFind(_ keys: [Jane_StorageKey]) -> Promise<[V?]> {
        return storage.get(keys: keys).then { values in
            let newKeys = values.map { value -> Jane_StorageKey? in
                if value == nil {
                    return nil
                } else {
                    return try! Jane_StorageKey(serializedData: value!)
                }
            }
            return self._find(newKeys)
        }
    }
    
    func _indirectFind(_ range: Range<Jane_StorageKey>, limit: Int = Int.max) -> Promise<[V]> {
        return storage.range(from: range.lowerBound, to: range.upperBound, limit: limit).then { values in
            return values.map { try! Jane_StorageKey(serializedData: $0) }
        }.then { keys in
            return self._find(keys)
        }.then { values in
            return values.compactMap{$0}
        }
    }
    
    
    func _find(_ key: Jane_StorageKey) -> Promise<V?> {
        return storage.get(key: key).then { value in
            value.flatMap{
                self.constructor(data: $0)
            }
        }
    }
    
    func _find(_ keys: [Jane_StorageKey?]) -> Promise<[V?]> {
        return _find(keys.compactMap{$0}).then { answers -> [V?] in
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
    
    func _find(_ keys: [Jane_StorageKey]) -> Promise<[V?]> {
        return storage.get(keys: keys).then { values in
            return values.map {
                $0.flatMap {
                    self.constructor(data: $0)
                }
            }
        }
    }
    
    func _find(_ range: Range<Jane_StorageKey>, limit: Int = Int.max) -> Promise<[V]> {
        return storage.range(from: range.lowerBound, to: range.upperBound, limit: limit).then { values in
            return values.map { self.constructor(data: $0)! }
        }
    }
    
    func save(_ objs: V...) -> Promise<Void> {
        return self.storage.transactionally { t in
            var promises: [Promise<Void>] = []
        
            for obj in objs {
                let key = obj.primaryIndex()
                let binaryKey = try! key.serializedData()
                let value = obj.toValue()
                promises += [t.put(key: key, value: value)]
                for index in obj.secondaryIndexes() {
                    promises += [t.get(key: index).then { (maybeData: Data?) -> Promise<Void> in
                        if let data = maybeData {
                            let existingKey = try! Jane_StorageKey(serializedData: data)
                            if existingKey == key {
                                return t.put(key: index, value: binaryKey)
                            } else {
                                return Promise(Conflict())
                            }
                        } else {
                            return t.put(key: index, value: binaryKey)
                        }
                    }]
                }
            }
        
            return all(promises).void
        }
    }
}
