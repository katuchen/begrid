import Foundation
import Testing
@testable import BeGrid

struct ImageURLBuilderTests {
    private let regular = URL(string:
        "https://images.unsplash.com/photo-1?crop=entropy&cs=tinysrgb&dpr=3&fit=max&fm=png&ixid=M3wxMjA3fDB8MXxhbGx8MXx8&ixlib=rb-4.0.3&q=60&w=1080"
    )

    @Test func keepsUnmanagedParametersVerbatim() throws {
        let base = try #require(regular)
        let url = ImageURLBuilder.url(from: base, pixelWidth: 600)
        let items = queryItems(of: url)

        #expect(values(named: "crop", in: items) == ["entropy"])
        #expect(values(named: "cs", in: items) == ["tinysrgb"])
        #expect(values(named: "fit", in: items) == ["max"])
        #expect(values(named: "ixid", in: items) == ["M3wxMjA3fDB8MXxhbGx8MXx8"])
        #expect(values(named: "ixlib", in: items) == ["rb-4.0.3"])
        #expect(url.host() == base.host())
        #expect(url.path() == base.path())
    }

    @Test func replacesManagedParametersOnce() throws {
        let items = queryItems(of: ImageURLBuilder.url(from: try #require(regular), pixelWidth: 600))

        #expect(values(named: "w", in: items) == ["600"])
        #expect(values(named: "dpr", in: items) == ["1"])
        #expect(values(named: "q", in: items) == ["80"])
        #expect(values(named: "fm", in: items) == ["jpg"])
    }

    @Test func addsManagedParametersToBareURL() throws {
        let raw = try #require(URL(string: "https://images.unsplash.com/photo-1?ixid=abc&ixlib=rb-4.0.3"))
        let items = queryItems(of: ImageURLBuilder.url(from: raw, pixelWidth: 300))

        #expect(values(named: "ixid", in: items) == ["abc"])
        #expect(values(named: "ixlib", in: items) == ["rb-4.0.3"])
        #expect(values(named: "w", in: items) == ["300"])
        #expect(values(named: "dpr", in: items) == ["1"])
        #expect(values(named: "q", in: items) == ["80"])
        #expect(values(named: "fm", in: items) == ["jpg"])
    }

    @Test func clampsWidthToAtLeastOnePixel() throws {
        let base = try #require(URL(string: "https://images.unsplash.com/photo-1?ixid=abc"))
        let items = queryItems(of: ImageURLBuilder.url(from: base, pixelWidth: 0))

        #expect(values(named: "w", in: items) == ["1"])
    }

    private func queryItems(of url: URL) -> [URLQueryItem] {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQueryItems ?? []
    }

    private func values(named name: String, in items: [URLQueryItem]) -> [String?] {
        items.filter { $0.name == name }.map(\.value)
    }
}
