import Foundation
import CoreLocation
import TrainConnect
#if os(macOS)
import AppKit
#else
import SwiftUI
#endif

/// Normalized values used by all additional onboard portals. Wire DTOs remain private to each adapter.
public struct OnboardJourney: TrainTrip {
    public let train: String
    public let vzn: String
    public let stops: [OnboardStop]
    public let vehicleType: TrainType?
    public var trainStops: [TrainStop] { stops }
    public var finalStopInfo: TrainFinalStopInfo? { nil }
}

public struct OnboardStop: TrainStop {
    public let id: UUID
    public let station: OnboardStation
    public let scheduledArrival: Date?
    public let actualArrival: Date?
    public let scheduledDeparture: Date?
    public let actualDeparture: Date?
    public let track: OnboardTrack?
    public let hasPassed: Bool
    public let isCancelled: Bool
    public let delayReason: String?
    public var trainStation: TrainStation { station }
    public var trainTrack: TrainTrack? { track }
    public var arrivalDelay: String { Self.delay(scheduledArrival, actualArrival) }
    public var departureDelay: String { Self.delay(scheduledDeparture, actualDeparture) }

    static func delay(_ scheduled: Date?, _ actual: Date?) -> String {
        guard let scheduled = scheduled, let actual = actual else { return "" }
        let minutes = Int((actual.timeIntervalSince(scheduled) / 60).rounded())
        return minutes == 0 ? "" : String(format: "%+d", minutes)
    }
}

public struct OnboardStation: TrainStation {
    public let code: String
    public let name: String
    public let coordinates: CLLocationCoordinate2D?
}

public struct OnboardTrack: TrainTrack {
    public let scheduled: String
    public let actual: String
}

public struct OnboardStatus: TrainStatus {
    public let latitude: Double
    public let longitude: Double
    public let currentSpeed: Measurement<UnitSpeed>
    public let trainType: TrainType
    public var currentConnectivity: String? { nil }
    public var connectedDevices: Int? { nil }
}

struct OnboardTrainType: TrainType {
    let trainModel: String
    let asset: String
    #if os(macOS)
    var trainIcon: NSImage? {
        Bundle.module.image(forResource: asset)
            ?? NSImage(systemSymbolName: "tram.fill", accessibilityDescription: trainModel)
    }
    #else
    var trainIcon: Image? { Image(asset, bundle: Bundle.module) }
    #endif
}
