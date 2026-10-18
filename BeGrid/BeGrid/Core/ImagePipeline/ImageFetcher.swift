import UIKit

nonisolated struct ImageFetcher: Sendable {
    private let client: any HTTPClient
    private let diskCache: DiskImageCache?

    init(client: any HTTPClient, diskCache: DiskImageCache? = nil) {
        self.client = client
        self.diskCache = diskCache
    }

    @concurrent
    func image(for url: URL, targetPixelSize: PixelSize?) async throws -> UIImage {
        if let data = await diskCache?.data(for: url),
           let image = ImageDecoder.image(from: data, targetPixelSize: targetPixelSize) {
            return image
        }
        let data = try await client.validatedData(for: URLRequest(url: url))
        guard let image = ImageDecoder.image(from: data, targetPixelSize: targetPixelSize) else { throw APIError.decoding }
        await diskCache?.store(data, for: url)
        return image
    }
}
