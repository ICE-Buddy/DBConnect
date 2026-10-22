import XCTest
import Moya
import TrainConnect

final class PortalTransportTests: XCTestCase {
    func testInvalidHTTPEmptyAndMalformedBodiesAlwaysComplete() {
        for (status, body, outcome) in [(200, "", "emptyResponse"), (200, "<html>Login</html>", "invalidJSON"), (200, "{}", "missingField"), (503, "unavailable", "httpError")] {
            let finished = expectation(description: "HTTP \(status): \(body)")
            let provider = MoyaProvider<SampleAPI>(endpointClosure: { target in
                Endpoint(url: target.baseURL.absoluteString, sampleResponseClosure: { .networkResponse(status, Data(body.utf8)) }, method: .get, task: .requestPlain, httpHeaderFields: nil)
            }, stubClosure: MoyaProvider.immediatelyStub)
            provider.loadJson(target: SampleAPI()) { (value: Payload?, error) in
                XCTAssertNil(value)
                XCTAssertNotNil(error)
                finished.fulfill()
            }
            wait(for: [finished], timeout: 1)
            let report = APIDiagnostics.shared.makeReport(applicationVersion: "test", build: "test")
            guard let json = try? JSONSerialization.jsonObject(with: Data(report.utf8)) as? [String: Any],
                  let entry = (json["requests"] as? [[String: Any]])?.last else {
                XCTFail("Missing diagnostic report"); continue
            }
            XCTAssertEqual(entry["outcome"] as? String, outcome)
            XCTAssertEqual(entry["httpStatus"] as? Int, status)
            XCTAssertEqual(entry["responseBytes"] as? Int, body.utf8.count)
        }
    }
}

private struct Payload: Decodable { let speed: Double }
private struct SampleAPI: TargetType {
    var baseURL: URL { URL(string: "https://example.invalid")! }
    var path: String { "" }
    var method: Moya.Method { .get }
    var sampleData: Data { Data() }
    var task: Task { .requestPlain }
    var headers: [String: String]? { nil }
}
