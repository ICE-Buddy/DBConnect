import XCTest
import TrainConnect
import DBConnect

final class ProviderSelectionTests: XCTestCase {
    func testNoProvidersCompletesWithError() {
        let completion = expectation(description: "No providers is a terminal failure")
        CombinedDataController().loadTrip(demoMode: false) { trip, error in
            XCTAssertNil(trip)
            XCTAssertNotNil(error)
            completion.fulfill()
        }
        wait(for: [completion], timeout: 0.3)
    }

    func testNilResponsesAndDuplicateCallbacksCompleteOnce() {
        let completion = expectation(description: "Malformed responses terminate once")
        completion.assertForOverFulfill = true
        let controllers = CombinedDataController(controllers: InvalidProvider(), InvalidProvider())
        var calls = 0
        controllers.loadTrip(demoMode: false) { trip, error in
            calls += 1
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(trip)
            XCTAssertNotNil(error)
            completion.fulfill()
        }
        wait(for: [completion], timeout: 0.3)
        XCTAssertEqual(calls, 1)
    }
}

private struct InvalidProvider: TrainDataController {
    func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> Void) {
        completionHandler(nil, nil)
        completionHandler(nil, TrainConnectionError.notConnected)
    }
    func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> Void) {
        completionHandler(nil, nil)
    }
}

private final class ScriptedTripProvider: TrainDataController {
    let trip: TrainTrip?
    let duplicate: Bool
    var tripRequests = 0
    init(trip: TrainTrip?, duplicate: Bool = false) { self.trip = trip; self.duplicate = duplicate }
    func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> Void) {
        tripRequests += 1
        DispatchQueue.global().async {
            completionHandler(self.trip, self.trip == nil ? TrainConnectionError.notConnected : nil)
            if self.duplicate { completionHandler(nil, TrainConnectionError.notConnected) }
        }
    }
    func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> Void) {
        completionHandler(nil, TrainConnectionError.unsupportedCapability)
    }
}

extension ProviderSelectionTests {
    func testSuccessIsNotFollowedByLateFailure() {
        let loaded = expectation(description: "Sample journey")
        let finished = expectation(description: "Only the winning provider completes")
        finished.assertForOverFulfill = true
        ICEDataController.shared.loadTrip(demoMode: true) { trip, error in
            XCTAssertNil(error)
            guard let trip = trip else { XCTFail("Missing fixture"); loaded.fulfill(); return }
            let combined = CombinedDataController(controllers: ScriptedTripProvider(trip: trip, duplicate: true), ScriptedTripProvider(trip: nil))
            combined.loadTrip(demoMode: false) { value, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(value)
                XCTAssertNil(error)
                finished.fulfill()
            }
            loaded.fulfill()
        }
        wait(for: [loaded, finished], timeout: 2)
    }

    func testOverlappingSnapshotPollsAreCoalescedAndCached() {
        let loaded = expectation(description: "Sample journey")
        let delivered = expectation(description: "Two overlapping and one cached consumer")
        delivered.expectedFulfillmentCount = 3
        ICEDataController.shared.loadTrip(demoMode: true) { trip, _ in
            guard let trip = trip else { XCTFail("Missing fixture"); loaded.fulfill(); return }
            let provider = ScriptedTripProvider(trip: trip)
            let combined = CombinedDataController(controllers: provider)
            combined.loadSnapshot(demoMode: false) { first, error in
                XCTAssertNotNil(first?.trip)
                XCTAssertNil(error)
                combined.loadSnapshot(demoMode: false) { cached, error in
                    XCTAssertEqual(first?.fetchedAt, cached?.fetchedAt)
                    XCTAssertEqual(provider.tripRequests, 1)
                    delivered.fulfill()
                }
                delivered.fulfill()
            }
            combined.loadSnapshot(demoMode: false) { snapshot, error in
                XCTAssertNotNil(snapshot)
                XCTAssertNil(error)
                XCTAssertEqual(provider.tripRequests, 1)
                delivered.fulfill()
            }
            loaded.fulfill()
        }
        wait(for: [loaded, delivered], timeout: 2)
    }
}
