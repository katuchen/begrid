import Foundation

nonisolated struct SearchResponseDTO: Decodable, Sendable {
    let totalPages: Int
    let results: [PhotoDTO]
}
