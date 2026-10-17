import Foundation
import Testing
@testable import BeGrid

actor StubHTTPClient: HTTPClient {
    enum Response: Sendable {
        case success(Data, status: Int = 200, headers: [String: String] = [:])
        case failure(any Error)
    }

    private let response: Response
    private(set) var requests: [URLRequest] = []

    init(_ response: Response) {
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        switch response {
        case let .success(data, status, headers):
            let url = try #require(request.url)
            return (data, try Self.httpResponse(url: url, status: status, headers: headers))
        case let .failure(error):
            throw error
        }
    }

    static func httpResponse(
        url: URL = URL(filePath: "/"),
        status: Int,
        headers: [String: String] = [:]
    ) throws -> HTTPURLResponse {
        try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers))
    }
}
