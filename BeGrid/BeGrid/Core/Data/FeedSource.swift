import Foundation

nonisolated struct FeedSource: PhotoSource {
    private let api: UnsplashAPI

    init(api: UnsplashAPI) {
        self.api = api
    }

    func page(_ number: Int) async throws -> Page {
        let dtos = try await api.photos(page: number)
        return Page(photos: PhotoMapper.photos(from: dtos), hasMore: dtos.count >= UnsplashEndpoint.perPage)
    }
}
