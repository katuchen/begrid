import Foundation

nonisolated protocol PhotoRepository: Sendable {
    func feedSource() -> any PhotoSource
    func searchSource(query: String) -> any PhotoSource
}

nonisolated struct UnsplashPhotoRepository: PhotoRepository {
    private let api: UnsplashAPI
    private let searchCache: PageCache
    private let feedStore: PageStore
    private let searchStore: PageStore

    init(
        api: UnsplashAPI,
        searchCache: PageCache = PageCache(),
        storeDirectory: URL = URL.cachesDirectory.appending(path: "Pages", directoryHint: .isDirectory)
    ) {
        self.api = api
        self.searchCache = searchCache
        feedStore = PageStore(directory: storeDirectory.appending(path: "Feed", directoryHint: .isDirectory), sourceLimit: 1)
        searchStore = PageStore(directory: storeDirectory.appending(path: "Search", directoryHint: .isDirectory))
    }

    func feedSource() -> any PhotoSource {
        FallbackSource(id: "feed", upstream: FeedSource(api: api), store: feedStore)
    }

    func searchSource(query: String) -> any PhotoSource {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = query.lowercased()
        let upstream = FallbackSource(id: id, upstream: SearchSource(query: query, api: api), store: searchStore)
        return CachedSource(id: id, upstream: upstream, cache: searchCache)
    }
}
