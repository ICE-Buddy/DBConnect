import Foundation
import Moya
import Alamofire

public extension MoyaProvider {
    func loadJson<D: Decodable>(decoder: JSONDecoder = .init(),
                               target: Target,
                               completionHandler: @escaping (D?, Error?) -> Void) {
        let startedAt = DispatchTime.now().uptimeNanoseconds
        let endpoint = APIDiagnosticEndpoint(baseURL: target.baseURL, path: target.path)
        request(target) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    guard !response.data.isEmpty else {
                        throw TrainConnectionError.notConnected
                    }
                    let decoded = try decoder.decode(D.self, from: response.data)
                    APIDiagnostics.shared.record(endpoint: endpoint, response: response, error: nil, startedAt: startedAt)
                    completionHandler(decoded, nil)
                } catch {
                    APIDiagnostics.shared.record(endpoint: endpoint, response: response, error: error, startedAt: startedAt)
                    completionHandler(nil, error)
                }
            case .failure(let error):
                APIDiagnostics.shared.record(endpoint: endpoint, response: error.response, error: error, startedAt: startedAt)
                completionHandler(nil, error)
            }
        }
    }
}

public let alamofireSessionWithFasterTimeout: Alamofire.Session = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 4
    configuration.timeoutIntervalForResource = 6
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    return Alamofire.Session(configuration: configuration)
}()
