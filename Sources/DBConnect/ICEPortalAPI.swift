//
//  ICEPortalAPI.swift
//  ICE Buddy
//
//  Created by Maximilian Seiferth on 28.01.22.
//

import Foundation
import Moya

// URL: https://iceportal.de/api1/rs/tripInfo/trip
// https://iceportal.de/api1/rs/status

public enum ICEPortalAPI {
    case trip
    case status
}

extension ICEPortalAPI: TargetType {
    public var baseURL: URL {
        URL(string: "https://iceportal.de/api1/rs")!
    }
    
    public var path: String {
        switch self {
        case .trip:
            return "/tripInfo/trip"
        case .status:
            return "/status"
        }
    }
    
    public var method: Moya.Method {
        return .get
    }
    
    private func data(for sample: String) -> Data {
        do {
            if let bundlePathURL = Bundle.module.path(forResource: sample, ofType: "json") {
                let data = try Data(contentsOf: URL(fileURLWithPath: bundlePathURL))
                return data
            } else {
                print("File could not be found")
            }
        } catch {
            print(error.localizedDescription)
        }
        return Data()
    }
    
    
    public var sampleData: Data {
        switch self {
        case .trip:
            return self.data(for: "tripInfo1")
        case .status:
            return self.data(for: "status")
        }
    }
    
    public var task: Task {
        .requestPlain
    }
    
    public var headers: [String : String]? {
        return [:]
    }
}
