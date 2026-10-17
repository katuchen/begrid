import Foundation
@testable import BeGrid

extension UnsplashAPI {
    static let testAccessKey = "test-key"

    static func stubbed(_ response: StubHTTPClient.Response) -> (UnsplashAPI, StubHTTPClient) {
        let client = StubHTTPClient(response)
        return (UnsplashAPI(client: client, accessKey: testAccessKey), client)
    }
}
