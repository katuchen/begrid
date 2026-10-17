import Foundation

nonisolated struct UnsplashAPI: Sendable {
    private let client: any HTTPClient
    private let accessKey: String
    private let decoder = JSONDecoder.unsplash()

    init(client: any HTTPClient, accessKey: String) {
        self.client = client
        self.accessKey = accessKey
    }

    func photos(page: Int) async throws -> [PhotoDTO] {
        try await send(.photos(page: page))
    }

    func search(query: String, page: Int) async throws -> SearchResponseDTO {
        try await send(.search(query: query, page: page))
    }

    @concurrent
    private func send<T: Decodable & Sendable>(_ endpoint: UnsplashEndpoint) async throws -> T {
        let (data, response) = try await fetch(endpoint)
        if let error = APIError.from(response) {
            throw error
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func fetch(_ endpoint: UnsplashEndpoint) async throws -> (Data, HTTPURLResponse) {
        do {
            let result = try await client.data(for: endpoint.request(accessKey: accessKey))
            try Task.checkCancellation()
            return result
        } catch {
            try Task.checkCancellation()
            switch error {
            case let urlError as URLError: throw APIError.from(urlError)
            case is CancellationError: throw error
            default: throw APIError.server(statusCode: nil)
            }
        }
    }
}
