import XCTest
import TrainConnect
import DBConnect
import SNCFConnect
@testable import OnboardConnect

final class OnboardContractTests: XCTestCase {
    func testOperatorSnapshotsAndPackagedImages() {
        let controllers: [TrainDataController] = [ICEDataController.shared, TGVDataController.shared,
                                                  RailnetDataController.shared, CDDataController.shared, DBRegioDataController.shared]
        for controller in controllers {
            let loaded = expectation(description: "\(type(of: controller))")
            controller.loadSnapshot(demoMode: true) { snapshot, error in
                XCTAssertNil(error)
                guard let snapshot = snapshot else { XCTFail("Missing snapshot"); loaded.fulfill(); return }
                XCTAssertFalse(snapshot.trip.trainStops.isEmpty)
                XCTAssertFalse(snapshot.trip.serviceName.isEmpty)
                XCTAssertNotNil(snapshot.trainType?.trainIcon, "Every supported train must have an image")
                #if os(macOS)
                if let image = snapshot.trainType?.trainIcon {
                    XCTAssertGreaterThan(image.size.width, image.size.height * 3, "Use the bundled train artwork, not the symbol fallback")
                }
                #endif
                if controller is DBRegioDataController {
                    XCTAssertNil(snapshot.status, "A portal without telemetry must not invent speed")
                    XCTAssertEqual(snapshot.trip.serviceNumber, "7426")
                }
                if controller is TGVDataController {
                    XCTAssertEqual(snapshot.status?.currentSpeed.unit, .metersPerSecond)
                }
                if controller is RailnetDataController {
                    XCTAssertEqual(snapshot.status?.currentSpeed.value, 60)
                    XCTAssertEqual(snapshot.trip.trainStops[1].arrivalDelay, "+58")
                    XCTAssertEqual(snapshot.trip.trainStops[1].trainTrack?.actual, "5")
                }
                if controller is CDDataController {
                    XCTAssertNil(snapshot.trip.trainStops[1].actualArrival)
                    XCTAssertEqual(snapshot.trip.trainStops[1].arrivalDelay, "")
                }
                loaded.fulfill()
            }
            wait(for: [loaded], timeout: 3)
        }
    }

    func testRailnetMidnightForecastRollover() throws {
        let reference = try XCTUnwrap(TrainDateParser.instant("2026-10-22T23:30:00+02:00"))
        var clock = RailnetClock(reference: reference, firstTime: "23:40")
        let first = try XCTUnwrap(clock.scheduled("23:40"))
        let forecast = try XCTUnwrap(clock.forecast("00:05", scheduled: first))
        let next = try XCTUnwrap(clock.scheduled("00:20"))
        XCTAssertEqual(forecast.timeIntervalSince(first), 25 * 60)
        XCTAssertEqual(next.timeIntervalSince(first), 40 * 60)
        var afterMidnight = RailnetClock(reference: try XCTUnwrap(TrainDateParser.instant("2026-10-23T00:10:00+02:00")), firstTime: "23:40")
        XCTAssertEqual(afterMidnight.scheduled("23:40"), first)
    }

    func testCancellationAndSubFiveMinuteDelayRemainVisible() throws {
        let json = #"{"name":"RE 1","no":1234,"stops":[{"station":{"evaNo":"1","name":"First"},"arrivalTime":{"target":"2026-10-22T12:00:00Z","predicted":"2026-10-22T12:03:00Z"},"status":"Canceled"},{"station":{"evaNo":"2","name":"Second"},"arrivalTime":{"target":"2099-10-22T12:00:00Z"}}]}"#
        let trip = try JSONDecoder().decode(RegioResponse.self, from: Data(json.utf8)).journey()
        XCTAssertEqual(trip.trainStops.first?.arrivalDelay, "+3")
        XCTAssertTrue(try XCTUnwrap(trip.trainStops.first).isCancelled)
        XCTAssertEqual(trip.trainStops.nextStop?.trainStation.name, "Second")
        XCTAssertNil(trip.trainStops[1].actualArrival)
    }

    func testStopIdentitySurvivesPolling() throws {
        let response = try JSONDecoder().decode(CDJourneyResponse.self, from: OnboardPortal.cdJourney.sampleData)
        let first = response.journey().trainStops
        let refreshed = response.journey().trainStops
        XCTAssertEqual(first.map(\.id), refreshed.map(\.id))
        XCTAssertEqual(Set(first.map(\.id)).count, first.count)
    }
}
