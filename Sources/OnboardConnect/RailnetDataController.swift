import Foundation
import Moya
import TrainConnect

/// ÖBB Railnet (Railjet/RJX). The combined response supplies both journey and telemetry.
public final class RailnetDataController: TrainDataController {
    public static let shared = RailnetDataController()
    public init() {}

    public func loadSnapshot(demoMode: Bool, completionHandler: @escaping (TrainSnapshot?, Error?) -> Void) {
        let provider = MoyaProvider<OnboardPortal>(stubClosure: demoMode ? MoyaProvider.immediatelyStub : MoyaProvider.neverStub,
                                                 session: alamofireSessionWithFasterTimeout)
        provider.loadJson(target: .railnet) { (response: RailnetResponse?, error) in
            guard let response = response else { completionHandler(nil, error); return }
            do { completionHandler(try response.snapshot(), nil) }
            catch {
                APIDiagnostics.shared.recordInvalidResponse(endpoint: .railnet)
                completionHandler(nil, error)
            }
        }
    }
    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> Void) {
        loadSnapshot(demoMode: demoMode) { completionHandler($0?.trip, $1) }
    }
    public func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> Void) {
        loadSnapshot(demoMode: demoMode) { completionHandler($0?.status, $1 ?? ($0?.status == nil ? TrainConnectionError.unsupportedCapability : nil)) }
    }
}

struct RailnetResponse: Decodable {
    let trainType: String
    let lineNumber: String
    let stations: [CallingPoint]
    let latestStatus: Live
    let nextStation: StationReference?

    struct StationReference: Decodable { let id: String }
    struct Time: Decodable { let scheduled: String?; let forecast: String? }
    struct CallingPoint: Decodable {
        let id: String
        let name: [String: String]
        let track: [String: String]?
        let arrival: Time
        let departure: Time
    }
    struct Live: Decodable {
        let dateTime: String
        let gpsPosition: Position?
        let speed: Double?
    }
    struct Position: Decodable { let latitude: String; let longitude: String }

    func snapshot() throws -> TrainSnapshot {
        guard !stations.isEmpty, let reference = TrainDateParser.instant(latestStatus.dateTime) else {
            throw TrainConnectionError.invalidResponse
        }
        let vehicle = OnboardTrainType(trainModel: "ÖBB \(trainType) · vehicle series unavailable", asset: "railjet")
        let firstTime = stations.first?.arrival.scheduled.flatMap { $0.isEmpty ? nil : $0 } ?? stations.first?.departure.scheduled
        var clock = RailnetClock(reference: reference, firstTime: firstTime)
        let nextIndex = stations.firstIndex { $0.id == nextStation?.id }
        let stops = stations.enumerated().map { index, stop -> OnboardStop in
            let arrival = clock.scheduled(stop.arrival.scheduled)
            let departure = clock.scheduled(stop.departure.scheduled)
            let actualArrival = clock.forecast(stop.arrival.forecast, scheduled: arrival)
            let actualDeparture = clock.forecast(stop.departure.forecast, scheduled: departure)
            let platform = stop.track?["de"] ?? stop.track?.values.sorted().first
            return OnboardStop(id: TrainStopIdentifier.uuid(provider: "oebb:" + lineNumber, station: stop.id, scheduledTime: departure ?? arrival), station: OnboardStation(code: stop.id, name: stop.name["de"] ?? stop.name.values.sorted().first ?? stop.id, coordinates: nil),
                               scheduledArrival: arrival, actualArrival: actualArrival,
                               scheduledDeparture: departure, actualDeparture: actualDeparture,
                               track: platform.map { OnboardTrack(scheduled: "", actual: $0) },
                               hasPassed: nextIndex.map { index < $0 } ?? ((actualDeparture ?? departure ?? actualArrival ?? arrival).map { $0 < reference } ?? false),
                               isCancelled: false, delayReason: nil)
        }
        var status: OnboardStatus?
        if let position = latestStatus.gpsPosition, let latitude = Double(position.latitude), let longitude = Double(position.longitude),
           let speed = latestStatus.speed, speed.isFinite, speed >= 0,
           (-90...90).contains(latitude), (-180...180).contains(longitude) {
            status = OnboardStatus(latitude: latitude, longitude: longitude, currentSpeed: Measurement(value: speed, unit: .kilometersPerHour), trainType: vehicle)
        }
        return TrainSnapshot(trip: OnboardJourney(train: trainType, vzn: lineNumber, stops: stops, vehicleType: vehicle), status: status)
    }
}
