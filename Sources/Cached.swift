
import CKit
import Dispatch
import struct Foundation.Data

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

public struct CachedContent: Cache {
    
    var policy: CacheLifeTimePolicy
    var file: File
    
    public init(staticContent content: Data, lifeTimePolicy: CacheLifeTimePolicy) {
        self.file = File(staticContent: content)
        self.policy = lifeTimePolicy
    }
    
    public init(lifeTimePolicy: CacheLifeTimePolicy, dynamic: @escaping () -> Data) {
        self.file = File(dynamic: dynamic)
        self.policy = lifeTimePolicy
    }
    
}

public extension CachedContent {
    
    public final class File {
        var timer: DispatchSourceTimer?
        var cached: Content
        var content: Data?
        
        public init(staticContent content: Data) {
            self.cached = .static(content)
        }
        
        public init(dynamic: @escaping () -> Data) {
            self.cached = .dynamic(dynamic)
        }
    }
    
    
    
}
extension CachedContent {
    public func read() -> Data? {
        return self.file.content
    }
    
    public mutating func update() {
        switch self.file.cached {
        case let .dynamic(fn):
            self.file.content = fn()
        case let .static(content):
            self.file.content = content
        }
    }
}

extension CachedContent {
    enum Content {
        case `static`(Data)
        case dynamic(() -> Data)
    }
}
