import Foundation

nonisolated protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

nonisolated extension HTTPClient {
    func validatedData(for request: URLRequest) async throws -> Data {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await self.data(for: request)
        } catch {
            try Task.checkCancellation()
            switch error {
            case let urlError as URLError: throw APIError.from(urlError)
            case is CancellationError: throw error
            default: throw APIError.server(statusCode: nil)
            }
        }
        try Task.checkCancellation()
        if let error = APIError.from(response) {
            throw error
        }
        return data
    }
}

nonisolated struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = URLSessionHTTPClient.makeSession()) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, httpResponse)
    }

    static func makeSession(cachesResponses: Bool = true) -> URLSession {
        let configuration = URLSessionConfiguration.default
        if !cachesResponses {
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        }
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }
}
