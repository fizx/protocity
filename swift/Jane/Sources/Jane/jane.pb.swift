import Promises
import Jane
import Swinject
import SwinjectAutoregistration
import Foundation
  
    
    class Example_UserRepository: Repository<Example_User> {
      
        // findOne
        func findById(_ key: String) -> Promise<Example_User?> {
          return self._findByPKRaw(BytesWrapper("Example_User", "Id", string: key))
        }
        // findAllArray
        func findByIds(_ keys: [String]) -> Promise<[Example_User?]> {
          return all(keys.map{ findById($0)})
        }
        
        // findAllVariadic
        func findByIds(_ keys: String...) -> Promise<[Example_User?]> {
          return all(keys.map{ findById($0)})
        }
        
        func _findByPKRaw(_ data: BytesWrapper) -> Promise<Example_User?> {
          return self.storage.get(key: data).then { (maybeBytes: BytesWrapper?) -> Example_User? in
            if let bytes = maybeBytes {
              return try! Example_User(serializedData: bytes.toData())
            } else {
              return nil
            }
          }
        }
      
      
      
        func findByLogin(_ key: String) -> Promise<Example_User?> {
          return self.storage.get(key: BytesWrapper("Example_User", "Login", string: key)).then { (maybeBytes: BytesWrapper?) -> Promise<Example_User?> in
            if let bytes = maybeBytes {
              return self._findByPKRaw(bytes)
            } else {
              return Promise<Example_User?>(nil)
            }
          }
        }
        // findAllArray
        func findByLogins(_ keys: [String]) -> Promise<[Example_User?]> {
          return all(keys.map{ findByLogin($0)})
        }
        
        // findAllVariadic
        func findByLogins(_ keys: String...) -> Promise<[Example_User?]> {
          return all(keys.map{ findByLogin($0)})
        }
      
    }
    
    extension Example_User: StorageMappable {
      
      public static func with(
          _ populator: (inout Example_User) throws -> ()
        ) rethrows -> Example_User {
          var message = Example_User()
          message.id = UUID().uuidString
          try populator(&message)
          return message
        }
      
        
      func toValue() -> BytesWrapper {
        return BytesWrapper(data: try! serializedData())
      } 
      func primaryIndex() -> BytesWrapper? {
        
          return BytesWrapper("Example_User", "Id", string: self.id)
        
      }
      func secondaryIndexes() -> [Index: BytesWrapper] {
        var out: [Index: BytesWrapper] = [:]
        
          out[Index(name: BytesWrapper("Example_User", "Login", string: self.login), unique: true)] = self.primaryIndex()
        
        return out
      }
      
      static func repository() -> Example_UserRepository.Type {
        return Example_UserRepository.self
      }
    }
    
    
    class Example_AccountRepository: Repository<Example_Account> {
      
        // findOne
        func findById(_ key: String) -> Promise<Example_Account?> {
          return self._findByPKRaw(BytesWrapper("Example_Account", "Id", string: key))
        }
        // findAllArray
        func findByIds(_ keys: [String]) -> Promise<[Example_Account?]> {
          return all(keys.map{ findById($0)})
        }
        
        // findAllVariadic
        func findByIds(_ keys: String...) -> Promise<[Example_Account?]> {
          return all(keys.map{ findById($0)})
        }
        
        func _findByPKRaw(_ data: BytesWrapper) -> Promise<Example_Account?> {
          return self.storage.get(key: data).then { (maybeBytes: BytesWrapper?) -> Example_Account? in
            if let bytes = maybeBytes {
              return try! Example_Account(serializedData: bytes.toData())
            } else {
              return nil
            }
          }
        }
      
      
      
    }
    
    extension Example_Account: StorageMappable {
      
      public static func with(
          _ populator: (inout Example_Account) throws -> ()
        ) rethrows -> Example_Account {
          var message = Example_Account()
          message.id = UUID().uuidString
          try populator(&message)
          return message
        }
      
        
      func toValue() -> BytesWrapper {
        return BytesWrapper(data: try! serializedData())
      } 
      func primaryIndex() -> BytesWrapper? {
        
          return BytesWrapper("Example_Account", "Id", string: self.id)
        
      }
      func secondaryIndexes() -> [Index: BytesWrapper] {
        var out: [Index: BytesWrapper] = [:]
        
        return out
      }
      
      static func repository() -> Example_AccountRepository.Type {
        return Example_AccountRepository.self
      }
    }
    
    
    class Example_MessageRepository: Repository<Example_Message> {
      
        // findOne
        func findById(_ key: String) -> Promise<Example_Message?> {
          return self._findByPKRaw(BytesWrapper("Example_Message", "Id", string: key))
        }
        // findAllArray
        func findByIds(_ keys: [String]) -> Promise<[Example_Message?]> {
          return all(keys.map{ findById($0)})
        }
        
        // findAllVariadic
        func findByIds(_ keys: String...) -> Promise<[Example_Message?]> {
          return all(keys.map{ findById($0)})
        }
        
        func _findByPKRaw(_ data: BytesWrapper) -> Promise<Example_Message?> {
          return self.storage.get(key: data).then { (maybeBytes: BytesWrapper?) -> Example_Message? in
            if let bytes = maybeBytes {
              return try! Example_Message(serializedData: bytes.toData())
            } else {
              return nil
            }
          }
        }
      
      
      
    }
    
    extension Example_Message: StorageMappable {
      
      public static func with(
          _ populator: (inout Example_Message) throws -> ()
        ) rethrows -> Example_Message {
          var message = Example_Message()
          message.id = UUID().uuidString
          try populator(&message)
          return message
        }
      
        
      func toValue() -> BytesWrapper {
        return BytesWrapper(data: try! serializedData())
      } 
      func primaryIndex() -> BytesWrapper? {
        
          return BytesWrapper("Example_Message", "Id", string: self.id)
        
      }
      func secondaryIndexes() -> [Index: BytesWrapper] {
        var out: [Index: BytesWrapper] = [:]
        
        return out
      }
      
      static func repository() -> Example_MessageRepository.Type {
        return Example_MessageRepository.self
      }
    }
    
    
    class Example_PhotoRepository: Repository<Example_Photo> {
      
        // findOne
        func findById(_ key: String) -> Promise<Example_Photo?> {
          return self._findByPKRaw(BytesWrapper("Example_Photo", "Id", string: key))
        }
        // findAllArray
        func findByIds(_ keys: [String]) -> Promise<[Example_Photo?]> {
          return all(keys.map{ findById($0)})
        }
        
        // findAllVariadic
        func findByIds(_ keys: String...) -> Promise<[Example_Photo?]> {
          return all(keys.map{ findById($0)})
        }
        
        func _findByPKRaw(_ data: BytesWrapper) -> Promise<Example_Photo?> {
          return self.storage.get(key: data).then { (maybeBytes: BytesWrapper?) -> Example_Photo? in
            if let bytes = maybeBytes {
              return try! Example_Photo(serializedData: bytes.toData())
            } else {
              return nil
            }
          }
        }
      
      
      
    }
    
    extension Example_Photo: StorageMappable {
      
      public static func with(
          _ populator: (inout Example_Photo) throws -> ()
        ) rethrows -> Example_Photo {
          var message = Example_Photo()
          message.id = UUID().uuidString
          try populator(&message)
          return message
        }
      
        
      func toValue() -> BytesWrapper {
        return BytesWrapper(data: try! serializedData())
      } 
      func primaryIndex() -> BytesWrapper? {
        
          return BytesWrapper("Example_Photo", "Id", string: self.id)
        
      }
      func secondaryIndexes() -> [Index: BytesWrapper] {
        var out: [Index: BytesWrapper] = [:]
        
        return out
      }
      
      static func repository() -> Example_PhotoRepository.Type {
        return Example_PhotoRepository.self
      }
    }
    
    
    class Example_HelloRequestRepository: Repository<Example_HelloRequest> {
      
      
      
    }
    
    extension Example_HelloRequest: StorageMappable {
      
        
      func toValue() -> BytesWrapper {
        return BytesWrapper(data: try! serializedData())
      } 
      func primaryIndex() -> BytesWrapper? {
        
          return nil
        
      }
      func secondaryIndexes() -> [Index: BytesWrapper] {
        var out: [Index: BytesWrapper] = [:]
        
        return out
      }
      
      static func repository() -> Example_HelloRequestRepository.Type {
        return Example_HelloRequestRepository.self
      }
    }
    
    
    class Example_HelloResponseRepository: Repository<Example_HelloResponse> {
      
      
      
    }
    
    extension Example_HelloResponse: StorageMappable {
      
        
      func toValue() -> BytesWrapper {
        return BytesWrapper(data: try! serializedData())
      } 
      func primaryIndex() -> BytesWrapper? {
        
          return nil
        
      }
      func secondaryIndexes() -> [Index: BytesWrapper] {
        var out: [Index: BytesWrapper] = [:]
        
        return out
      }
      
      static func repository() -> Example_HelloResponseRepository.Type {
        return Example_HelloResponseRepository.self
      }
    }
  



  class Example_Binder {
    static func bind(_ container: Container) {
      
        container.autoregister(Example_UserRepository.self, initializer: Example_UserRepository.init)
      
        container.autoregister(Example_AccountRepository.self, initializer: Example_AccountRepository.init)
      
        container.autoregister(Example_MessageRepository.self, initializer: Example_MessageRepository.init)
      
        container.autoregister(Example_PhotoRepository.self, initializer: Example_PhotoRepository.init)
      
        container.autoregister(Example_HelloRequestRepository.self, initializer: Example_HelloRequestRepository.init)
      
        container.autoregister(Example_HelloResponseRepository.self, initializer: Example_HelloResponseRepository.init)
      
    }
  }
