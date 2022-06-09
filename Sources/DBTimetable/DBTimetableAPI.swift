//
//  DBTimetableAPI.swift
//  ICE Buddy
//
//  Created by Maximilian Seiferth on 16.02.22.
//

import Foundation
import Moya
import DBConnect

// API used here: https://v5.db.transport.rest/api.html#get-stopsiddepartures

enum DBTimetableAPI {
    case departures(for: JourneyStop)
    case arrivals(for: JourneyStop)
}

extension DBTimetableAPI: TargetType {
    var baseURL: URL {
        URL(string: "https://v5.db.transport.rest")!
    }
    
    var path: String {
        switch self {
        case .arrivals(let stop):
            var evaNr = stop.station.evaNr
            if let index = evaNr.firstIndex(of: "_") {
                evaNr = String(evaNr.prefix(upTo: index))
            }
            return "/stops/\(evaNr)/arrivals"
        case .departures(let stop):
            var evaNr = stop.station.evaNr
            if let index = evaNr.firstIndex(of: "_") {
                evaNr = String(evaNr.prefix(upTo: index))
            }
            return "/stops/\(evaNr)/departures"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .departures(let stop), .arrivals(let stop):
            let params = [
                "when": ISO8601DateFormatter().string(from: (stop.timetable.actualArrivalTimeDate ?? stop.timetable.scheduledDepartureTimeDate) ?? Date()),
                "includeRelatedStations": "false",
                "duration": 180,
                "bus": "false",
                "ferry": "false",
                "subway": "false",
                "tram": "false",
                "taxi": "false"
            ] as [String : Any]
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        return [:]
    }
    
    
}
