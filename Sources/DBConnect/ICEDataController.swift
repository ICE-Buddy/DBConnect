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
            return MoyaProvider<ICEPortalAPI>(stubClosure: MoyaProvider.neverStub)
        }
    }
    
    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> ()) {
        self.loadTripData(demoMode: demoMode, completionHandler: {
            completionHandler($0?.trip, $1)
        })
    }
    
    public func loadTripData(demoMode: Bool = false, completionHandler: @escaping (TripResponse?, Error?) -> ()){
        let provider = getProvider(demoMode: demoMode)
        provider.request(.trip) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .formatted(DateFormatter.yyyyMMdd)
                    let trip = try decoder.decode(TripResponse.self, from: response.data)
                    completionHandler(trip, nil)
                } catch DecodingError.dataCorrupted(let context) {
                    print(context)
                } catch DecodingError.keyNotFound(let key, let context) {
                    print("Key '\(key)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch DecodingError.valueNotFound(let value, let context) {
                    print("Value '\(value)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch DecodingError.typeMismatch(let type, let context) {
                    print("Type '\(type)' mismatch:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch {
                    print(error.localizedDescription)
                    completionHandler(nil, error)
                }
                break
            case .failure(let error):
                print(error.localizedDescription)
                completionHandler(nil, error)
                break
            }
        }
    }
    
    
    public func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> ()) {
        self.loadStatus(demoMode: demoMode, completionHandler: {
            completionHandler($0, $1)
        })
    }
    
    public func loadStatus(demoMode: Bool = false, completionHandler: @escaping (Status?, Error?) -> ()) {
        let provider = getProvider(demoMode: demoMode)
        provider.request(.status) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    let status = try decoder.decode(Status.self, from: response.data)
                    completionHandler(status, nil)
                } catch DecodingError.dataCorrupted(let context) {
                    print(context)
                } catch DecodingError.keyNotFound(let key, let context) {
                    print("Key '\(key)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch DecodingError.valueNotFound(let value, let context) {
                    print("Value '\(value)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch DecodingError.typeMismatch(let type, let context) {
                    print("Type '\(type)' mismatch:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch {
                    print(error.localizedDescription)
                    completionHandler(nil, error)
                }
                break
            case .failure(let error):
                print(error.localizedDescription)
                completionHandler(nil, error)
                break
            }
        }
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
