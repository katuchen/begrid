import UIKit

nonisolated protocol ImageLoading: Sendable {
    func image(for url: URL, targetPixelSize: PixelSize) async throws -> UIImage
    func cachedImage(for url: URL, targetPixelSize: PixelSize) -> UIImage?
    func prefetchImage(for url: URL, targetPixelSize: PixelSize) async
}
