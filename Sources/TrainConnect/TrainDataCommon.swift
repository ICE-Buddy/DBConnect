import Foundation
import Moya
import Alamofire

public extension MoyaProvider {
    func loadJson<D: Decodable>(decoder: JSONDecoder = .init(),
                                target: Target,
                                completionHandler: @escaping (D?, Error?) -> ()) {
        request(target) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    if response.data.isEmpty {
                        // iceportal.de outside WiFi returns 200 with an empty body.
                        completionHandler(nil, TrainConnectionError.notConnected)
                    }
                    else {
                        let result = try decoder.decode(D.self, from: response.data)
                        completionHandler(result, nil)
                    }
                } catch let error {
                    logDecodingError(error: error)
                    completionHandler(nil, error)
                }
                break
            case .failure(let error):
                print(error.localizedDescription)
                completionHandler(nil, error)
                break
            }
        }
    }
}

private func logDecodingError(error: Error) {
    switch error {
    case DecodingError.dataCorrupted(let context):
        print(context)
    case DecodingError.keyNotFound(let key, let context):
        print("Key '\(key)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    case DecodingError.valueNotFound(let value, let context):
        print("Value '\(value)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    case DecodingError.typeMismatch(let type, let context):
        print("Type '\(type)' mismatch:", context.debugDescription)
        print("codingPath:", context.codingPath)
    default:
        print(error.localizedDescription)
    }
}

public let alamofireSessionWithFasterTimeout: Alamofire.Session = {
    let configuration = URLSessionConfiguration.default
    // Use a very short timeout so we don't wait a minute before showing the "not connected" UI
    configuration.timeoutIntervalForRequest = 2
    configuration.timeoutIntervalForResource = 2
    return Alamofire.Session(configuration: configuration)
}()
