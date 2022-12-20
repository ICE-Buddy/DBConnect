//
//  File.swift
//  
//
//  Created by Leo Mehlig on 13.07.22.
//

import Foundation
import CoreLocation
#if os(macOS)
import AppKit
#endif

#if !os(macOS)
import SwiftUI
#endif

public protocol TrainTrip {
    var train: String { get }
    var trainStops: [TrainStop] { get }
    var vzn: String { get }
    var finalStopInfo: TrainFinalStopInfo? { get }
}

public protocol TrainFinalStopInfo {
    var finalStationName: String { get }
    var finalStationEvaNr: String { get }
}

public protocol TrainStop {
    var id: UUID { get }
    var trainStation: TrainStation { get }
    var scheduledArrival: Date? { get }
    var actualArrival: Date? { get }
    
    var scheduledDeparture: Date? { get }
    var actualDeparture: Date? { get }
    
    var departureDelay: String { get }
    var arrivalDelay: String { get }
    
    var trainTrack: TrainTrack? { get }
    
    var hasPassed: Bool { get }
    
    var delayReason: String? { get }
    
}

public protocol TrainStation {
    var code: String { get }
    var name: String { get }
    var coordinates: CLLocationCoordinate2D? { get }
}

public protocol TrainTrack {
    var scheduled: String { get }
    var actual: String { get }
}

public protocol TrainStatus {
    var latitude: Double { get }
    var longitude: Double { get }
    var currentSpeed: Measurement<UnitSpeed> { get }
    var currentConnectivity: String? { get }
    var connectedDevices: Int? { get }
    var trainType: TrainType { get }
}

public protocol TrainType {
    var trainModel: String { get }
#if os(macOS)
    var trainIcon: NSImage? { get }
#else
    var trainIcon: Image? { get }
#endif
}

public protocol TrainConnectivity {
    var currentState: String? { get }
    var nextState: String? { get }
    var remainingTimeSeconds: Int? { get }
}

public extension Array where Element == TrainStop {
    var nextStop: TrainStop? {
        self.filter({ stop in
            return !stop.hasPassed
        }).first
    }
}
