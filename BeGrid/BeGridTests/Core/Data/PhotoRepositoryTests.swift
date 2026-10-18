import Foundation
import Testing
@testable import BeGrid

struct PhotoRepositoryTests {
    private func makeRepository(_ response: StubHTTPClient.Response) -> (UnsplashPhotoRepository, StubHTTPClient) {
        let (api, client) = UnsplashAPI.stubbed(response)
        return (UnsplashPhotoRepository(api: api, storeDirectory: TemporaryDirectory.make()), client)
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

    @Test(arguments: [false, true])
    func searchIsSavedForOfflineOnlyWhenKept(kept: Bool) async throws {
        let directory = TemporaryDirectory.make()
        let (api, _) = UnsplashAPI.stubbed(.success(try Fixture.data(named: "search")))
        let repository = UnsplashPhotoRepository(api: api, storeDirectory: directory)
        _ = try await repository.searchSource(query: "Cat").page(1)
        if kept {
            await repository.keepOffline(query: " cat ")
        }

        let (offlineAPI, _) = UnsplashAPI.stubbed(.failure(URLError(.notConnectedToInternet)))
        let offline = UnsplashPhotoRepository(api: offlineAPI, storeDirectory: directory)
        let page = try? await offline.searchSource(query: "cat").page(1)

        #expect(page?.isStale == (kept ? true : nil))
    }

    @Test func feedIsNotCached() async throws {
        let (repository, client) = makeRepository(.success(try Fixture.data(named: "photos")))

        _ = try await repository.feedSource().page(1)
        _ = try await repository.feedSource().page(1)

        #expect(await client.requests.count == 2)
    }
}
