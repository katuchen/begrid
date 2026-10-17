import Foundation

nonisolated struct PixelSize: Hashable, Sendable {
    let width: Int
    let height: Int

    var aspectRatio: Double {
        Double(width) / Double(height)
    }
}
