import XCTest
import Moya
import TrainConnect

final class APIDiagnosticsTests: XCTestCase {
    func testReportRedactsRequestResponseAndDynamicCodingKeys() throws {
        let api = PrivateFixtureAPI()
        let provider = MoyaProvider<PrivateFixtureAPI>(endpointClosure: { target in
            let response = HTTPURLResponse(url: target.baseURL, statusCode: 200, httpVersion: nil,
                                           headerFields: ["Content-Type": "application/json", "Set-Cookie": "PRIVATE_COOKIE_MARKER"])!
            return Endpoint(url: target.baseURL.absoluteString, sampleResponseClosure: { .response(response, target.sampleData) },
                            method: .get, task: .requestPlain, httpHeaderFields: target.headers)
        }, stubClosure: MoyaProvider.immediatelyStub)
        let finished = expectation(description: "Malformed field generates sanitized diagnostics")
        provider.loadJson(target: api) { (value: [String: Reading]?, error) in
            XCTAssertNil(value)
            XCTAssertNotNil(error)
            finished.fulfill()
        }
        wait(for: [finished], timeout: 1)
        let report = APIDiagnostics.shared.makeReport(applicationVersion: "2.0", build: "16")
        for value in ["PRIVATE_USER_MARKER", "PRIVATE_PASSWORD_MARKER", "PRIVATE_QUERY_MARKER", "PRIVATE_AUTH_MARKER",
                      "PRIVATE_STATION_MARKER", "PRIVATE_VALUE_MARKER", "PRIVATE_COOKIE_MARKER", "52.520008", "13.404954"] {
            XCTAssertFalse(report.contains(value), "Leaked \(value)")
        }
        let entry = try latestEntry(report)
        XCTAssertEqual(entry["endpoint"] as? String, "iceportal.de/api1/rs/status")
        XCTAssertEqual(entry["outcome"] as? String, "typeMismatch")
        XCTAssertEqual(entry["field"] as? String, "<field>.speed")
        XCTAssertEqual(entry["expectedType"] as? String, "Double")
        XCTAssertEqual(entry["responseFormat"] as? String, "json")
        XCTAssertNotNil(entry["durationMilliseconds"])
    }

    func testNetworkErrorKeepsCodeWithoutLocalizedDescriptionOrFailingURL() throws {
        let provider = MoyaProvider<PrivateFixtureAPI>(endpointClosure: { target in
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut,
                                userInfo: [NSLocalizedDescriptionKey: "PRIVATE_ERROR_MARKER", NSURLErrorFailingURLStringErrorKey: "https://PRIVATE_URL_MARKER"])
            return Endpoint(url: target.baseURL.absoluteString, sampleResponseClosure: { .networkError(error) },
                            method: .get, task: .requestPlain, httpHeaderFields: nil)
        }, stubClosure: MoyaProvider.immediatelyStub)
        let finished = expectation(description: "Network failure recorded")
        provider.loadJson(target: PrivateFixtureAPI()) { (value: Reading?, error) in
            XCTAssertNil(value)
            XCTAssertNotNil(error)
            finished.fulfill()
        }
        wait(for: [finished], timeout: 1)
        let report = APIDiagnostics.shared.makeReport(applicationVersion: "2.0", build: "16")
        let entry = try latestEntry(report)
        XCTAssertEqual(entry["outcome"] as? String, "transportError")
        XCTAssertEqual(entry["networkErrorCode"] as? Int, NSURLErrorTimedOut)
        XCTAssertFalse(report.contains("PRIVATE_ERROR_MARKER"))
        XCTAssertFalse(report.contains("PRIVATE_URL_MARKER"))
    }

    func testReportIsBoundedAndIncludesAdapterValidationFailures() throws {
        for _ in 0..<45 { APIDiagnostics.shared.recordInvalidResponse(endpoint: .railnet) }
        let report = APIDiagnostics.shared.makeReport(applicationVersion: "2.0", build: "16", isDemo: true)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(report.utf8)) as? [String: Any])
        let requests = try XCTUnwrap(json["requests"] as? [[String: Any]])
        XCTAssertEqual(requests.count, 40)
        XCTAssertTrue(requests.allSatisfy { $0["outcome"] as? String == "invalidResponse" })
        XCTAssertEqual(json["isDemo"] as? Bool, true)
    }

    private func latestEntry(_ report: String) throws -> [String: Any] {
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(report.utf8)) as? [String: Any])
        return try XCTUnwrap((json["requests"] as? [[String: Any]])?.last)
    }
}

private struct Reading: Decodable { let speed: Double }
private struct PrivateFixtureAPI: TargetType {
    var baseURL: URL { URL(string: "https://PRIVATE_USER_MARKER:PRIVATE_PASSWORD_MARKER@iceportal.de/api1/rs?query=PRIVATE_QUERY_MARKER")! }
    var path: String { "/status" }
    var method: Moya.Method { .get }
    var sampleData: Data {
        Data(#"{"PRIVATE_STATION_MARKER":{"speed":"PRIVATE_VALUE_MARKER","latitude":52.520008,"longitude":13.404954}}"#.utf8)
    }
    var task: Task { .requestPlain }
    var headers: [String: String]? { ["Authorization": "Bearer PRIVATE_AUTH_MARKER"] }
}
