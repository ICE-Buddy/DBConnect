//
//  SNCFModel.swift
//  
//
//  Created by Leo Mehlig on 13.07.22.
//

import Foundation
import TrainConnect
import CoreLocation
#if os(macOS)
import AppKit
#else
import UIKit
import SwiftUI
#endif

// MARK: - DetailsResponse
public struct DetailsResponse: Codable, TrainTrip {
    public var train: String {
        self.carrier
    }
    
    public var trainStops: [TrainStop] {
        self.stops
    }
    
    public var vzn: String {
        self.number
    }
    
    public var finalStopInfo: TrainFinalStopInfo? {
            nil
    }
    
    public let number: String
    public let carrier: String
    //  public let events: [Any]
//    public let onboardServices: [String]
//    public let additionalServices: AdditionalServices
    public let stops: [Stop]
    public let trainId: String
}

// MARK: - AdditionalServices
public struct AdditionalServices: Codable {
}

// MARK: - Stop
public struct Stop: Codable, TrainStop {
    public var id: UUID { TrainStopIdentifier.uuid(provider: "sncf", station: code, scheduledTime: scheduledDeparture ?? scheduledArrival) }
    
    public var trainStation: TrainStation {
        Station(code: self.code,
                name: self.label,
                coordinates: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude))
    }
    
    public var scheduledArrival: Date? {
        self.theoricDate
    }
    
    public var actualArrival: Date? {
        self.realDate
    }
    
    public var scheduledDeparture: Date? {
        self.scheduledArrival?.addingTimeInterval(TimeInterval(self.duration) * 60)
    }
    
    public var actualDeparture: Date? {
        self.actualArrival?.addingTimeInterval(TimeInterval(self.duration) * 60)
    }
    
    public var hasPassed: Bool {
        (self.progress?.progressPercentage ?? 0) >= 100
    }
    
    public var departureDelay: String {
        if isDelayed {
            return "+\(self.delay)"
        } else {
            return ""
        }
    }
    
    public var arrivalDelay: String {
        self.departureDelay
    }
    
    public var trainTrack: TrainTrack? {
        if let platform = platform {
            return Track(scheduled: platform, actual: platform)
        }
        return nil
    }
    
    public var delayReason: String? {
        nil
    }
    
    public let code: String
    public let label: String
//    public let services: Services
    public let coordinates: Coordinates
    public let progress: Progress?
    public let theoricDate, realDate: Date?
//    public let isRemoved, isCreated, isDiversion: Bool
    public let delay: Int
    public let isDelayed: Bool
    public let duration: Int
    public let platform: String?
}

struct Station: TrainStation {
    let code: String
    
    let name: String
    
    let coordinates: CLLocationCoordinate2D?
}

struct Track: TrainTrack {
    let scheduled: String
    
    let actual: String
}

// MARK: - Coordinates
public struct Coordinates: Codable {
    public let latitude, longitude: Double
}

// MARK: - Progress
public struct Progress: Codable {
    public let progressPercentage: Double
    public let traveledDistance: Double
    public let remainingDistance: Double
}

// MARK: - Services
public struct Services: Codable {
    public let driver: Bool?
}


struct Status: TrainStatus {
    
    
    let gps: GPSResponse
    let statistics: StatisticsResponse?
    
    let trainId: String
    
    var latitude: Double {
        gps.latitude
    }
    
    var longitude: Double {
        gps.longitude
    }
    
 
    
    var currentSpeed: Measurement<UnitSpeed> {
        Measurement<UnitSpeed>(value: gps.speed, unit: .metersPerSecond)
    }

    
    
    var currentConnectivity: String? {
        guard let statistics = statistics else { return nil }
        var connectivity: String = ""
        for _ in 0..<min(5, max(0, statistics.quality)) {
            connectivity += "●"
        }
        for _ in 0..<max(0, 5 - max(0, statistics.quality)) {
            connectivity += "○"
        }
        return connectivity
    }
    
    var connectedDevices: Int? {
        self.statistics?.devices
    }
    
    var trainType: TrainType {
        TGVTrainType(trainId: self.trainId)
    }
}

