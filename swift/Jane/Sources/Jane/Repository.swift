import Promises
import SwiftProtobuf
import Dispatch

class Repository<V: StorageMappable> {
    let storage: RawStorage
    init(storage: RawStorage) {
        self.storage = storage
    }
    
    func save(_ objs: V...) -> Promise<Void> {
        return self.storage.transactionally { t in
            var promises: [Promise<Void>] = []
        
            for obj in objs {
                let key = obj.primaryIndex()
                let value = obj.toValue()
                promises += [t.put(key: key!, value: value)]
                for (index, value) in obj.secondaryIndexes() {
                    if index.unique {
                        promises += [t.get(key: index.name).then { (id: BytesWrapper?) -> Promise<Void> in
                            if id != nil && id! != value {
                                return Promise(Conflict())
                            } else {
                                return t.put(key: index.name, value: value)
                            }
                        }]
                    } else {
                        promises += [t.put(key: index.name, value: value)]
                    }
                }
            }
        
            return all(promises).void
        }
    }
}
