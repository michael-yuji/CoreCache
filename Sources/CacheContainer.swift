
//  Copyright (c) 2016, Yuji
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the FreeBSD Project.
//
//  Created by yuuji on 10/20/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation
import CKit

public final class CacheContainer {
    public static var shared: CacheContainer = CacheContainer(refreshResulotion: CCTimeInterval(milisec: 100))
    public var cached = [String: Cache]()
    public var clock: Timer
    
    
    internal var inotify_fd: Int32 = 0
    
    fileprivate var scheduledRemovalTable = [String: (CCTimeInterval, CCTimeInterval)]()
    public init(refreshResulotion: CCTimeInterval) {
        self.clock = Timer(interval: refreshResulotion)
        self.clock.fire()
    }
}

// -MARK: Exposed API
extension CacheContainer {
    
    public func currentFd(of ident: String) -> Int32? {
        guard
            let cache = self.cached[ident],
            let file = cache as? CachedFile else {
                return nil
        }
        
        return file.currentFileDescriptor
    }
    
    
    public subscript(str: String) -> Data? {
        
        if let (dt, scheduledRemoval) = self.scheduledRemovalTable[str] {
            let new = Timer.now() + dt.unix_timespec
            self.clock.reScheduledAction(origin: scheduledRemoval.unix_timespec, tag: str.hashValue, new: Timer.now() + dt.unix_timespec)
            self.scheduledRemovalTable[str] = (dt, CCTimeInterval(rawValue: new))
        }
        
        return self.cached[str]?.read()
    }
    
    public func remove(item key: String) {
        remove(cache: key, uuid: nil)
    }
    
    public func cacheFile(at path: String, as identifier: String, using policy: CachePolicy, lifetime: CacheLifeTimePolicy, errHandle: ((_ path:String, _ error: Error) -> ())?) {
        
        do {
            let cached = try CachedFile(path: path, policy: policy)
            cache(ident: identifier, cache: cached, policy: policy, lifetime: lifetime)
        } catch {
            errHandle?(path, error)
        }
        
    }
 
    public func cacheDynamicContent(as identifier: String, using policy: CachePolicy, lifetime: CacheLifeTimePolicy, generator data: @escaping () -> Data) {
        var cached = CachedContent(lifeTimePolicy: lifetime, dynamic: data)
        cached.update() // initialize
        cache(ident: identifier, cache: cached, policy: policy, lifetime: lifetime)
    }
}

//- MARK: Implementation
extension CacheContainer {

    @inline(__always)
    fileprivate func remove(cache ident: String, uuid: UUID?) {
        self.cached.removeValue(forKey: ident)
        self.scheduledRemovalTable.removeValue(forKey: ident)
        
        if let uuid = uuid {
            self.clock.remove(uuid: uuid)
        }
    }
    
    fileprivate func cache(ident: String, cache: Cache, policy: CachePolicy, lifetime: CacheLifeTimePolicy) {
        self.cached[ident] = cache
        
        var uuid: UUID?
        
        switch policy {
        case .once:
            break
        case let .interval(dt):
            uuid = self.clock.schedulePeriodic(timeinterval: dt, action: { clock, uuid in
                guard var content = self.cached[ident] else {
                    if let clock = clock {
                        clock.remove(uuid: uuid)
                    }
                    return
                }
                content.update()
            })
            
        default:
            break
        }
        
        switch lifetime {
        case .forever:
            break
        case let .strictInterval(dt):
            let t = Timer.now() + dt.unix_timespec
            self.clock.scheduleAction(at: t, action: {
                self.remove(cache: ident, uuid: uuid)
            })

        case let .idleInterval(dt):
            let removalTime = CCTimeInterval(rawValue: Timer.now()) + dt
            self.scheduledRemovalTable[ident] = (dt, removalTime)
            
            self.clock.scheduleAction(at: removalTime.rawValue, tag: ident.hashValue) {
                self.remove(cache: ident, uuid: uuid)
            }
        }
    }
}
