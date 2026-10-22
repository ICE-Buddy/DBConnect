import Foundation
import CoreLocation
import Moya
import TrainConnect

/// ČD's Passengera portal, including ČD Railjet. Uses only data actually supplied onboard.
public final class CDDataController: TrainDataController {
    public static let shared = CDDataController()
    public init() {}

    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> Void) {
        provider(demoMode).loadJson(target: .cdJourney) { (response: CDJourneyResponse?, error) in
            guard let response = response, !response.connexionTimes.isEmpty else {
                if error == nil { APIDiagnostics.shared.recordInvalidResponse(endpoint: .cdJourney) }
                completionHandler(nil, error ?? TrainConnectionError.invalidResponse); return
            }
            completionHandler(response.journey(), nil)
        }
    }
    public func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> Void) {
        provider(demoMode).loadJson(target: .cdStatus) { (response: CDStatusResponse?, error) in
            guard let response = response, response.speed.isFinite, response.speed >= 0,
                  (-90...90).contains(response.gpsLat), (-180...180).contains(response.gpsLng) else {
                if error == nil { APIDiagnostics.shared.recordInvalidResponse(endpoint: .cdStatus) }
                completionHandler(nil, error ?? TrainConnectionError.invalidResponse); return
            }
            completionHandler(OnboardStatus(latitude: response.gpsLat, longitude: response.gpsLng,
                                            currentSpeed: Measurement(value: response.speed, unit: .kilometersPerHour),
                                            trainType: OnboardTrainType(trainModel: "České dráhy · vehicle series unavailable", asset: "cd")), nil)
        }
    }
    private func provider(_ demo: Bool) -> MoyaProvider<OnboardPortal> {
        MoyaProvider(stubClosure: demo ? MoyaProvider.immediatelyStub : MoyaProvider.neverStub,
                     session: alamofireSessionWithFasterTimeout)
    }
}

struct CDJourneyResponse: Decodable {
    let name: String
    let connexionTimes: [CallingPoint]
    struct CallingPoint: Decodable {
        let timeArrival: String?
        let timeDeparture: String?
        let station: Station
    }
    struct Station: Decodable {
        let id: Int
        let name: String
        let gpsLat: Double?
        let gpsLng: Double?
    }
    func journey() -> OnboardJourney {
        let stops = connexionTimes.map { stop -> OnboardStop in
            let arrival = TrainDateParser.instant(stop.timeArrival)
            let departure = TrainDateParser.instant(stop.timeDeparture)
            var coordinates: CLLocationCoordinate2D?
            if let lat = stop.station.gpsLat, let lon = stop.station.gpsLng,
               (-90...90).contains(lat), (-180...180).contains(lon) {
                coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            // This endpoint supplies scheduled times, not real-time forecasts or delay values.
            return OnboardStop(id: TrainStopIdentifier.uuid(provider: "cd:" + name, station: String(stop.station.id), scheduledTime: departure ?? arrival), station: OnboardStation(code: String(stop.station.id), name: stop.station.name, coordinates: coordinates),
                               scheduledArrival: arrival, actualArrival: nil, scheduledDeparture: departure, actualDeparture: nil,
                               track: nil, hasPassed: (departure ?? arrival).map { $0 < Date() } ?? false, isCancelled: false, delayReason: nil)
        }
        // Keep the full reported service name. A service number does not identify a vehicle series.
        return OnboardJourney(train: name, vzn: "", stops: stops,
                              vehicleType: OnboardTrainType(trainModel: "České dráhy · vehicle series unavailable", asset: "cd"))
    }
}

struct CDStatusResponse: Decodable {
    let gpsLat: Double
    let gpsLng: Double
    let speed: Double
}
