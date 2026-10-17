import Foundation

nonisolated protocol PhotoSource: Sendable {
    func page(_ number: Int) async throws -> Page
}
