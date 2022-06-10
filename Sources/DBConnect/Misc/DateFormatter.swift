//
//  DateFormatter.swift
//  ICE Buddy
//
//  Created by Maximilian Seiferth on 02.02.22.
//

import Foundation

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = .current
          //Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = .current
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }()
}
