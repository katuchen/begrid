import Foundation

nonisolated struct PixelSize: Hashable, Codable, Sendable {
    let width: Int
    let height: Int

    var aspectRatio: Double {
        Double(width) / Double(height)
    }
}

nonisolated extension PixelSize {
    init(points: CGSize, scale: CGFloat) {
        self.init(width: Int((points.width * scale).rounded(.up)), height: Int((points.height * scale).rounded(.up)))
    }
}
