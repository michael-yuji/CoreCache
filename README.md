# CoreCache

CoreCache is a Library that allow you to easily cache file/dynamic content. Once you use CoreCache to cache those data, you can also specify how the caches update/synchronize with underlying file/generator. Futhermore, CoreCache allow you to control the lifetime of caches.

## Usage

To cache a file from file system in default CacheContainer:
```swift
let my_ident = "some_id" /* identifier(key) to cache */

// the `using` argument define how the cacheContainer should update the file
// when how is set to .up2date, the CacheContainer will update the content 
// in cache automatically when file is changed
CacheContainer.shared.cacheFile(at: "/path/to/file", as: my_ident, using: .up2Date, lifetime: .forever, errhandler: nil)

// when you want to read from cache:

let file_data = CacheContainer.shared[my_ident]
```

Sometime, we generate some data periodically in code. We can cache these kind of content and let the CacheContainer update it for you automatically.

```swift
let my_ident = "some_identifier"
let updateInterval = CCTimeInterval(sec: 1)
let source: () -> Data = { "\(time(nil))".data(using:.ascii) ?? Data() }

// this will update the underlying data every one second using the block `source`
CacheContainer.shared.cacheDynamicContent(as: my_ident, using: .interval(updateInterval), lifetime: .forever, generator: source)

// just read it like any cache
let data = CacheContainer.shared[my_ident]
```

## Cache Options

```Swift
// If an unavailable policy assigned to DynamicContent Cache, the CacheContainer will use .once by default
public enum CachePolicy {
    case once // cache only once and not update
    case interval(CCTimeInterval) // update every certain interval
    case up2Date // File only option, track changes of the underlying file
    case lazyUp2Date // File only option, track changes and update when the cache is requested.
    case noReserve // File only option, cache only file descriptor ** not implemented yet
    case oldCopy // File only option, same as lazyUp2Date, but return the old copy instead of up-to-date one
}
```

## Lifetime Management

```Swift
public enum CacheLifeTimePolicy {
    case forever // do not implictly remove the cache
    case strictInterval(CCTimerInterval) // Remove the cache after interval of time it cached
    case idleInterval(CCTimerInterval) // Remove the cache if its untouched for interval of time
}
```

## Resolution

In CoreCache, the CacheContainer is run by its own Timer, which limit its resolution of time and thus improve performance. The default shared Container has resolution of 0.1 second. You can create a higher/lower resolution of CacheContainer that fit your need.

```Swift
let rate = CCTimeInterval(microsec: 10)
let myHiResContainer = CacheContainer(refreshResulotion: rate)
``` 


Warning: This project is still in very early development stage.
