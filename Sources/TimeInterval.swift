//
//  TimeInterval.swift
//  CoreCache
//
//  Created by yuuji on 10/20/16.
//
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
