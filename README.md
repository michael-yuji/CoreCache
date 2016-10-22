# CoreCache

Library to cache File/Dynamic Content in painless way.

## Usage

To cache File from file system in default CacheContainer:
```swift
let my_ident = "some_file_" /* identifier(key) to cache */

// the `how` argument define how the cacheContainer should update the file
// when how is set to .up2date, the CacheContainer will update the content 
// in cache automatically when file is changed
CacheContainer.shared.cache(identifier: my_ident, file: "/path/to/your/file", how: .up2date, lifetime: .forever) 

// when you want to read from cache:

let file_data = CacheContainer.shared[my_ident]
```

Sometime, we generate some data periodically in code. We can cache these kind of content and let the CacheContainer update it for you automatically.

```swift
let my_ident = "some_generator"
let source: () -> Data = { "\(time(nil))".data(using:.ascii) ?? Data() }

// this will update the underlying data every one second using the block `source`
CacheContainer.shared.cache(identifier: my_ident, dynamic: source, policy: .interval(CCTimeInterval(sec: 1)), lifetime: .forever)

// just read it like any cache
let data = CacheContainer.shared[my_ident]
```

BUG: lifetime feature is not finished yet
The project in still in very early development stage.
