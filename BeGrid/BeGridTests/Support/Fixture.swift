import Foundation
@testable import BeGrid

enum Fixture {
    private final class BundleToken {}

    struct MissingFixture: Error {
        let name: String
    }

    static func data(named name: String) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else { throw MissingFixture(name: name) }
        return try Data(contentsOf: url)
    }

    static func decode<T: Decodable>(_ type: T.Type, named name: String) throws -> T {
        try JSONDecoder.unsplash().decode(type, from: data(named: name))
    }
}
