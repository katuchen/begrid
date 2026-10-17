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
        let data = try await client.validatedData(for: endpoint.request(accessKey: accessKey))
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
