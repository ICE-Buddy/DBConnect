//
//  DBTimetableViewModel.swift
//  ICE Buddy
//
//  Created by Maximilian Seiferth on 16.02.22.
//

import Foundation
import SwiftUI

public struct TimetableSection: Hashable {
    public let id = UUID()
    public let productName: String
    public let departures: [TimetableTrip]
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: TimetableSection, rhs: TimetableSection) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct TimetableTrip: Decodable, Hashable {
    public let id = UUID()
    public let when: Date?
    public let plannedWhen: Date?
    public let delay: Int?
    public let plattform: String?
    public let plannedPlattform: String?
    public let direction: String?
    public let line: TimetableLine
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: TimetableTrip, rhs: TimetableTrip) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct TimetableLine: Decodable {
    let name: String
    let productName: String
}
