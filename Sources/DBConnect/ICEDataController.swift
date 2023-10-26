//
//  ICEDataController.swift
//  ICE Buddy
//
//  Created by Maximilian Seiferth on 28.01.22.
//

import Foundation
import Combine
import Moya
import TrainConnect

public final class ICEDataController: NSObject, TrainDataController {
    
    public static let shared = ICEDataController()
    
    override init() {
        super.init()
    }
    
    public func getProvider(demoMode: Bool) -> MoyaProvider<ICEPortalAPI> {
        if demoMode {
            return MoyaProvider<ICEPortalAPI>(stubClosure: MoyaProvider.immediatelyStub)
        } else {
            return MoyaProvider<ICEPortalAPI>(stubClosure: MoyaProvider.neverStub,
                                              session: alamofireSessionWithFasterTimeout)
        }
    }
    
    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> ()) {
        self.loadTripData(demoMode: demoMode, completionHandler: {
            completionHandler($0?.trip, $1)
        })
    }
    
    public func loadTripData(demoMode: Bool = false, completionHandler: @escaping (TripResponse?, Error?) -> ()){
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.yyyyMMdd)
        let provider = getProvider(demoMode: demoMode)
        provider.loadJson(decoder: decoder, target: .trip, completionHandler: completionHandler)
    }
    
    
    public func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> ()) {
        self.loadStatus(demoMode: demoMode, completionHandler: {
            completionHandler($0, $1)
        })
    }
    
    public func loadStatus(demoMode: Bool = false, completionHandler: @escaping (Status?, Error?) -> ()) {
        getProvider(demoMode: demoMode).loadJson(target: .status, completionHandler: completionHandler)
    }
}

extension ICEDataController {
    static public func sampleStop() -> JourneyStop? {
        var stop: JourneyStop?
        let dataController = self.shared
        dataController.loadTripData(demoMode: true) { tripResponse, error in
            if let tripResponse = tripResponse {
                stop = tripResponse.trip.stops.filter({ stop in
                    return stop.timetable.arrivalDelay != ""
                }).first
            }
        }
        return stop
    }
}

