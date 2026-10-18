import Foundation

nonisolated struct PhotoURLs: Hashable, Codable, Sendable {
    let raw: URL
    let full: URL
    let regular: URL
    let small: URL
}
