//
//  CachedFile_internal.swift
//  CoreCache
//
//  Created by yuuji on 10/11/16.
//
//

import CKit
import struct Foundation.Data

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

public extension CachedFile {
    
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
                if stat == self.laststat {
                    return
                }
            }
            
            let newfd = open(path, O_RDWR)
            
            if newfd == -1 {
                throw CachedFile.Error.open(String.lastErrnoString)
            }
            
            close(self.lastfd)
            
            self.lastfd = newfd
            self.laststat = try FileStatus(fd: lastfd)
            
            if case .noReserve = policy {} else {
                
                let ptr = mmap(nil, laststat.size, PROT_READ | PROT_WRITE | PROT_EXEC , MAP_FILE | MAP_PRIVATE, lastfd, 0)
                
                if ptr?.numerialValue == -1 {
                    perror("mmap")
                } else {
                    mappedData = Data(bytesNoCopy: UnsafeMutableRawPointer(ptr)!, count: laststat.size, deallocator: .unmap)
                }
            }
            
            self.updatedDate = time(nil)
        }
        
    }
    
}
