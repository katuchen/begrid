import Foundation

nonisolated enum UnsplashEndpoint: Sendable {
    case photos(page: Int)
    case search(query: String, page: Int)

    static let perPage = 30

    func request(accessKey: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        return request
    }

    private var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.unsplash.com"
        components.path = path
        components.queryItems = queryItems
        guard let url = components.url else { preconditionFailure("Invalid Unsplash endpoint: \(self)") }
        return url
    }

    private var path: String {
        switch self {
        case .photos: "/photos"
        case .search: "/search/photos"
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case let .photos(page):
            Self.pagination(page)
        case let .search(query, page):
            [URLQueryItem(name: "query", value: query)] + Self.pagination(page)
        }
    }

    private static func pagination(_ page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
    }
}
