//
//  File.swift
//  
//
//  Created by Max Seiferth on 09.06.22.
//

import Foundation

public enum InternetConnection {
    case high, unstable
    
    public static func from(rawString: String) -> InternetConnection {
        if rawString == "HIGH" {
            return .high
        }
        return .unstable
    }
    
    public var localizedString: String {
        switch self {
        case .high:
            return NSLocalizedString("high-string", comment: "Netzwerk Verbindungsqualität HIGH")
        case .unstable:
            return NSLocalizedString("unstable-string", comment: "Netzwerk Verbindungsqualität UNSTABLE")
        }
    }
}
