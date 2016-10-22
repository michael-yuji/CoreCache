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

public extension timespec {
    static var distantFuture: timespec {
        return timespec(tv_sec: Int.max, tv_nsec: Int.max)
    }
}

public final class Timer {
    public var interval: CCTimeInterval
    public var events = [UUID : () -> Void]()
    public var delegate: TimerDelegate?
    
    internal var eventsIntervals = [UUID : (start: Int, interval: Int)]()
    internal var source: DispatchSourceTimer
    internal var started = timespec()

    fileprivate var annoymousActions = [Int : () -> Void]()
    fileprivate var scheduled = [() -> Void]()
    fileprivate var suspended = true
    fileprivate var ticks = 0
    
    public init(interval: CCTimeInterval) {
        self.interval = interval
        self.source = DispatchSource.makeTimerSource()
        
        self.started = Timer.now()
        
        source.setEventHandler {
            self.ticks += 1
            while !self.scheduled.isEmpty {
                self.scheduled.removeFirst()()
            }
            
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

public extension Timer {
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
        let ev_ticks = Int(round(Double(timeinterval.nanoseconds)/Double(self.interval.nanoseconds)))
        self.eventsIntervals[uuid] = (now, ev_ticks)
        return uuid
    }
    
    public func scheduledOneshot(timeinterval: CCTimeInterval, action: @escaping () -> Void) {
        queue {
            let ev_ticks = Int(round(Double(timeinterval.nanoseconds)/Double(self.interval.nanoseconds)))
            self.annoymousActions[self.ticks + ev_ticks] = {
                action()
                self.annoymousActions.removeValue(forKey: self.ticks + ev_ticks)
            }
        }
    }
    
    public func remove(uuid: UUID) {
        self.eventsIntervals.removeValue(forKey: uuid)
        self.events.removeValue(forKey: uuid)
    }
    
    public static func now() -> timespec {
        var time = timespec()
        #if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
            if #available(OSX 10.12, iOS 10, *) {
                clock_gettime(_CLOCK_REALTIME, &time)
            } else {
                var clock = clock_serv_t()
                host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &clock)
                var mach_ts = mach_timespec()
                clock_get_time(clock, &mach_ts)
                time = timespec(tv_sec: Int(mach_ts.tv_sec), tv_nsec: Int(mach_ts.tv_nsec))
                mach_port_deallocate(mach_task_self_, clock)
            }
        #elseif os(FreeBSD)
            clock_gettime(CLOCK_REALTIME_FAST, &time)
        #elseif os(Linux)
            clock_gettime(CLOCK_REALTIME, &time)
        #endif
        return time
    }
    
    fileprivate func queue(action: @escaping () -> Void) {
        scheduled.append(action)
    }
}
