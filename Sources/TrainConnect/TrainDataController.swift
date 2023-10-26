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
        delegate(completionHandler: completionHandler) {
            $0.loadTrip(demoMode: demoMode, completionHandler: $1)
        }
    }
    
    public func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> ()) {
        delegate(completionHandler: completionHandler) {
            $0.loadTrainStatus(demoMode: demoMode, completionHandler: $1)
        }
    }
    
    private func delegate<D>(completionHandler: @escaping (D?, Error?) -> (),
                             action: (TrainDataController, @escaping (D?, Error?) -> ()) -> ()) {
        var completed: Bool = false
        var failed: Int = 0
        for controller in controllers {
            action(controller) { result, error in
                if let error = error {
                    failed += 1
                    if failed >= self.controllers.count {
                        completionHandler(nil, error)
                    }
                } else if !completed, let result = result {
                    completed = true
                    completionHandler(result, nil)
                }
            }
        }
    }
}

public enum TrainConnectionError: Error {
    case notConnected
}
