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

struct UnsplashAPIRetryTests {
    private let clock = ManualClock()
    private let serverError = StubHTTPClient.Response.success(Data(), status: 503)

    private func retrying(_ responses: StubHTTPClient.Response...) -> (UnsplashAPI, StubHTTPClient) {
        let client = StubHTTPClient(responses: responses)
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: .seconds(1), clock: clock)
        return (UnsplashAPI(client: client, accessKey: UnsplashAPI.testAccessKey, retryPolicy: policy), client)
    }

    @Test func serverErrorIsRetriedWithBackoff() async throws {
        let (api, client) = retrying(serverError, serverError, .success(Data("[]".utf8)))
        let task = Task { try await api.photos(page: 1) }

        try await waitUntil { clock.sleeperCount == 1 }
        clock.advance(by: .seconds(1))
        try await waitUntil { await client.requests.count == 2 && clock.sleeperCount == 1 }
        clock.advance(by: .seconds(1))
        #expect(await client.requests.count == 2)
        clock.advance(by: .seconds(1))

        #expect(try await task.value.isEmpty)
        #expect(await client.requests.count == 3)
    }

    @Test func lastErrorIsThrownAfterMaxAttempts() async throws {
        let (api, client) = retrying(serverError)
        let task = Task { try await api.photos(page: 1) }

        for _ in 0..<2 {
            try await waitUntil { clock.sleeperCount == 1 }
            clock.advance(by: .seconds(2))
        }

        await #expect(throws: APIError.server(statusCode: 503)) { try await task.value }
        #expect(await client.requests.count == 3)
    }

    @Test(arguments: [
        StubHTTPClient.Response.success(Data(), status: 429),
        .success(Data(), status: 401),
        .success(Data(), status: 404),
        .success(Data("not json".utf8)),
        .failure(URLError(.notConnectedToInternet))
    ])
    func nonTransientErrorIsNotRetried(_ response: StubHTTPClient.Response) async {
        let (api, client) = retrying(response)

        await #expect(throws: APIError.self) { try await api.photos(page: 1) }
        #expect(await client.requests.count == 1)
    }

    @Test func cancellingDuringBackoffStopsRetrying() async throws {
        let (api, client) = retrying(serverError)
        let task = Task { try await api.photos(page: 1) }
        try await waitUntil { clock.sleeperCount == 1 }

        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await client.requests.count == 1)
    }
}
