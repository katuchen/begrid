import Foundation

nonisolated struct AppConfiguration: Sendable, Equatable {
    static let accessKeyInfoKey = "UnsplashAccessKey"

    let unsplashAccessKey: String

    static func load(from bundle: Bundle = .main) throws(ConfigurationError) -> AppConfiguration {
        try load(from: bundle.infoDictionary ?? [:])
    }

    static func load(from infoDictionary: [String: Any]) throws(ConfigurationError) -> AppConfiguration {
        let rawKey = (infoDictionary[accessKeyInfoKey] as? String) ?? ""
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isUsable(key) else { throw .missingAccessKey }
        return AppConfiguration(unsplashAccessKey: key)
    }

    private static func isUsable(_ key: String) -> Bool {
        !key.isEmpty && key != "your-access-key-here" && !key.hasPrefix("$(")
    }
}

nonisolated enum ConfigurationError: Error, Equatable {
    case missingAccessKey
}
