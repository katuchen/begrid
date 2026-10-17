import Foundation
import Testing
@testable import BeGrid

actor StubHTTPClient: HTTPClient {
    enum Response: Sendable {
        case success(Data, status: Int = 200, headers: [String: String] = [:])
        case failure(any Error)

        func result(for request: URLRequest) throws -> (Data, HTTPURLResponse) {
            switch self {
            case let .success(data, status, headers):
                let url = try #require(request.url)
                return (data, try StubHTTPClient.httpResponse(url: url, status: status, headers: headers))
            case let .failure(error):
                throw error
            }
        }
    }

    private let response: Response
    private(set) var requests: [URLRequest] = []

    init(_ response: Response) {
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        return try response.result(for: request)
    }

    static func httpResponse(
        url: URL = URL(filePath: "/"),
        status: Int,
        headers: [String: String] = [:]
    ) throws -> HTTPURLResponse {
        try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers))
    }
}
