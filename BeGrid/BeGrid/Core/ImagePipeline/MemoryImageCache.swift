import UIKit

nonisolated final class MemoryImageCache: @unchecked Sendable {
    private let cache = NSCache<NSString, UIImage>()
    private let notificationCenter: NotificationCenter
    private let observers: [any NSObjectProtocol]

    init(costLimit: Int = MemoryImageCache.defaultCostLimit, notificationCenter: NotificationCenter = .default) {
        cache.totalCostLimit = costLimit
        self.notificationCenter = notificationCenter
        nonisolated(unsafe) let cache = cache
        observers = [UIApplication.didReceiveMemoryWarningNotification, UIApplication.didEnterBackgroundNotification].map {
            notificationCenter.addObserver(forName: $0, object: nil, queue: nil) { _ in
                cache.removeAllObjects()
            }
        }
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString, cost: Self.cost(of: image))
    }

    static let defaultCostLimit = Int(clamping: ProcessInfo.processInfo.physicalMemory / 8)

    static func cost(of image: UIImage) -> Int {
        if let cgImage = image.cgImage { return cgImage.bytesPerRow * cgImage.height }
        return Int(image.size.width * image.scale) * Int(image.size.height * image.scale) * 4
    }
}
