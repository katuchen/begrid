import SwiftUI

struct DetailPhotoImage: View {
    let photo: Photo
    let previewPixelSize: PixelSize

    @Environment(\.imageLoader) private var loader
    @Environment(\.displayScale) private var displayScale
    @State private var size: CGSize = .zero

    var body: some View {
        let cell = PhotoCellModel(photo: photo)
        let preview = loader.cachedImage(for: cell.imageURL(covering: previewPixelSize), targetPixelSize: previewPixelSize)
        let pixelSize = PixelSize(points: size, scale: displayScale)
        RemoteImage(
            url: cell.imageURL(covering: pixelSize),
            targetPixelSize: pixelSize,
            blurHash: cell.blurHash,
            placeholder: cell.color,
            preview: preview
        )
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
    }
}
