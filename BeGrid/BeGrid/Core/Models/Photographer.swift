import Foundation

nonisolated struct Photographer: Hashable, Sendable {
    let name: String
    let username: String
    let profileURL: URL?
}
