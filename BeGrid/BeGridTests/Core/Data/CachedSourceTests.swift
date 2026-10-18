import Foundation
import Testing
@testable import BeGrid

struct CachedSourceTests {
    private struct Failure: Error {}

    private func cached(_ id: String, _ upstream: CountingSource, cache: PageCache) -> CachedSource {
        CachedSource(id: id, upstream: upstream, cache: cache)
    }

    @Test func repeatedPageIsServedFromCache() async throws {
        let upstream = CountingSource()
        let cache = PageCache()

        let first = try await cached("cat", upstream, cache: cache).page(1)
        let second = try await cached("cat", upstream, cache: cache).page(1)

        #expect(first == second)
        #expect(await upstream.requestedPages == [1])
    }

    @Test func differentSourceOrPageIsFetched() async throws {
        let upstream = CountingSource()
        let cache = PageCache()

        _ = try await cached("cat", upstream, cache: cache).page(1)
        _ = try await cached("cat", upstream, cache: cache).page(2)
        _ = try await cached("dog", upstream, cache: cache).page(1)

        #expect(await upstream.requestedPages == [1, 2, 1])
    }

    @Test func failureIsNotCached() async throws {
        let cache = PageCache()
        await #expect(throws: Failure.self) {
            try await cached("cat", CountingSource(.failure(Failure())), cache: cache).page(1)
        }

        let upstream = CountingSource()
        _ = try await cached("cat", upstream, cache: cache).page(1)

        #expect(await upstream.requestedPages == [1])
    }

    @Test func stalePageIsNotCached() async throws {
        let upstream = CountingSource(.success(Page(photos: [], hasMore: true, isStale: true)))
        let cache = PageCache()

        _ = try await cached("cat", upstream, cache: cache).page(1)
        _ = try await cached("cat", upstream, cache: cache).page(1)

        #expect(await upstream.requestedPages == [1, 1])
    }

    @Test func expiredSourceIsFetchedAgain() async throws {
        let clock = TestClock()
        let cache = PageCache(lifetime: 60) { clock.now }
        let upstream = CountingSource()
        let source = cached("cat", upstream, cache: cache)

        _ = try await source.page(1)
        clock.advance(by: 59)
        _ = try await source.page(2)
        clock.advance(by: 1)
        _ = try await source.page(1)
        _ = try await source.page(2)

        #expect(await upstream.requestedPages == [1, 2, 1, 2])
    }

    @Test func oldestSourceIsEvictedPastLimit() async throws {
        let upstream = CountingSource()
        let cache = PageCache(sourceLimit: 2)

        for id in ["cat", "dog", "cat", "owl", "cat", "dog"] {
            _ = try await cached(id, upstream, cache: cache).page(1)
        }

        #expect(await upstream.requestedPages.count == 4)
    }
}
