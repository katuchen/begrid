import Foundation

nonisolated struct Photographer: Hashable, Codable, Sendable {
    let name: String
    let username: String
    let profileURL: URL?
}
