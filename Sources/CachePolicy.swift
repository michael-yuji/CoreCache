//
//  CachePolicy.swift
//  CoreCache
//
//  Created by yuuji on 10/3/16.
//
//

import Foundation

public enum FileCachePolicy {
    case once // cache only once
    case interval(time_t) // update every certain interval
    case up2Date // track changes
    case lazyUp2Date // detect changes when requested, update and return if changes were made
    case noReserve // do not reserve binary, cache only file descriptor
    case oldCopy // return cached content first then update content if changed while requested
}
