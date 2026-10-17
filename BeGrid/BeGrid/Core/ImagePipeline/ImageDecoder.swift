import ImageIO
import UIKit

nonisolated enum ImageDecoder {
    static func image(from data: Data, targetPixelSize: PixelSize?) -> UIImage? {
        let image = if let targetPixelSize { thumbnail(from: data, covering: targetPixelSize) } else { UIImage(data: data) }
        return image.map { $0.preparingForDisplay() ?? $0 }
    }

    private static func thumbnail(from data: Data, covering target: PixelSize) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions),
              let sourceSize = pixelSize(of: source) else { return nil }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize(of: sourceSize, covering: target)
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    static func maxPixelSize(of source: PixelSize, covering target: PixelSize) -> Int {
        let scale = min(1, max(
            Double(target.width) / Double(source.width),
            Double(target.height) / Double(source.height)
        ))
        return max(Int((Double(max(source.width, source.height)) * scale).rounded(.up)), 1)
    }

    private static func pixelSize(of source: CGImageSource) -> PixelSize? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else { return nil }

        let orientation = properties[kCGImagePropertyOrientation] as? UInt32 ?? 1
        return (5...8).contains(orientation) ? PixelSize(width: height, height: width) : PixelSize(width: width, height: height)
    }
}
