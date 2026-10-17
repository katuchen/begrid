import Foundation
@testable import BeGrid

actor CountingSource: PhotoSource {
    private let result: Result<Page, any Error>
    private(set) var requestedPages: [Int] = []

    init(_ result: Result<Page, any Error> = .success(Page(photos: [], hasMore: true))) {
        self.result = result
    }

    func page(_ number: Int) async throws -> Page {
        requestedPages.append(number)
        return try result.get()
    }
}
