import Foundation

nonisolated struct PhotoURLsDTO: Decodable, Sendable {
    let raw: URL
    let full: URL
    let regular: URL
    let small: URL
}
