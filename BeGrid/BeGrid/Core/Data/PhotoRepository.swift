import Foundation

nonisolated protocol PhotoRepository: Sendable {
    func feedSource() -> any PhotoSource
    func searchSource(query: String) -> any PhotoSource
}

nonisolated struct UnsplashPhotoRepository: PhotoRepository {
    private let api: UnsplashAPI
    private let searchCache: PageCache

    init(api: UnsplashAPI, searchCache: PageCache = PageCache()) {
        self.api = api
        self.searchCache = searchCache
    }

    func feedSource() -> any PhotoSource {
        FeedSource(api: api)
    }

    func searchSource(query: String) -> any PhotoSource {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return CachedSource(id: query.lowercased(), upstream: SearchSource(query: query, api: api), cache: searchCache)
    }
}
