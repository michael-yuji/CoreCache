
import CKit
import Dispatch
import struct Foundation.Data

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

public struct CachedContent {
    
    var policies: (lifetime: CacheLifeTimePolicy,  timer: CacheTimerPolicy)
    var file: File
    public init(staticContent content: Data, lifeTimePolicy: CacheLifeTimePolicy, timerPolicy: CacheTimerPolicy) {
//        self.cached = .static(content)
        self.file = File(staticContent: content)
        self.policies = (lifeTimePolicy, timerPolicy)
    }
    
    public init(lifeTimePolicy: CacheLifeTimePolicy, timerPolicy: CacheTimerPolicy, dynamic: @escaping () -> Data) {
//        self.cached = .dynamic(dynamic)
        self.file = File(dynamic: dynamic)
        self.policies = (lifeTimePolicy, timerPolicy)
    }
    
    private static func initialize(content: CachedContent) {
//        switch content.policies.lifetime {
//        case <#pattern#>:
//            <#code#>
//        default:
//            <#code#>
//        }
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
