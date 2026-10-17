import Foundation

nonisolated struct SearchSource: PhotoSource {
    private let query: String
    private let api: UnsplashAPI

    init(query: String, api: UnsplashAPI) {
        self.query = query
        self.api = api
    }

    func page(_ number: Int) async throws -> Page {
        let response = try await api.search(query: query, page: number)
        return Page(photos: PhotoMapper.photos(from: response.results), hasMore: number < response.totalPages)
    }
}
