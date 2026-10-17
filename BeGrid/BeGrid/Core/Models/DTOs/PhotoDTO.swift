import Foundation

nonisolated struct PhotoDTO: Decodable, Sendable {
    let id: String
    let width: Int?
    let height: Int?
    let color: String?
    let blurHash: String?
    let description: String?
    let altDescription: String?
    let urls: PhotoURLsDTO
    let user: UserDTO
}
