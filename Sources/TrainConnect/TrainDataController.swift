//
//  File.swift
//  
//
//  Created by Leo Mehlig on 13.07.22.
//

import Foundation

public protocol TrainDataController {
    func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> ())
    func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> ())
}

public class CombinedDataController: TrainDataController {
    public static var _shared: TrainDataController = CombinedDataController()
    
    var controllers: [TrainDataController]
    
    public init(controllers: TrainDataController...) {
        self.controllers = controllers
    }
    
    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> ()) {
        var completed: Bool = false
        var failed: Int = 0
        for controller in controllers {
            controller.loadTrip(demoMode: demoMode) {
                if let error = $1 {
                    failed += 1
                    if failed >= self.controllers.count {
                        completionHandler(nil, error)
                    }
                } else if !completed, let trip = $0 {
                    completed = true
                    completionHandler(trip, nil)
                }
            }
        }
    }
    
    public func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> ()) {
        var completed: Bool = false
        var failed: Int = 0
        for controller in controllers {
            controller.loadTrainStatus(demoMode: demoMode) {
                if let error = $1 {
                    failed += 1
                    if failed >= self.controllers.count {
                        completionHandler(nil, error)
                    }
                } else if !completed, let status = $0 {
                    completed = true
                    completionHandler(status, nil)
                }
            }
        }
    }
}
