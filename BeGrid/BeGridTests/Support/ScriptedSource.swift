import Foundation
@testable import BeGrid

actor ScriptedSource: PhotoSource {
    private var script: [Int: [Result<Page, any Error>]]
    private var isOpen: Bool
    private(set) var requestedPages: [Int] = []

    init(_ script: [Int: [Result<Page, any Error>]], isOpen: Bool = true) {
        self.script = script
        self.isOpen = isOpen
    }

    init(pages: [Page], isOpen: Bool = true) {
        self.init(Dictionary(uniqueKeysWithValues: pages.enumerated().map { ($0.offset + 1, [.success($0.element)]) }), isOpen: isOpen)
    }

    func open() {
        isOpen = true
    }

    func close() {
        isOpen = false
    }

    func page(_ number: Int) async throws -> Page {
        requestedPages.append(number)
        while !isOpen {
            try await Task.sleep(for: .milliseconds(5))
        }
        guard let results = script[number], let result = results.first else { return Page(photos: [], hasMore: false) }
        if results.count > 1 {
            script[number] = Array(results.dropFirst())
        }
        return try result.get()
    }
}

extension Page {
    static func of(_ ids: String..., hasMore: Bool = true) -> Page {
        Page(photos: ids.map { Photo.stub(id: $0) }, hasMore: hasMore)
    }
}

extension Photo {
    static func stub(
        id: String,
        summary: String? = nil,
        size: PixelSize? = nil,
        blurHash: String? = nil,
        averageColor: String? = nil
    ) -> Photo {
        let url = URL(string: "https://images.unsplash.com/\(id)?ixid=abc") ?? URL(filePath: "/")
        return Photo(
            id: id,
            summary: summary,
            size: size,
            blurHash: blurHash,
            averageColor: averageColor,
            urls: PhotoURLs(raw: url, full: url, regular: url, small: url),
            photographer: Photographer(name: "Name", username: "user", profileURL: nil)
        )
    }
}
