import XCTest
import Moya
import TrainConnect

final class PortalTransportTests: XCTestCase {
    func testInvalidHTTPEmptyAndMalformedBodiesAlwaysComplete() {
        for (status, body) in [(200, ""), (200, "<html>Login</html>"), (200, "{}"), (503, "unavailable")] {
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
