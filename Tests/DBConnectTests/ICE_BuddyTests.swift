//
//  ICE_BuddyTests.swift
//  ICE BuddyTests
//
//  Created by Frederik Riedel on 16.11.21.
//

import XCTest
@testable import ICE_Buddy
@testable import DBConnect

class ICE_BuddyTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTriebzugNummern() throws {
        let tz240 = ICETrainType(tzn: "Tz240").model
        XCTAssertEqual(tz240, .BR402)
        
        let tz9453 = ICETrainType(tzn: "Tz9453").model
        XCTAssertEqual(tz9453, .BR412)

        let tz_9453 = ICETrainType(tzn: "Tz 9453").model
        XCTAssertEqual(tz_9453, .BR412)

        let ICE0334 = ICETrainType(tzn: "ICE0334").model
        XCTAssertEqual(ICE0334, .BR403)

        let ICE1159 = ICETrainType(tzn: "ICE1159").model
        XCTAssertEqual(ICE1159, .BR411)
    }
}
