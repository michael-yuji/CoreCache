
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


#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

import enum Dispatch.DispatchTimeInterval

public struct CCTimeInterval: RawRepresentable, Comparable {
    internal var nanoseconds: Int
    
    public typealias RawValue = timespec
    
    public var rawValue: timespec {
        return unix_timespec
    }
    
    public init(rawValue: timespec) {
        self.nanoseconds = rawValue.tv_sec * 1_000_000_000 + rawValue.tv_nsec
    }
    
    public init(sec: Int = 0, milisec: Int = 0, microsec: Int = 0, nsec: Int = 0) {
        self.nanoseconds = sec * 1_000_000_000 + milisec * 1000_000 + microsec * 1_000 + nsec
    }
    
    var dispatchTimeInterval: DispatchTimeInterval {
        return DispatchTimeInterval.nanoseconds(nanoseconds)
    }
    
    var unix_timespec: timespec {
        return timespec(tv_sec: 0, tv_nsec: nanoseconds)
    }
    
    var unix_time: time_t {
        return nanoseconds / 1_000_000_000
    }
}

public func +(lhs: CCTimeInterval, rhs: CCTimeInterval) -> CCTimeInterval {
    return CCTimeInterval(sec: 0, milisec: 0, microsec: 0, nsec: lhs.nanoseconds + rhs.nanoseconds)
}

public func -(lhs: CCTimeInterval, rhs: CCTimeInterval) -> CCTimeInterval {
    return CCTimeInterval(sec: 0, milisec: 0, microsec: 0, nsec: lhs.nanoseconds - rhs.nanoseconds)
}

public func *(lhs: CCTimeInterval, rhs: CCTimeInterval) -> CCTimeInterval {
    return CCTimeInterval(sec: 0, milisec: 0, microsec: 0, nsec: lhs.nanoseconds * rhs.nanoseconds)
}

public func /(lhs: CCTimeInterval, rhs: CCTimeInterval) -> CCTimeInterval {
    return CCTimeInterval(sec: 0, milisec: 0, microsec: 0, nsec: lhs.nanoseconds / rhs.nanoseconds)
}

public func +(lhs: CCTimeInterval, rhs: Int) -> CCTimeInterval {
    return CCTimeInterval(sec: 0, milisec: 0, microsec: 0, nsec: lhs.nanoseconds + rhs)
}

public func -(lhs: CCTimeInterval, rhs: Int) -> CCTimeInterval {
    return CCTimeInterval(sec: 0, milisec: 0, microsec: 0, nsec: lhs.nanoseconds - rhs)
}

public func *(lhs: CCTimeInterval, rhs: Int) -> CCTimeInterval {
    return CCTimeInterval(sec: 0, milisec: 0, microsec: 0, nsec: lhs.nanoseconds * rhs)
}

public func /(lhs: CCTimeInterval, rhs: Int) -> CCTimeInterval {
    return CCTimeInterval(sec: 0, milisec: 0, microsec: 0, nsec: lhs.nanoseconds / rhs)
}

public func +=(lhs: inout CCTimeInterval, rhs: CCTimeInterval) {
    lhs.nanoseconds += rhs.nanoseconds
}

public func -=(lhs: inout CCTimeInterval, rhs: CCTimeInterval) {
    lhs.nanoseconds -= rhs.nanoseconds
}

public func *=(lhs: inout CCTimeInterval, rhs: CCTimeInterval) {
    lhs.nanoseconds *= rhs.nanoseconds
}

public func /=(lhs: inout CCTimeInterval, rhs: CCTimeInterval) {
    lhs.nanoseconds /= rhs.nanoseconds
}

public func %(lhs: CCTimeInterval, rhs: CCTimeInterval) -> CCTimeInterval {
    return CCTimeInterval(sec: 0, milisec: 0, microsec: 0, nsec: lhs.nanoseconds % rhs.nanoseconds)
}

public func ==(lhs: CCTimeInterval, rhs: CCTimeInterval) -> Bool {
    return lhs.nanoseconds == rhs.nanoseconds
}

public func >(lhs: CCTimeInterval, rhs: CCTimeInterval) -> Bool {
    return lhs.nanoseconds > rhs.nanoseconds
}

public func <(lhs: CCTimeInterval, rhs: CCTimeInterval) -> Bool {
    return lhs.nanoseconds < rhs.nanoseconds
}

public func >=(lhs: CCTimeInterval, rhs: CCTimeInterval) -> Bool {
    return lhs.nanoseconds >= rhs.nanoseconds
}

public func <=(lhs: CCTimeInterval, rhs: CCTimeInterval) -> Bool {
    return lhs.nanoseconds <= rhs.nanoseconds
}
