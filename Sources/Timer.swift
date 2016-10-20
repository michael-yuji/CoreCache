//
//  Timer.swift
//  CoreCache
//
//  Created by yuuji on 10/16/16.
//
//


#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

import Dispatch
import struct Foundation.UUID

public struct CCTimeInterval: Comparable {
    internal var nanoseconds: Int
    
    public init(sec: Int, milisec: Int, microsec: Int, nsec: Int) {
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

public final class Timer {
    public var interval: CCTimeInterval
    public var events = [UUID : () -> Void]()
    internal var eventsIntervals = [UUID : (start: Int, interval: Int)]()
    
    internal var source: DispatchSourceTimer
    public var delegate: TimerDelegate?
    private var suspended = true
    private var ticks = 0
    
    public func fire() {
        if suspended {
            self.source.resume()
            suspended = false
        }
    }
    
    public func stop() {
        if !suspended {
            self.source.suspend()
            suspended = true
        }
    }
    
    public func append(timeinterval: CCTimeInterval, action: @escaping () -> Void) -> UUID {
        let uuid = UUID()
        self.events[uuid] = action
        let now = self.ticks
        let ev_ticks = Int(round(Double(self.interval.nanoseconds) / Double(timeinterval.nanoseconds)))
        self.eventsIntervals[uuid] = (now, ev_ticks)
        return uuid
    }
    
    public func remove(uuid: UUID) {
        self.eventsIntervals.removeValue(forKey: uuid)
        self.events.removeValue(forKey: uuid)
    }
    
    public init(interval: CCTimeInterval) {
        self.interval = interval
        self.source = DispatchSource.makeTimerSource()
        source.setEventHandler {
            self.ticks += 1
            for (uuid, event) in self.events {
                guard let t = self.eventsIntervals[uuid] else {
                    continue
                }
                
                if (self.ticks - t.start) % t.interval == 0 {
                    self.delegate?.didExecutableTask(timer: self, taskId: uuid)
                    event()
                }
            }
        }
        
        self.source.scheduleRepeating(deadline: DispatchTime.now(), interval: interval.dispatchTimeInterval)
    }
    
    deinit {
        if !suspended {
            self.stop()
        }
        self.source.cancel()
    }
    
}

public protocol TimerDelegate {
    func didExecutableTask(timer: Timer, taskId: UUID)
}
