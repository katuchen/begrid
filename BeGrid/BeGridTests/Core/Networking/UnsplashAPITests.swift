import Foundation
import Testing
@testable import BeGrid

struct UnsplashAPITests {
    @Test func photosDecodesFeedPage() async throws {
        let (api, client) = UnsplashAPI.stubbed(.success(try Fixture.data(named: "photos")))

        let photos = try await api.photos(page: 2)

        #expect(photos.map(\.id) == ["feed-1", "feed-2"])
        #expect(await client.requests == [UnsplashEndpoint.photos(page: 2).request(accessKey: UnsplashAPI.testAccessKey)])
    }

    @Test func searchDecodesResponse() async throws {
        let (api, client) = UnsplashAPI.stubbed(.success(try Fixture.data(named: "search")))

        let response = try await api.search(query: "red car", page: 1)

        #expect(!response.results.isEmpty)
        #expect(await client.requests == [UnsplashEndpoint.search(query: "red car", page: 1).request(accessKey: UnsplashAPI.testAccessKey)])
    }

    @Test func forbiddenIsRateLimited() async {
        let (api, _) = UnsplashAPI.stubbed(.success(Data(), status: 403))

        await #expect(throws: APIError.rateLimited) { try await api.photos(page: 1) }
    }

    @Test func invalidJSONIsDecodingError() async {
        let (api, _) = UnsplashAPI.stubbed(.success(Data("not json".utf8)))

        await #expect(throws: APIError.decoding) { try await api.photos(page: 1) }
    }

    @Test func noConnectionIsOffline() async {
        let (api, _) = UnsplashAPI.stubbed(.failure(URLError(.notConnectedToInternet)))

        await #expect(throws: APIError.offline) { try await api.photos(page: 1) }
    }

    @Test(arguments: [StubHTTPClient.Response.success(Data("[]".utf8)), .failure(URLError(.cancelled))])
    func cancelledTaskThrowsCancellationError(_ response: StubHTTPClient.Response) async {
        let (api, _) = UnsplashAPI.stubbed(response)

        let task = Task { try await api.photos(page: 1) }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func sessionCancellationWithoutTaskCancellationIsServerError() async {
        let (api, _) = UnsplashAPI.stubbed(.failure(URLError(.cancelled)))

        await #expect(throws: APIError.server(statusCode: nil)) { try await api.photos(page: 1) }
    }
}
