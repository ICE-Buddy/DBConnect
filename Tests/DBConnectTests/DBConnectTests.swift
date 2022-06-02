import XCTest
@testable import DBConnect

final class DBConnectTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(DBConnect().text, "Hello, World!")
    }
}
