import Foundation

nonisolated struct PhotoURLs: Hashable, Sendable {
    let raw: URL
    let full: URL
    let regular: URL
    let small: URL
}
