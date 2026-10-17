import Foundation

nonisolated struct Photo: Identifiable, Hashable, Sendable {
    static let defaultAspectRatio = 4.0 / 5.0

    let id: String
    let summary: String?
    let size: PixelSize?
    let blurHash: String?
    let averageColor: String?
    let urls: PhotoURLs
    let photographer: Photographer

    var aspectRatio: Double {
        size?.aspectRatio ?? Self.defaultAspectRatio
    }
}
