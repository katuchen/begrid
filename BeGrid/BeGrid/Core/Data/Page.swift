import Foundation

nonisolated struct Page: Equatable, Sendable {
    let photos: [Photo]
    let hasMore: Bool
}
