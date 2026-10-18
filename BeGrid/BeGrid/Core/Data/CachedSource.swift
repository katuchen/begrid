import Foundation

nonisolated struct CachedSource: PhotoSource {
    private let id: String
    private let upstream: any PhotoSource
    private let cache: PageCache

    init(id: String, upstream: any PhotoSource, cache: PageCache) {
        self.id = id
        self.upstream = upstream
        self.cache = cache
    }

    func page(_ number: Int) async throws -> Page {
        if let cached = await cache.page(number, of: id) {
            return cached
        }
        let page = try await upstream.page(number)
        if !page.isStale {
            await cache.insert(page, number: number, of: id)
        }
        return page
    }
}
