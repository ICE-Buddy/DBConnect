import Foundation
import Moya

/// Verified onboard endpoints. No SSID spelling checks or cloud timetable assumptions.
enum OnboardPortal: TargetType {
    case railnet, cdJourney, cdStatus, dbRegio

    var baseURL: URL {
        switch self {
        case .railnet: return URL(string: "https://railnet.oebb.at")!
        case .cdJourney, .cdStatus: return URL(string: "http://cdwifi.cz")!
        case .dbRegio: return URL(string: "https://zugportal.de")!
        }
    }
    var path: String {
        switch self {
        case .railnet: return "/assets/media/fis/combined.json"
        case .cdJourney: return "/portal/api/timetable/connexion/current"
        case .cdStatus: return "/portal/api/vehicle/realtime"
        case .dbRegio: return "/@prd/zupo-travel-information/api/public/ri/journey"
        }
    }
    var task: Task {
        if case .cdJourney = self { return .requestParameters(parameters: ["locale": "en_GB"], encoding: URLEncoding.queryString) }
        return .requestPlain
    }
    var method: Moya.Method { .get }
    var headers: [String: String]? { ["Accept": "application/json"] }
    var sampleData: Data {
        let name: String
        switch self {
        case .railnet: name = "railnet"
        case .cdJourney: name = "cd-journey"
        case .cdStatus: name = "cd-status"
        case .dbRegio: name = "db-regio"
        }
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else { return Data() }
        return (try? Data(contentsOf: url)) ?? Data()
    }
}
