import Foundation

/// ISO 8601 timestamps with explicit offsets, with or without fractional seconds.
/// Create formatters per operation to avoid mutable shared formatter state across callbacks.
public enum TrainDateParser {
    public static func instant(_ text: String?) -> Date? {
        guard let text = text, !text.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: text) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: text) { return date }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: text)
    }
}
