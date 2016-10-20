//
//  CachePolicy.swift
//  CoreCache
//
//  Created by yuuji on 10/3/16.
//
//

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

public enum CacheLifeTimePolicy {
    case forever // keep the cache in container forever unless removed
    case strictInterval(time_t) // keep the cache for t amount of time strict after created
    case idleInterval(time_t) // remove the cache if the cache haven't read for an interval of time
}

// how should we time the cache lifetime??
public enum CacheTimerPolicy {
    case global // use the container's timer. For example, if the timer of container fires every 2s, where we set the lifetime of the cache as `strictInterval` and 1.5 sec, than the cache will be remove in between 1.5 - 2.0s
    case independent // setup an independent timer. For example, if the timer of container fires every 2s, where we set the lifetime of the cache as `strictInterval` and 1.5 sec, than the cache will be remove strictly at 1.5s
}

public enum FileCachePolicy {
    case once // cache only once
    case interval(time_t) // update every certain interval
    case up2Date // track changes
    case lazyUp2Date // detect changes when requested, update and return if changes were made
    case noReserve // do not reserve binary, cache only file descriptor
    case oldCopy // return cached content first then update content if changed while requested
}
