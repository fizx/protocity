import Promises
import SwiftProtobuf
import Dispatch

class Repository<V: StorageMappable> {
    let storage: RawStorage
    init(storage: RawStorage) {
        self.storage = storage
    }
    
    func save(_ objs: V...) -> Promise<Void> {
        var promises: [Promise<Void>] = []
        
        for obj in objs {
            let key = obj.primaryIndex()
            let value = obj.toValue()
            promises += [self.storage.put(key: key!, value: value)]
            for (index, value) in obj.secondaryIndexes() {
                promises += [self.storage.put(key: index.name, value: value)]
            }
        }
        
        return all(promises).void
    }
}
