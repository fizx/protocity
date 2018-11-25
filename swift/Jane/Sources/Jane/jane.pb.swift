import Promises
import Jane
import Swinject
import SwinjectAutoregistration
import Foundation
  
    
    class Example_UserRepository: Repository<Example_User> {
      
      
      
    }
    
    extension Example_User: StorageMappable {
      
        
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
      
      static func repository() -> Example_UserRepository.Type {
        return Example_UserRepository.self
      }
    }
    
    
    class Example_AccountRepository: Repository<Example_Account> {
      
      
      
    }
    
    extension Example_Account: StorageMappable {
      
        
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
      
      static func repository() -> Example_AccountRepository.Type {
        return Example_AccountRepository.self
      }
    }
    
    
    class Example_MessageRepository: Repository<Example_Message> {
      
      
      
    }
    
    extension Example_Message: StorageMappable {
      
        
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
      
      static func repository() -> Example_MessageRepository.Type {
        return Example_MessageRepository.self
      }
    }
    
    
    class Example_PhotoRepository: Repository<Example_Photo> {
      
      
      
    }
    
    extension Example_Photo: StorageMappable {
      
        
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
