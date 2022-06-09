//
//  File.swift
//  
//
//  Created by Max Seiferth on 09.06.22.
//

import Foundation

public struct TripResponse: Decodable {
    public let trip: Trip
}

public struct Trip: Decodable {
    public let tripDate: Date
    public let trainType: String
    public let vzn: String
    public let stopInfo: JourneyStopInfo
    public let stops: [JourneyStop]
}

public struct JourneyStopInfo: Decodable {
    public let finalStationName: String
    public let finalStationEvaNr: String
}

public struct JourneyStop: Decodable, Hashable, Identifiable {
    public let id = UUID()
    public let station: Station
    public let timetable: Timetable
    public let track: Track
    public let info: Info
    public let delayReasons: [DelayReasons]?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: JourneyStop, rhs: JourneyStop) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct Station: Decodable {
    public let evaNr: String
    public let name: String
    public let geocoordinates: Coordinate?
}

public struct Timetable: Decodable {
    public let scheduledArrivalTime: Double?
    public var scheduledArrivalTimeDate: Date? {
        if let scheduledArrivalTime = scheduledArrivalTime {
            return Date(timeIntervalSince1970: (scheduledArrivalTime / 1000))
        }
        return nil
    }

    
    public let actualArrivalTime: Double?
    public var actualArrivalTimeDate: Date? {
        if let actualArrivalTime = actualArrivalTime {
            return Date(timeIntervalSince1970: (actualArrivalTime / 1000))
        }
        return nil
    }
    
    public let showActualArrivalTime: Bool?
    public let arrivalDelay: String
    
    public let scheduledDepartureTime: Double?
    public var scheduledDepartureTimeDate: Date? {
        if let scheduledDepartureTime = scheduledDepartureTime {
            return Date(timeIntervalSince1970: (scheduledDepartureTime / 1000))
        }
        return nil
    }
    
    public let actualDepartureTime: Double?
    public var actualDepartureTimeDate: Date? {
        if let actualDepartureTime = actualDepartureTime {
            return Date(timeIntervalSince1970: (actualDepartureTime / 1000))
        }
        return nil
    }
    
    public let showActualDepartureTime: Bool?
    public let departureDelay: String
}

public struct Track: Decodable {
    public let scheduled: String
    public let actual: String
}

public struct Info: Decodable {
    public let distance: Int
    public let passed: Bool
    public let status: Int
}

public struct DelayReasons: Decodable {
    public let code: String
    public let text: String
}

public struct Coordinate: Decodable {
    public let latitude: Double
    public let longitude: Double
}


public struct Status: Decodable {
    public let latitude: Double
    public let longitude: Double
    public let series: String
    public let speed: Double
    public let tzn: String
    public let connectivity: Connectivity
}

public struct Connectivity: Decodable {
    public let currentState: String?
    public let nextState: String?
    public let remainingTimeSeconds: Int?
}
