import Foundation
import Testing
@testable import BeGrid

struct AppConfigurationTests {
    @Test func loadsTrimmedKey() throws {
        let config = try AppConfiguration.load(from: [AppConfiguration.accessKeyInfoKey: "  abc123\n"])
        #expect(config.unsplashAccessKey == "abc123")
    }

    @Test(arguments: [
        [:],
        [AppConfiguration.accessKeyInfoKey: ""],
        [AppConfiguration.accessKeyInfoKey: "   "],
        [AppConfiguration.accessKeyInfoKey: "your-access-key-here"],
        [AppConfiguration.accessKeyInfoKey: "$(UNSPLASH_ACCESS_KEY)"]
    ] as [[String: String]])
    func rejectsUnusableKeys(info: [String: String]) {
        #expect(throws: ConfigurationError.missingAccessKey) {
            try AppConfiguration.load(from: info)
        }
    }
}
