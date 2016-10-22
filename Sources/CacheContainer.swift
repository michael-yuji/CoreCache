//
//  CacheContainer.swift
//  CoreCache
//
//  Created by yuuji on 10/20/16.
//
//

import Foundation

public protocol Cache {
    func read() -> Data?
}

public final class CacheContainer {
    public var cached = [String: Cache]()
    internal var accessRecord = [String: CCTimeInterval]()
    public var clock: Timer
    public static var shared: CacheContainer = CacheContainer(refreshResulotion: CCTimeInterval(milisec: 100))
    
    public subscript(str: String) -> Data? {
        return self.cached[str]?.read()
    }
    
    public init(refreshResulotion: CCTimeInterval) {
        self.clock = Timer(interval: refreshResulotion)
        self.clock.fire()
    }
    
    public func cache(identifier: String, file path: String, how: FileCachePolicy,lifetime: CacheLifeTimePolicy, errHandle: (_ path:String, _ error: Error) -> ()) {
        
        do {
            let cache = try CachedFile(path: path, policy: how)
            append(ident: identifier, cache: cache, lifetime: lifetime)
        } catch {
            errHandle(path, error)
        }
        
    }
    
    public func cache(identifier: String, static data: Data, policy: CachePolicy, lifetime: CacheLifeTimePolicy) {
        let cache = CachedContent(staticContent: data, lifeTimePolicy: lifetime)
        var uuid: UUID?
        switch policy {
        case .once:
            break
        case let .interval(dt):
            uuid = self.clock.append(timeinterval: dt, action: {
                guard let c = self.cached[identifier],
                var content = c as? CachedContent else {
                    return
                }
                content.update()
            })
        default:
            break
        }
        
        append(ident: identifier, cache: cache, lifetime: lifetime, buuid: uuid)
    }
    
    internal func append(ident: String, cache: Cache, lifetime: CacheLifeTimePolicy, buuid: UUID? = nil) {
        self.cached[ident] = cache
        
        switch lifetime {
        case .forever:
            break
        case let .strictInterval(dt):
            self.clock.scheduledOneshot(timeinterval: dt, action: {
                self.cached.removeValue(forKey: ident)
                if let uuid = buuid {
                    self.clock.remove(uuid: uuid)
                }
            })
        case let .idleInterval(dt):
            func makeNext() {
                let now = Timer.now()
                self.clock.scheduledOneshot(timeinterval: dt, action: {
                    guard let xt = self.accessRecord[ident] else {
                        return
                    }
                    if xt > CCTimeInterval(rawValue: Timer.now()) - CCTimeInterval(rawValue: now) {
                        self.cached.removeValue(forKey: ident)
                        if let uuid = buuid {
                            self.clock.remove(uuid: uuid)
                        }
                    } else {
                        makeNext()
                    }
                })
            }
            
            makeNext()
        }
    }
}
