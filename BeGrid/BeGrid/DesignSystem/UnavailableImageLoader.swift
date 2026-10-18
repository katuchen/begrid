import UIKit

nonisolated struct UnavailableImageLoader: ImageLoading {
    struct Unavailable: Error {}

    func image(for url: URL, targetPixelSize: PixelSize) async throws -> UIImage {
        throw Unavailable()
    }

    func cachedImage(for url: URL, targetPixelSize: PixelSize) -> UIImage? {
        nil
    }

    func prefetchImage(for url: URL, targetPixelSize: PixelSize) async {}
}
