import Foundation

/// Operator adapters expose the same journey and telemetry contracts.
/// A journey may be available even when the train provides no live telemetry.
public protocol TrainDataController {
    func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> Void)
    func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> Void)
    func loadSnapshot(demoMode: Bool, completionHandler: @escaping (TrainSnapshot?, Error?) -> Void)
}

public extension TrainDataController {
    func loadSnapshot(demoMode: Bool, completionHandler: @escaping (TrainSnapshot?, Error?) -> Void) {
        loadTrip(demoMode: demoMode) { trip, error in
            guard let trip = trip, !trip.trainStops.isEmpty else {
                completionHandler(nil, error ?? TrainConnectionError.invalidResponse)
                return
            }
            self.loadTrainStatus(demoMode: demoMode) { status, _ in
                completionHandler(TrainSnapshot(trip: trip, status: status), nil)
            }
        }
    }
}

/// A coherent result from one operator. Never combine one train's stops with another's speed.
public struct TrainSnapshot {
    public let trip: TrainTrip
    public let status: TrainStatus?
    public let fetchedAt: Date
    public var trainType: TrainType? { status?.trainType ?? trip.vehicleType }

    public init(trip: TrainTrip, status: TrainStatus?, fetchedAt: Date = Date()) {
        self.trip = trip
        self.status = status
        self.fetchedAt = fetchedAt
    }
}

public final class CombinedDataController: TrainDataController {
    public static var _shared: TrainDataController = CombinedDataController()
    private let controllers: [TrainDataController]
    // Accessed only on the main queue. Concurrent UI consumers share one poll.
    private var pending: [Bool: [(TrainSnapshot?, Error?) -> Void]] = [:]
    private var cached: [Bool: TrainSnapshot] = [:]

    public init(controllers: TrainDataController...) {
        self.controllers = controllers
    }

    public func loadSnapshot(demoMode: Bool, completionHandler: @escaping (TrainSnapshot?, Error?) -> Void) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.loadSnapshot(demoMode: demoMode, completionHandler: completionHandler) }
            return
        }
        if let snapshot = cached[demoMode], Date().timeIntervalSince(snapshot.fetchedAt) < 5 {
            completionHandler(snapshot, nil)
            return
        }
        if pending[demoMode] != nil {
            pending[demoMode]?.append(completionHandler)
            return
        }
        pending[demoMode] = [completionHandler]
        race(demoMode: demoMode, completion: { (snapshot: TrainSnapshot?, error) in
            if let snapshot = snapshot { self.cached[demoMode] = snapshot }
            let callbacks = self.pending.removeValue(forKey: demoMode) ?? []
            callbacks.forEach { $0(snapshot, error) }
        }) { controller, completion in
            controller.loadSnapshot(demoMode: demoMode, completionHandler: completion)
        }
    }

    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> Void) {
        race(demoMode: demoMode, completion: completionHandler) {
            $0.loadTrip(demoMode: demoMode, completionHandler: $1)
        }
    }

    public func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> Void) {
        race(demoMode: demoMode, completion: completionHandler) {
            $0.loadTrainStatus(demoMode: demoMode, completionHandler: $1)
        }
    }

    private func race<Value>(demoMode: Bool, completion: @escaping (Value?, Error?) -> Void,
                             action: (TrainDataController, @escaping (Value?, Error?) -> Void) -> Void) {
        // Demo data must be deterministic, independent of provider response timing.
        let candidates = demoMode ? Array(controllers.prefix(1)) : controllers
        let race = ProviderRace<Value>(count: candidates.count, completion: completion)
        for (index, controller) in candidates.enumerated() {
            action(controller) { race.receive(index: index, value: $0, error: $1) }
        }
    }
}

public enum TrainConnectionError: Error {
    case notConnected
    case invalidResponse
    case unsupportedCapability
}

/// Suppresses duplicate and late callbacks, including callbacks from different queues.
private final class ProviderRace<Value> {
    private let lock = NSLock()
    private var received = Set<Int>()
    private let count: Int
    private var completion: ((Value?, Error?) -> Void)?

    init(count: Int, completion: @escaping (Value?, Error?) -> Void) {
        self.count = count
        self.completion = completion
        if count == 0 {
            self.completion = nil
            DispatchQueue.main.async { completion(nil, TrainConnectionError.notConnected) }
        }
    }

    func receive(index: Int, value: Value?, error: Error?) {
        lock.lock()
        guard let callback = completion, received.insert(index).inserted else {
            lock.unlock()
            return
        }
        let success = value != nil && error == nil
        guard success || received.count == count else {
            lock.unlock()
            return
        }
        completion = nil
        lock.unlock()
        DispatchQueue.main.async {
            callback(success ? value : nil, success ? nil : (error ?? TrainConnectionError.invalidResponse))
        }
    }
}
