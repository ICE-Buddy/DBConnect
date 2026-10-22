import Foundation

/// Only catalogued, static endpoints may appear in a report. Never retain a request URL.
public enum APIDiagnosticEndpoint: String, CaseIterable, Encodable {
    case iceTrip = "iceportal.de/api1/rs/tripInfo/trip"
    case iceStatus = "iceportal.de/api1/rs/status"
    case tgvDetails = "wifi.sncf/router/api/train/details"
    case tgvGPS = "wifi.sncf/router/api/train/gps"
    case tgvStatistics = "wifi.sncf/router/api/connection/statistics"
    case tgvCoverage = "wifi.sncf/router/api/train/coverage"
    case railnet = "railnet.oebb.at/assets/media/fis/combined.json"
    case cdJourney = "cdwifi.cz/portal/api/timetable/connexion/current"
    case cdStatus = "cdwifi.cz/portal/api/vehicle/realtime"
    case dbRegio = "zugportal.de/@prd/zupo-travel-information/api/public/ri/journey"
    case other = "other endpoint"

    init(baseURL: URL, path: String) {
        let identifier = (baseURL.host?.lowercased() ?? "") + baseURL.appendingPathComponent(path).path
        self = Self.allCases.first { $0.rawValue == identifier } ?? .other
    }
}
