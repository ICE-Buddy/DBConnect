import XCTest
@testable import DBConnect
import TrainConnect

final class ICETrainIdentificationTests: XCTestCase {
    func testReportedSeriesAndEveryVehicleImage() {
        for series in ["408", "BR408", "br 408", "408.0"] {
            XCTAssertEqual(ICETrainType(tzn: "Tz 9001", series: series).model, .BR408)
        }
        XCTAssertEqual(ICETrainType(tzn: "Tz 1801", series: "105").model, .ICE_L)
        XCTAssertEqual(ICETrainType(tzn: "Tz 9001", series: "807").model, .BR412)
        for model in ICETrainType.Model.allCases {
            let type = ICETrainType(tzn: "unidentified", series: model.rawValue)
            #if os(macOS)
            guard let image = type.trainIcon else { XCTFail("Missing image: \(model)"); continue }
            XCTAssertGreaterThan(image.size.width, image.size.height * 3, "Missing artwork: \(model)")
            #endif
        }
    }

    func testTrainsetIdentifiers() {
        let cases: [(String, ICETrainType.Model)] = [
            ("Tz240", .BR402), ("Tz9453", .BR412), ("Tz 9453", .BR412),
            ("ICE0334", .BR403), ("ICE1159", .BR411), ("ICE08014", .BR408),
            (" Tz 8014 ", .BR408), ("8014", .BR408), ("TZN 8080", .BR408),
            ("ICE9999", .unknown), ("ICE 221 to Berlin", .unknown)
        ]
        for (identifier, expected) in cases {
            XCTAssertEqual(ICETrainType(tzn: identifier).model, expected, identifier)
        }
    }
}
