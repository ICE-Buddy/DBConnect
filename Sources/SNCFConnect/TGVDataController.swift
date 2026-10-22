//
//  SNCFDataController.swift
//  ICE Buddy
//
//  Created by Leo Mehlig on 13.07.22.
//

import Foundation
import Combine
import Moya
import TrainConnect

public class TGVDataController: NSObject, TrainDataController {
    public static let shared = TGVDataController()
    
    override init() {
        super.init()
    }
    
    public func getProvider(demoMode: Bool) -> MoyaProvider<TGVPortalAPI> {
        if demoMode {
            return MoyaProvider<TGVPortalAPI>(stubClosure: MoyaProvider.immediatelyStub)
        } else {
            return MoyaProvider<TGVPortalAPI>(stubClosure: MoyaProvider.neverStub,
                                              session: alamofireSessionWithFasterTimeout)
        }
    }
    
    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> ()){
        self.loadDetails(demoMode: demoMode, completionHandler: {
            completionHandler($0, $1)
        })
    }
    private func loadDetails(demoMode: Bool, completionHandler: @escaping (DetailsResponse?, Error?) -> ()){
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = TrainDateParser.instant(text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO 8601 timestamp")
            }
            return date
        }
        let provider = getProvider(demoMode: demoMode)
        provider.loadJson(decoder: decoder, target: .details, completionHandler: completionHandler)
    }
    
    public func loadSnapshot(demoMode: Bool, completionHandler: @escaping (TrainSnapshot?, Error?) -> Void) {
        loadDetails(demoMode: demoMode) { trip, error in
            guard let trip = trip, !trip.stops.isEmpty else {
                completionHandler(nil, error ?? TrainConnectionError.invalidResponse)
                return
            }
            self.loadGPS(demoMode: demoMode) { gps, _ in
                guard let gps = gps, gps.success, gps.speed >= 0,
                      (-90...90).contains(gps.latitude), (-180...180).contains(gps.longitude) else {
                    completionHandler(TrainSnapshot(trip: trip, status: nil), nil)
                    return
                }
                self.loadStatistics(demoMode: demoMode) { statistics, _ in
                    let status = Status(gps: gps, statistics: statistics, trainId: trip.trainId)
                    completionHandler(TrainSnapshot(trip: trip, status: status), nil)
                }
            }
        }
    }

    public func loadTrainStatus(demoMode: Bool = false, completionHandler: @escaping (TrainStatus?, Error?) -> Void) {
        loadSnapshot(demoMode: demoMode) { completionHandler($0?.status, $1 ?? ($0?.status == nil ? TrainConnectionError.unsupportedCapability : nil)) }
    }

    private func loadGPS(demoMode: Bool = false, completionHandler: @escaping (GPSResponse?, Error?) -> ()) {
        getProvider(demoMode: demoMode).loadJson(target: .gps, completionHandler: completionHandler)
    }
    
    private func loadStatistics(demoMode: Bool = false, completionHandler: @escaping (StatisticsResponse?, Error?) -> ()) {
        getProvider(demoMode: demoMode).loadJson(target: .statistics, completionHandler: completionHandler)
    }
}
