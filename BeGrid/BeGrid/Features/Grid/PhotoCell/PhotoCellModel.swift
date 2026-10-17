import SwiftUI

nonisolated struct PhotoCellModel: Identifiable, Equatable {
    let id: Photo.ID
    let summary: String?
    let accessibilityLabel: String
    let url: URL
    let blurHash: String?
    let color: Color
    let aspectRatio: Double

    init(photo: Photo) {
        id = photo.id
        summary = photo.summary
        accessibilityLabel = photo.accessibilityLabel
        url = photo.urls.regular
        blurHash = photo.blurHash
        color = photo.averageColor.flatMap(Color.init(hex:)) ?? .photoPlaceholder
        aspectRatio = photo.aspectRatio
    }

    func imageURL(covering size: PixelSize) -> URL {
        let width = max(size.width, Int((Double(size.height) * aspectRatio).rounded(.up)))
        return ImageURLBuilder.url(from: url, pixelWidth: width)
    }
}
