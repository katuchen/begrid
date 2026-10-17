import Foundation

nonisolated struct UserDTO: Decodable, Sendable {
    let username: String
    let name: String?
    let links: UserLinksDTO?
}
