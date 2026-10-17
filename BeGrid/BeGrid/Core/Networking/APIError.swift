import Foundation

nonisolated enum APIError: Error, Equatable, Sendable {
    case offline
    case rateLimited
    case unauthorized
    case server(statusCode: Int?)
    case decoding

    static let rateLimitRemainingHeader = "X-Ratelimit-Remaining"

    static func from(_ response: HTTPURLResponse) -> APIError? {
        switch response.statusCode {
        case 200..<300: nil
        case 401: .unauthorized
        case 403, 429: .rateLimited
        default:
            response.value(forHTTPHeaderField: rateLimitRemainingHeader) == "0"
                ? .rateLimited
                : .server(statusCode: response.statusCode)
        }
    }

    static func from(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff,
             .cannotFindHost, .cannotConnectToHost, .timedOut:
            .offline
        default:
            .server(statusCode: nil)
        }
    }
}
