import Foundation
import Testing
@testable import BeGrid

struct SearchSourceTests {
    @Test(arguments: [(1, true), (4, true), (5, false), (6, false)])
    func lastPageEndsResults(page: Int, hasMore: Bool) async throws {
        let (api, _) = UnsplashAPI.stubbed(.success(try Fixture.data(named: "search")))

        let result = try await SearchSource(query: "cat", api: api).page(page)

        #expect(result.hasMore == hasMore)
    }

    @Test func noResultsHasNoMore() async throws {
        let (api, _) = UnsplashAPI.stubbed(.success(PhotoJSON.search(totalPages: 0, count: 0)))

        let page = try await SearchSource(query: "cat", api: api).page(1)

        #expect(page == Page(photos: [], hasMore: false))
    }

    @Test func mapsResultsAndRequestsQuery() async throws {
        let (api, client) = UnsplashAPI.stubbed(.success(PhotoJSON.search(totalPages: 2, count: 3)))

        let page = try await SearchSource(query: "red car", api: api).page(2)

        #expect(page.photos.map(\.id) == ["photo-0", "photo-1", "photo-2"])
        #expect(await client.requests == [
            UnsplashEndpoint.search(query: "red car", page: 2).request(accessKey: UnsplashAPI.testAccessKey)
        ])
    }
}
