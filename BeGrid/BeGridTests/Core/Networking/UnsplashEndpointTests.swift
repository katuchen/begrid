import Foundation
import Testing
@testable import BeGrid

struct UnsplashEndpointTests {
    @Test func photosRequestUsesFeedPathAndPagination() throws {
        let request = UnsplashEndpoint.photos(page: 3).request(accessKey: "test-key")
        let components = try #require(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })

        #expect(components.scheme == "https")
        #expect(components.host == "api.unsplash.com")
        #expect(components.path == "/photos")
        #expect(components.queryItems == [
            URLQueryItem(name: "page", value: "3"),
            URLQueryItem(name: "per_page", value: "30")
        ])
    }

    @Test func searchRequestEncodesQuery() throws {
        let request = UnsplashEndpoint.search(query: "red car", page: 1).request(accessKey: "test-key")
        let url = try #require(request.url)

        #expect(url.path() == "/search/photos")
        #expect(url.query() == "query=red%20car&page=1&per_page=30")
    }

    @Test(arguments: [UnsplashEndpoint.photos(page: 1), .search(query: "cats", page: 2)])
    func requestIsAuthenticatedGET(_ endpoint: UnsplashEndpoint) {
        let request = endpoint.request(accessKey: "test-key")

        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Client-ID test-key")
        #expect(request.value(forHTTPHeaderField: "Accept-Version") == "v1")
    }
}