struct TGVTrainType: TrainType {
    
    enum TGVModel: String {
        case pseBi = "TGV PSE (bicourant)"
        case pseTri = "TGV PSE (tricourant)"
        case atlantique = "TGV Atlantique"
        case reseauBi = "TGV Réseau (bicourant)"
        case reseauTri = "TGV Réseau (tricourant)"
        case duplex = "TGV Duplex"
        case reseauDuplex = "TGV Réseau Duplex"
        case duplexPOS = "TGV Duplex POS"
        case dasye = "TGV DASYE"
        case euroduplex3UH = "Euroduplex / TGV 2N2 (3UH)"
        case euroduplex3UF = "Euroduplex / TGV 2N2 (3UF)"
        case euroduplex3UA = "Euroduplex / TGV 2N2 (3UA)"
        case euroduplex3UFC = "Euroduplex / TGV 2N2 (3UFC Océane)"
        case thalyse = "THALYS PBKA"
    }
    
    let trainId: String
    
    //Source: https://www.hunza.pro/differentes-rames-tgv-circulant-sur-reseau-sncf.html
    var trainModel: String {
        return self.model?.rawValue ?? self.trainId
    }
    
    private var model: TGVModel? {
        switch Int(self.trainId) ?? 0 {
        case 1...102:
            return .pseBi
        case 110...118:
            return .pseTri
        case 301...405, 105:
            return .atlantique
        case 501...554:
            return .reseauBi
        case 4501...4540:
            return .reseauTri
        case 201...294:
            return .duplex
        case 601...619:
            return .reseauDuplex
        case 4401...4419:
            return .duplexPOS
        case 701...752:
            return .dasye
        case 800...810:
            return .euroduplex3UH
        case 811...825:
            return .euroduplex3UF
        case 4701...4730:
            return .euroduplex3UA
        case 826...894:
            return .euroduplex3UFC
        case 4301...4346:
            return .thalyse
        default:
            return nil
        }
    }
    
    #if os(macOS)
    var trainIcon: NSImage? {
        Bundle.module.image(forResource: self.icon) ?? NSImage(systemSymbolName: "tram.fill", accessibilityDescription: trainModel)
    }
    #endif
    
    #if os(iOS)
    @available(iOS 13.0, *)
    var trainIcon: Image? {
        
        Image(self.icon, bundle: Bundle.module)
    }
    #endif
    
    private var icon: String {
        guard let model = self.model else {
            return "tgv_default"
        }
        switch model {
        case .pseBi, .pseTri:
            return "tgv_pse"
        case .atlantique, .reseauBi, .reseauDuplex:
            return "tgv_atlantique"
        case .reseauTri:
            return "tgv_reseau_tri"
        case .duplexPOS:
            return "tgv_pos"
        case .dasye, .euroduplex3UH, .euroduplex3UF, .euroduplex3UA, .euroduplex3UFC, .duplex:
            return "tgv_duplex"
        case .thalyse:
            return "tgv_thalyse"
        }
    }
    
    
}

// MARK: - GPSResponse
public struct GPSResponse: Codable {
    public let success: Bool
    public let fix, timestamp: Int
    public let latitude, longitude: Double
    public let altitude: Double
    public let speed, heading: Double
}

// MARK: - CoverageResponse
public struct CoverageResponse: Codable {
    public let type: String
    public let features: [Feature]
}

// MARK: - Feature
public struct Feature: Codable {
    public let type: FeatureType
    public let geometry: Geometry
    public let properties: Properties
}

// MARK: - Geometry
public struct Geometry: Codable {
    public let type: GeometryType
    public let coordinates: [[Double]]
}

public enum GeometryType: String, Codable {
    case lineString = "LineString"
}

// MARK: - Properties
public struct Properties: Codable {
    public let quality: Quality
}

public enum Quality: String, Codable {
    case big = "big"
    case small = "small"
    case tiny = "tiny"
    case tunnel = "tunnel"
}

public enum FeatureType: String, Codable {
    case feature = "Feature"
}

// MARK: - StatisticsResponse
public struct StatisticsResponse: Codable {
    public let quality, devices: Int
}
