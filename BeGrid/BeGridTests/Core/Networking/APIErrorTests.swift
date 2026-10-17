import Foundation
import Testing
@testable import BeGrid

struct APIErrorTests {
    struct StatusCase: Sendable, CustomTestStringConvertible {
        let status: Int
        let remaining: String?
        let expected: APIError?

        var testDescription: String {
            "\(status), remaining: \(remaining ?? "nil")"
        }
    }

    @Test(arguments: [
        StatusCase(status: 200, remaining: nil, expected: nil),
        StatusCase(status: 200, remaining: "0", expected: nil),
        StatusCase(status: 401, remaining: nil, expected: .unauthorized),
        StatusCase(status: 403, remaining: nil, expected: .rateLimited),
        StatusCase(status: 429, remaining: nil, expected: .rateLimited),
        StatusCase(status: 500, remaining: "0", expected: .rateLimited),
        StatusCase(status: 500, remaining: "12", expected: .server(statusCode: 500)),
        StatusCase(status: 404, remaining: nil, expected: .server(statusCode: 404))
    ])
    func classifiesStatus(_ testCase: StatusCase) throws {
        let headers = testCase.remaining.map { [APIError.rateLimitRemainingHeader: $0] } ?? [:]
        let response = try StubHTTPClient.httpResponse(status: testCase.status, headers: headers)

        #expect(APIError.from(response) == testCase.expected)
    }

    @Test(arguments: [
        URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff,
        .cannotFindHost, .cannotConnectToHost, .timedOut
    ])
    func connectivityErrorsAreOffline(_ code: URLError.Code) {
        #expect(APIError.from(URLError(code)) == .offline)
    }

    @Test func otherURLErrorsAreServerErrors() {
        #expect(APIError.from(URLError(.badServerResponse)) == .server(statusCode: nil))
    }
}
