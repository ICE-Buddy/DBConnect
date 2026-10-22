import Foundation
import Moya
import Alamofire

/// Session-only, bounded technical metadata. This object has no persistence or network sender.
public final class APIDiagnostics {
    public static let shared = APIDiagnostics()
    private let lock = NSLock()
    private var entries: [Entry] = []
    private let capacity = 40
    private let retention: TimeInterval = 15 * 60
    private init() {}

    public func makeReport(applicationVersion: String, build: String, isDemo: Bool = false) -> String {
        let now = Date()
        lock.lock()
        let recent = entries.filter { now.timeIntervalSince($0.timestamp) <= retention }
        lock.unlock()
        let report = Report(schemaVersion: 1, generatedAt: now, applicationVersion: applicationVersion, build: build,
                            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
                            isDemo: isDemo, requests: recent)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(report), let text = String(data: data, encoding: .utf8) else {
            return "{\"error\":\"Report could not be generated\"}"
        }
        return text
    }

    /// For a decoded response that fails the adapter's semantic validation.
    public func recordInvalidResponse(endpoint: APIDiagnosticEndpoint) {
        append(Entry(timestamp: Date(), endpoint: endpoint, outcome: .invalidResponse))
    }

    func record(endpoint: APIDiagnosticEndpoint, response: Response?, error: Error?, startedAt: UInt64) {
        var entry = Entry(timestamp: Date(), endpoint: endpoint, outcome: .success)
        entry.durationMilliseconds = Int((DispatchTime.now().uptimeNanoseconds - startedAt) / 1_000_000)
        entry.httpStatus = response?.statusCode
        entry.responseBytes = response?.data.count
        if let contentType = response?.response?.mimeType?.lowercased() {
            entry.responseFormat = contentType.contains("json") ? "json" : (contentType == "text/html" ? "html" : "other")
        }
        if let error = error {
            switch error {
            case DecodingError.keyNotFound(let key, let context):
                entry.outcome = .missingField
                entry.field = Self.safePath(context.codingPath + [key])
            case DecodingError.typeMismatch(let type, let context):
                entry.outcome = .typeMismatch
                entry.field = Self.safePath(context.codingPath)
                entry.expectedType = Self.safeType(type)
            case DecodingError.valueNotFound(let type, let context):
                entry.outcome = .missingValue
                entry.field = Self.safePath(context.codingPath)
                entry.expectedType = Self.safeType(type)
            case DecodingError.dataCorrupted(let context):
                entry.outcome = context.codingPath.isEmpty ? .invalidJSON : .invalidValue
                entry.field = Self.safePath(context.codingPath)
            default:
                if let status = response?.statusCode, !(200...299).contains(status) {
                    entry.outcome = .httpError
                } else if let response = response, response.data.isEmpty {
                    entry.outcome = .emptyResponse
                } else {
                    entry.outcome = .transportError
                    entry.networkErrorCode = Self.networkCode(error)
                }
            }
        }
        append(entry)
    }

    private func append(_ entry: Entry) {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll { entry.timestamp.timeIntervalSince($0.timestamp) > retention }
        entries.append(entry)
        if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
    }

    // Coding keys can originate in dynamic dictionaries. Preserve only known schema field names.
    private static func safePath(_ keys: [CodingKey]) -> String {
        let known: Set<String> = ["trip", "stops", "station", "name", "evaNr", "geocoordinates", "timetable", "track", "info",
                                  "tripDate", "trainType", "vzn", "stopInfo", "finalStationName", "finalStationEvaNr",
                                  "scheduledArrivalTime", "actualArrivalTime", "scheduledDepartureTime", "actualDepartureTime",
                                  "arrivalDelay", "departureDelay", "scheduled", "actual", "distance", "distanceFromStart", "passed", "status",
                                  "latitude", "longitude", "series", "speed", "tzn", "connectivity", "currentState", "nextState", "remainingTimeSeconds",
                                  "number", "carrier", "trainId", "code", "label", "coordinates", "progress", "progressPercentage",
                                  "theoricDate", "realDate", "delay", "isDelayed", "duration", "platform", "success", "fix", "timestamp", "altitude", "heading", "quality", "devices",
                                  "lineNumber", "stations", "latestStatus", "nextStation", "id", "arrival", "departure", "forecast", "dateTime", "gpsPosition",
                                  "connexionTimes", "timeArrival", "timeDeparture", "gpsLat", "gpsLng", "no", "evaNo", "position", "target", "prediction", "predicted",
                                  "arrivalTime", "departureTime", "canceled", "messages", "type", "textShort", "text"]
        return keys.map { $0.intValue != nil ? "[]" : (known.contains($0.stringValue) ? $0.stringValue : "<field>") }.joined(separator: ".")
    }

    private static func safeType(_ type: Any.Type) -> String {
        if type == String.self { return "String" }
        if type == Int.self { return "Int" }
        if type == Double.self { return "Double" }
        if type == Bool.self { return "Bool" }
        return "structured value"
    }

    private static func networkCode(_ error: Error, depth: Int = 0) -> Int? {
        guard depth < 5 else { return nil }
        if let moya = error as? MoyaError, case .underlying(let underlying, _) = moya {
            return networkCode(underlying, depth: depth + 1)
        }
        if let alamofire = error as? AFError, let underlying = alamofire.underlyingError {
            return networkCode(underlying, depth: depth + 1)
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain { return nsError.code }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return networkCode(underlying, depth: depth + 1)
        }
        return nil
    }

    private enum Outcome: String, Encodable {
        case success, emptyResponse, httpError, transportError, invalidJSON, missingField, typeMismatch, missingValue, invalidValue, invalidResponse
    }
    private struct Entry: Encodable {
        let timestamp: Date
        let endpoint: APIDiagnosticEndpoint
        var outcome: Outcome
        var durationMilliseconds: Int?
        var httpStatus: Int?
        var responseBytes: Int?
        var responseFormat: String?
        var field: String?
        var expectedType: String?
        var networkErrorCode: Int?
    }
    private struct Report: Encodable {
        let schemaVersion: Int
        let generatedAt: Date
        let applicationVersion: String
        let build: String
        let operatingSystem: String
        let isDemo: Bool
        let requests: [Entry]
        let note = "Failed probes for other operators are expected. Contains technical metadata only; no response bodies, headers, query values, station names, locations or network identifiers."
    }
}
