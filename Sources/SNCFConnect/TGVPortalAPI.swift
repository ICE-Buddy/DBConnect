//
//  SNCFPortalAPI.swift
//  ICE Buddy
//
//  Created by Leo Mehlig on 13.07.22.
//

import Foundation
import Moya

// URL: https://wifi.sncf/router/api/train/details

public enum TGVPortalAPI {
    case details
    case gps
    case coverage
    case statistics
    
}

extension TGVPortalAPI: TargetType {
    public var baseURL: URL {
        URL(string: "https://wifi.sncf/router/api")!
    }
    
    public var path: String {
        switch self {
        case .details:
            return "/train/details"
        case .gps:
            return "/train/gps"
        case .coverage:
            return "/train/coverage"
        case .statistics:
            return "/connection/statistics"
        }
    }
    
    public var method: Moya.Method {
        return .get
    }
    
    public var sampleData: Data {
        switch self {
        case .details:
            return self.data(for: "Details-ESBST-FRPLY")
        case .statistics:
            return self.data(for: "Statistics-1")
        case .coverage:
            return self.data(for: "Coverage-ESBST-FRPLY")
        case .gps:
            return self.data(for: "GPS-1")
        }
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
    
    public var task: Task {
        .requestPlain
    }
    
    public var headers: [String : String]? {
        return [:]
    }
}

