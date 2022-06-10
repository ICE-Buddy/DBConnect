//
//  DBTimetableDataController.swift
//  ICE Buddy
//
//  Created by Maximilian Seiferth on 16.02.22.
//

import Foundation
import Moya
import DBConnect

public class DBTimetableDataController: NSObject {
    public static let shared = DBTimetableDataController()
    private let provider = MoyaProvider<DBTimetableAPI>()
    
    public func loadArrivalBoard(for stop: JourneyStop, completionHandler: @escaping ([TimetableTrip]?, Error?) -> ()){
        provider.request(.arrivals(for: stop)) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let arrivalBoard = try decoder.decode([TimetableTrip].self, from: response.data)
                    completionHandler(arrivalBoard, nil)
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
    
    public func loadDepartureBoard(for stop: JourneyStop, completionHandler: @escaping ([TimetableTrip]?, Error?) -> ()) {
        provider.request(.departures(for: stop)) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let departureBoard = try decoder.decode([TimetableTrip].self, from: response.data)
                    completionHandler(departureBoard, nil)
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
