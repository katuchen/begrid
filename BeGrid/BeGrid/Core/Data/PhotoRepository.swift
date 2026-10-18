import Foundation

nonisolated protocol PhotoRepository: Sendable {
    func feedSource() -> any PhotoSource
    func searchSource(query: String) -> any PhotoSource
    func keepOffline(query: String) async
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
        searchStore = PageStore(directory: storeDirectory.appending(path: "Search", directoryHint: .isDirectory), requiresPin: true)
    }

    func feedSource() -> any PhotoSource {
        FallbackSource(id: "feed", upstream: FeedSource(api: api), store: feedStore)
    }

    func searchSource(query: String) -> any PhotoSource {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = Self.id(for: query)
        let upstream = CachedSource(id: id, upstream: SearchSource(query: query, api: api), cache: searchCache)
        return FallbackSource(id: id, upstream: upstream, store: searchStore)
    }

    func keepOffline(query: String) async {
        await searchStore.pin(Self.id(for: query))
    }

    private static func id(for query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
