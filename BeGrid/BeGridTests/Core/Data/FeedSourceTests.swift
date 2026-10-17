import Foundation
import Testing
@testable import BeGrid

struct FeedSourceTests {
    @Test(arguments: [(0, false), (UnsplashEndpoint.perPage - 1, false), (UnsplashEndpoint.perPage, true)])
    func shortPageEndsFeed(count: Int, hasMore: Bool) async throws {
        let (api, _) = UnsplashAPI.stubbed(.success(PhotoJSON.photos(count: count)))

        let page = try await FeedSource(api: api).page(1)

        #expect(page.photos.count == count)
        #expect(page.hasMore == hasMore)
    }

    @Test func mapsPhotosAndRequestsPage() async throws {
        let (api, client) = UnsplashAPI.stubbed(.success(try Fixture.data(named: "photos")))

        let page = try await FeedSource(api: api).page(3)

        #expect(page.photos.map(\.id) == ["feed-1", "feed-2"])
        #expect(await client.requests == [UnsplashEndpoint.photos(page: 3).request(accessKey: UnsplashAPI.testAccessKey)])
    }
}
