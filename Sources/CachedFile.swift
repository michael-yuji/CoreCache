
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
//  Created by yuuji on 9/27/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import CKit
import Dispatch
import struct Foundation.Data

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

public struct CachedFile {
    
    internal var path: String {
        return self.file.path
    }

    internal var updatedDate: time_t {
        return self.file.updatedDate
    }

    internal var file: File
    
    public enum Error : Swift.Error {
        case open(String)
    }
    
    internal class File {
        
        internal var path: String
        internal var policy: FileCachePolicy
        
        internal var lastfd: Int32
        internal var laststat: FileStatus
        
        internal var updatedDate: time_t
        
        internal var mappedData: Data?
        internal var swap: Data?
        
        public init(path: String, policy: FileCachePolicy, fd: Int32, stat: FileStatus, updated: time_t) {
            self.path = path
            self.policy = policy
            self.lastfd = fd
            self.laststat = stat
            self.updatedDate = updated
        }
        
        internal func update() throws {
            if let stat = try? FileStatus(fd: self.lastfd) {
                if stat.modificationDate == self.laststat.modificationDate {
                    return
                }
            } else {
                let newfd = open(path, O_RDWR)
                if newfd == -1 {
                    throw CachedFile.Error.open(String.lastErrnoString)
                }
                self.lastfd = newfd
                self.laststat = try FileStatus(fd: lastfd)
            }
            self.updatedDate = time(nil)
        }
        
    }
    
    public func read() -> Data? {
        switch self.file.policy {
        case .oldCopy:
            let reserved = self.file.mappedData
            try? self.file.update()
            return reserved
        case .lazyUp2Date:
            try? self.file.update()
            fallthrough
        default:
            return self.file.mappedData
        }
    }
    
    public init(path: String, policy: FileCachePolicy, lifetime: timespec) throws {
        let fd = open(path, O_RDWR)
        let laststat = try FileStatus(fd: fd)
        let updatedDate = time(nil)
        
        self.file = File(path: path, policy: policy, fd: fd, stat: laststat, updated: updatedDate)
        weak var file = self.file
        var source: DispatchSourceProtocol?
        
        switch policy {
        case .noReserve:
            break
            
        case let .interval(time):
            
            source = DispatchSource.makeTimerSource()
            (source as! DispatchSourceTimer).scheduleRepeating(wallDeadline: DispatchWallTime(timespec: lifetime), interval: DispatchTimeInterval.seconds(time))
            source!.setEventHandler(qos: DispatchQoS.default, flags: [], handler: {
                guard let file = file else {
                    // TODO: handle error
                    return
                }
                do {
                    try file.update()
                } catch {}
            })
            
        case .up2Date:
            
            source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .all)
            source!.setEventHandler(qos: DispatchQoS.default, flags: [], handler: {
                do {
                    try file?.update()
                } catch {}
            })
            
        default:
            break
        }
        
        if let source = source {
            source.resume()
        }
        
        if case .noReserve = policy {} else {
            let ptr = mmap(nil, laststat.size, PROT_READ, 0, self.file.lastfd, 0)
            self.file.mappedData = Data(bytesNoCopy: UnsafeMutableRawPointer(ptr)!, count: laststat.size, deallocator: .unmap)
        }
        
    }
}

