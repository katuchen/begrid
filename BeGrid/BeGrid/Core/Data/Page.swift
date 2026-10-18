import Foundation

nonisolated struct Page: Equatable, Sendable {
    let photos: [Photo]
    let hasMore: Bool
    var staleReason: APIError?

    var isStale: Bool {
        staleReason != nil
    }
}
