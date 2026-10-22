import Foundation
import CoreLocation
import Moya
import TrainConnect

/// DB Zugportal. Availability depends on the train's portal, not the capitalization of WIFI@DB.
/// A working journey is useful even though this API has no live speed or vehicle series.
public final class DBRegioDataController: TrainDataController {
    public static let shared = DBRegioDataController()
    public init() {}

    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> Void) {
        let provider = MoyaProvider<OnboardPortal>(stubClosure: demoMode ? MoyaProvider.immediatelyStub : MoyaProvider.neverStub,
                                                 session: alamofireSessionWithFasterTimeout)
        provider.loadJson(target: .dbRegio) { (response: RegioResponse?, error) in
            guard let response = response, !response.stops.isEmpty else {
                if error == nil { APIDiagnostics.shared.recordInvalidResponse(endpoint: .dbRegio) }
                completionHandler(nil, error ?? TrainConnectionError.invalidResponse); return
            }
            completionHandler(response.journey(), nil)
        }
    }
    public func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> Void) {
        completionHandler(nil, TrainConnectionError.unsupportedCapability)
    }
}

struct RegioResponse: Decodable {
    let name: String
    let no: Int
    let stops: [CallingPoint]
    struct CallingPoint: Decodable {
        let station: Station
        let track: Track?
        let arrivalTime: Time?
        let departureTime: Time?
        let canceled: Bool?
        let status: String?
        let messages: [Message]?
    }
    struct Station: Decodable {
        let evaNo: String
        let name: String
        let position: Position?
    }
    struct Position: Decodable { let latitude: Double; let longitude: Double }
    struct Track: Decodable { let target: String?; let prediction: String? }
    struct Time: Decodable { let target: String?; let predicted: String? }
    struct Message: Decodable { let type: String; let textShort: String?; let text: String? }

    func journey() -> OnboardJourney {
        let stops = stops.map { stop -> OnboardStop in
            let arrival = TrainDateParser.instant(stop.arrivalTime?.target)
            let departure = TrainDateParser.instant(stop.departureTime?.target)
            let actualArrival = TrainDateParser.instant(stop.arrivalTime?.predicted)
            let actualDeparture = TrainDateParser.instant(stop.departureTime?.predicted)
            var coordinate: CLLocationCoordinate2D?
            if let position = stop.station.position, (-90...90).contains(position.latitude), (-180...180).contains(position.longitude) {
                coordinate = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
            }
            let track = stop.track.map { OnboardTrack(scheduled: $0.target ?? "", actual: $0.prediction ?? $0.target ?? "") }
            return OnboardStop(id: TrainStopIdentifier.uuid(provider: "db-regio:" + String(no), station: stop.station.evaNo, scheduledTime: departure ?? arrival), station: OnboardStation(code: stop.station.evaNo, name: stop.station.name, coordinates: coordinate),
                               scheduledArrival: arrival, actualArrival: actualArrival, scheduledDeparture: departure, actualDeparture: actualDeparture,
                               track: track, hasPassed: (actualDeparture ?? departure ?? actualArrival ?? arrival).map { $0 < Date() } ?? false,
                               isCancelled: stop.canceled == true || stop.status == "Canceled",
                               delayReason: stop.messages?.first(where: { $0.type == "CUSTOMER_REASON" }).flatMap { $0.textShort ?? $0.text })
        }
        return OnboardJourney(train: name, vzn: String(no), stops: stops,
                              vehicleType: OnboardTrainType(trainModel: "DB regional train · vehicle series unavailable", asset: "regional"))
    }
}
