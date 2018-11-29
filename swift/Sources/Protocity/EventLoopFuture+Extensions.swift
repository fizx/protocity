import NIO

extension EventLoopFuture {
    public static func andAllVoid<X>(_ futures: [EventLoopFuture<X>], eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return EventLoopFuture.andAll(futures.map{ $0.void }, eventLoop: eventLoop)
    }
    
    public var void: EventLoopFuture<Void> {
        get {
            return self.map { _ in
                return ()
            }
        }
    }
}
