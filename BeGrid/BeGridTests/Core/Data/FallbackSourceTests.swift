import Foundation
import Testing
@testable import BeGrid

struct FallbackSourceTests {
    private let directory = TemporaryDirectory.make()

    private func makeSource(
        _ script: [Int: [Result<Page, any Error>]],
        id: String = "feed",
        store: PageStore? = nil
    ) -> FallbackSource {
        FallbackSource(id: id, upstream: ScriptedSource(script), store: store ?? PageStore(directory: directory))
    }

    @Test func savedPageIsReturnedAsStaleWhenTheNetworkFails() async throws {
        let source = makeSource([1: [.success(.of("a", "b")), .failure(APIError.offline)]])

        let fresh = try await source.page(1)
        let fallback = try await source.page(1)

        #expect(!fresh.isStale)
        #expect(fallback == Page(photos: fresh.photos, hasMore: true, isStale: true))
    }

    @Test func failureWithoutASavedPageRethrows() async throws {
        let source = makeSource([1: [.success(.of("a"))], 2: [.failure(APIError.offline)]])
        _ = try await source.page(1)

        await #expect(throws: APIError.offline) { try await source.page(2) }
    }

    @Test func cancellationDoesNotFallBack() async throws {
        let source = makeSource([1: [.success(.of("a")), .failure(CancellationError())]])
        _ = try await source.page(1)

        await #expect(throws: CancellationError.self) { try await source.page(1) }
    }

    @Test func savedPagesAreReadBackByANewStore() async throws {
        _ = try await makeSource([1: [.success(.of("a"))]]).page(1)

        let page = try await makeSource([1: [.failure(APIError.offline)]]).page(1)

        #expect(page.photos.map(\.id) == ["a"])
        #expect(page.isStale)
    }

    @Test func sourcesAreSavedSeparately() async throws {
        _ = try await makeSource([1: [.success(.of("cat"))]], id: "cat").page(1)

        await #expect(throws: APIError.offline) {
            try await makeSource([1: [.failure(APIError.offline)]], id: "dog").page(1)
        }
    }

    @Test func pagesPastTheLimitAreNotSaved() async throws {
        let store = PageStore(directory: directory, pageLimit: 1)
        let source = makeSource([1: [.success(.of("a"))], 2: [.success(.of("b")), .failure(APIError.offline)]], store: store)
        _ = try await source.page(1)
        _ = try await source.page(2)

        await #expect(throws: APIError.offline) { try await source.page(2) }
    }

    @Test func oldestSourceIsEvictedPastLimit() async throws {
        let date = SteppingDate()
        let store = PageStore(directory: directory, sourceLimit: 2) { date.next() }
        for id in ["cat", "dog", "cat", "owl"] {
            _ = try await makeSource([1: [.success(.of(id))]], id: id, store: store).page(1)
        }

        for id in ["cat", "owl"] {
            _ = try await makeSource([1: [.failure(APIError.offline)]], id: id, store: store).page(1)
        }
        await #expect(throws: APIError.offline) {
            try await makeSource([1: [.failure(APIError.offline)]], id: "dog", store: store).page(1)
        }
    }
}
