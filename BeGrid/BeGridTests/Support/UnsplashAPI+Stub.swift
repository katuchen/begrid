import Foundation
@testable import BeGrid

extension UnsplashAPI {
    static let testAccessKey = "test-key"

    static func stubbed(
        _ responses: StubHTTPClient.Response...,
        retryPolicy: RetryPolicy = .none
    ) -> (UnsplashAPI, StubHTTPClient) {
        let client = StubHTTPClient(responses: responses)
        return (UnsplashAPI(client: client, accessKey: testAccessKey, retryPolicy: retryPolicy), client)
    }
}
