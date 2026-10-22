import Foundation
import CryptoKit

/// Stable across polls, including repeated visits to a station within one service.
public enum TrainStopIdentifier {
    public static func uuid(provider: String, station: String, scheduledTime: Date?) -> UUID {
        let key = [provider, station, scheduledTime.map { String($0.timeIntervalSince1970) } ?? ""].joined(separator: "\u{1F}")
        let bytes = Array(SHA256.hash(data: Data(key.utf8)).prefix(16))
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
