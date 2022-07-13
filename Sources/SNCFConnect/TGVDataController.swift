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

extension DateFormatter {
    static let tgvFormatter: DateFormatter = {
        //2022-07-13T11:58:00.000Z
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

public class TGVDataController: NSObject, TrainDataController {
    public static let shared = TGVDataController()
    
    override init() {
        super.init()
    }
    
    public func getProvider(demoMode: Bool) -> MoyaProvider<TGVPortalAPI> {
        if demoMode {
            return MoyaProvider<TGVPortalAPI>(stubClosure: MoyaProvider.immediatelyStub)
        } else {
            return MoyaProvider<TGVPortalAPI>(stubClosure: MoyaProvider.neverStub)
        }
    }
    
    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> ()){
        self.loadDetails(demoMode: demoMode, completionHandler: {
            completionHandler($0, $1)
        })
    }
    private func loadDetails(demoMode: Bool, completionHandler: @escaping (DetailsResponse?, Error?) -> ()){
        
        let provider = getProvider(demoMode: demoMode)
        provider.request(.details) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    print(DateFormatter.tgvFormatter.string(from: .init()))
                    decoder.dateDecodingStrategy = .formatted(DateFormatter.tgvFormatter)
                    let trip = try decoder.decode(DetailsResponse.self, from: response.data)
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
    
    public func loadTrainStatus(demoMode: Bool = false, completionHandler: @escaping (TrainStatus?, Error?) -> ()) {
        self.loadGPS(demoMode: demoMode) { gps, error in
            if let gps = gps {
                self.loadStatistics(demoMode: demoMode) { statistics, error in
                    if let statistics = statistics {
                        self.loadDetails(demoMode: demoMode) { trip, error in
                            if let trip = trip {
                                completionHandler(Status(gps: gps, statistics: statistics, trainId: trip.trainId), nil)
                            } else {
                                completionHandler(nil, error)
                            }
                        }
                    } else {
                        completionHandler(nil, error)
                    }
                }
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    private func loadGPS(demoMode: Bool = false, completionHandler: @escaping (GPSResponse?, Error?) -> ()) {
        let provider = getProvider(demoMode: demoMode)
        provider.request(.gps) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    let status = try decoder.decode(GPSResponse.self, from: response.data)
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
    
    private func loadStatistics(demoMode: Bool = false, completionHandler: @escaping (StatisticsResponse?, Error?) -> ()) {
        let provider = getProvider(demoMode: demoMode)
        provider.request(.statistics) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    let status = try decoder.decode(StatisticsResponse.self, from: response.data)
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

//extension ICEDataController {
//    static public func sampleStop() -> JourneyStop? {
//        var stop: JourneyStop?
//        let dataController = self.shared
//        dataController.loadTripData(demoMode: true) { tripResponse, error in
//            if let tripResponse = tripResponse {
//                stop = tripResponse.trip.stops.filter({ stop in
//                    return stop.timetable.arrivalDelay != ""
//                }).first
//            }
//        }
//        return stop
//    }
//}

