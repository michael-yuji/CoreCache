
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
//  Created by yuuji on 10/16/16.
//  Copyright © 2016 yuuji. All rights reserved.
//


#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

import Dispatch
import CKit
import struct Foundation.UUID

public final class Timer {
    public var interval: CCTimeInterval
    
    private var periodics = [UUID : () -> Void]()
    private var oneshots = [Int : [Int: () -> Void]]()
    private var scheduled = [() -> Void]()
    
    internal var eventsIntervals = [UUID : (start: Int, interval: Int)]()
    internal var source: DispatchSourceTimer
    internal var started = timespec()
    
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
    
    public var uptime: timespec {
        let now = Timer.now()
        return timespec(tv_sec: now.tv_sec - started.tv_sec, tv_nsec: now.tv_nsec - started.tv_nsec)
    }
    
    internal func date2ticks(dt time: timespec) -> Int {
        return Int(round(Double(time.hashValue - started.hashValue) / Double(self.interval.nanoseconds)))
    }
    
    internal func date2ticks(dt time: CCTimeInterval) -> Int {
        return Int(round(Double(time.nanoseconds - started.hashValue) / Double(self.interval.nanoseconds)))
    }
    
    internal func date2ticks(dt nanoseconds: Int) -> Int {
        return Int(round(Double(nanoseconds - started.hashValue) / Double(self.interval.nanoseconds)))
    }
    
    public func schedulePeriodic(timeinterval: CCTimeInterval, action: @escaping (Timer?, UUID) -> Void) -> UUID {
        let uuid = UUID()
        self.periodics[uuid] = { [weak self] in
            action(self, uuid)
        }
        let now = self.ticks
        let ev_ticks = Int(round(Double(timeinterval.nanoseconds)/Double(self.interval.nanoseconds)))
        self.eventsIntervals[uuid] = (now, ev_ticks)
        return uuid
    }
    
    public func scheduleAction(at date: timespec, tag: Int = 0, action: @escaping () -> Void) {
        queue {
            let ticks = self.date2ticks(dt: date.hashValue)
            if let _ = self.oneshots[ticks] {
                self.oneshots[ticks]![tag] = action
            } else {
                self.oneshots[ticks] = [tag: action]
            }
        }
    }
    
    public func delayScheduledAction(origin o_time: timespec, tag: Int, by delay: timespec) {
        let key = date2ticks(dt: o_time)
        if let origin = oneshots[key]?.removeValue(forKey: tag) {
            if oneshots[key]!.count == 0 {
                oneshots.removeValue(forKey: key)
            }
            scheduleAction(at: o_time + delay, tag: tag, action: origin)
        }
    }
    
    public func reScheduledAction(origin o_time: timespec, tag: Int, new: timespec) {
        let key = date2ticks(dt: o_time)
        if let origin = oneshots[key]?.removeValue(forKey: tag) {
            if oneshots[key]!.count == 0 {
                oneshots.removeValue(forKey: key)
            }
            scheduleAction(at: new, tag: tag, action: origin)
        }
    }
    
    public func remove(uuid: UUID) {
        self.eventsIntervals.removeValue(forKey: uuid)
        self.periodics.removeValue(forKey: uuid)
    }
    
    public static func now() -> timespec {
        return timespec.now()
    }
    
    public init(interval: CCTimeInterval) {
        self.interval = interval
        self.source = DispatchSource.makeTimerSource()
        
        self.started = Timer.now()
        
        source.setEventHandler {
            self.ticks += 1
            while !self.scheduled.isEmpty {
                self.scheduled.removeFirst()()
            }
            
            for (time, shots) in self.oneshots {
                if self.ticks >= time {
                    for (_, shot) in shots {
                        shot()
                    }
                }
                self.oneshots.removeValue(forKey: self.ticks)
            }
            
            for (uuid, event) in self.periodics {
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
    
    private func queue(action: @escaping () -> Void) {
        scheduled.append(action)
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
