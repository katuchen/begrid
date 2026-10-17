import Foundation

nonisolated extension JSONDecoder {
    static func unsplash() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
