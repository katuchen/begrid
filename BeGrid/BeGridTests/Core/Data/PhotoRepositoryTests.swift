import Foundation
import Testing
@testable import BeGrid

struct PhotoRepositoryTests {
    private func makeRepository(_ response: StubHTTPClient.Response) -> (UnsplashPhotoRepository, StubHTTPClient) {
        let (api, client) = UnsplashAPI.stubbed(response)
        return (UnsplashPhotoRepository(api: api), client)
    }

    @Test func repeatedSearchIsServedFromCache() async throws {
        let (repository, client) = makeRepository(.success(try Fixture.data(named: "search")))

        let first = try await repository.searchSource(query: "cat").page(1)
        let second = try await repository.searchSource(query: "cat").page(1)

        #expect(first == second)
        #expect(await client.requests.count == 1)
    }

    @Test func queryIsTrimmedAndMatchedCaseInsensitively() async throws {
        let (repository, client) = makeRepository(.success(try Fixture.data(named: "search")))

        _ = try await repository.searchSource(query: "  Red Car\n").page(1)
        _ = try await repository.searchSource(query: "red car").page(1)

        #expect(await client.requests == [
            UnsplashEndpoint.search(query: "Red Car", page: 1).request(accessKey: UnsplashAPI.testAccessKey)
        ])
    }

    @Test func feedIsNotCached() async throws {
        let (repository, client) = makeRepository(.success(try Fixture.data(named: "photos")))

        _ = try await repository.feedSource().page(1)
        _ = try await repository.feedSource().page(1)

        #expect(await client.requests.count == 2)
    }
}
