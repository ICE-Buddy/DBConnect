import Foundation
import TrainConnect

/// Railnet sends clock times and a timestamp, not complete dates for every stop.
/// Unroll scheduled times across midnight; keep forecast rollover independent of the schedule.
struct RailnetClock {
    private var calendar: Calendar
    private var day: Date
    private var previous: Date?

    init(reference: Date, firstTime: String?) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Vienna")!
        self.calendar = calendar
        self.day = calendar.startOfDay(for: reference)
        if let first = Self.clock(firstTime, day: day, calendar: calendar), first.timeIntervalSince(reference) > 12 * 3600 {
            self.day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
    }

    mutating func scheduled(_ text: String?) -> Date? {
        guard var result = Self.clock(text, day: day, calendar: calendar) else { return nil }
        if let previous = previous, result < previous {
            day = calendar.date(byAdding: .day, value: 1, to: day)!
            result = Self.clock(text, day: day, calendar: calendar)!
        }
        previous = result
        return result
    }

    func forecast(_ text: String?, scheduled: Date?) -> Date? {
        guard let scheduled = scheduled,
              var result = Self.clock(text, day: scheduled, calendar: calendar) else { return nil }
        let difference = result.timeIntervalSince(scheduled)
        if difference < -12 * 3600 { result = calendar.date(byAdding: .day, value: 1, to: result)! }
        if difference > 12 * 3600 { result = calendar.date(byAdding: .day, value: -1, to: result)! }
        return result
    }

    private static func clock(_ text: String?, day: Date, calendar: Calendar) -> Date? {
        guard let text = text else { return nil }
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]) else { return nil }
        return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: day)
    }
}
