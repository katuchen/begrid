import UIKit

nonisolated struct ImageFetcher: Sendable {
    private let client: any HTTPClient

    init(client: any HTTPClient) {
        self.client = client
    }

    @concurrent
    func image(for url: URL, targetPixelSize: PixelSize?) async throws -> UIImage {
        let data = try await client.validatedData(for: URLRequest(url: url))
        guard let image = ImageDecoder.image(from: data, targetPixelSize: targetPixelSize) else { throw APIError.decoding }
        return image
    }
}
