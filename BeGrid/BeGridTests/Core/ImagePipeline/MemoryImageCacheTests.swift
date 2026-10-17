import Foundation
import Testing
import UIKit
@testable import BeGrid

struct MemoryImageCacheTests {
    private func makeImage() throws -> UIImage {
        try #require(UIImage(data: ImageFixture.png(width: 40, height: 30)))
    }

    @Test(arguments: [UIApplication.didReceiveMemoryWarningNotification, UIApplication.didEnterBackgroundNotification])
    func notificationClearsCache(name: Notification.Name) throws {
        let center = NotificationCenter()
        let cache = MemoryImageCache(notificationCenter: center)
        cache.insert(try makeImage(), for: "photo")

        center.post(name: name, object: nil)

        #expect(cache.image(for: "photo") == nil)
    }

    @Test func costIsDecodedByteSize() throws {
        let image = try makeImage()
        let cgImage = try #require(image.cgImage)

        #expect(MemoryImageCache.cost(of: image) == cgImage.bytesPerRow * 30)
        #expect(cgImage.bytesPerRow >= 40 * 4)
    }
}
