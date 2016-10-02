import XCTest
@testable import CoreCache

class CoreCacheTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(CoreCache().text, "Hello, World!")
    }


    static var allTests : [(String, (CoreCacheTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
