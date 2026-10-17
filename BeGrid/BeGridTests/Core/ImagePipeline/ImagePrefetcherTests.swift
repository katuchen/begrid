import Foundation
import Testing
@testable import BeGrid

@MainActor
struct ImagePrefetcherTests {
    private let size = PixelSize(width: 100, height: 100)
    private let loader = RecordingImageLoader()
    private let prefetcher = ImagePrefetcher()

    private func requests(_ range: ClosedRange<Int>) -> [ImagePrefetcher.Request] {
        range.map { ImagePrefetcher.Request(url: URL(filePath: "/\($0).jpg"), size: size) }
    }

    private func urls(_ range: ClosedRange<Int>) -> Set<URL> {
        Set(requests(range).map(\.url))
    }

    @Test func scrollingBackCancelsRequestsBeyondTheWindow() async throws {
        prefetcher.prefetch(requests(5...8), after: 4, using: loader)
        try await waitUntil { loader.started.count == 4 }

        prefetcher.prefetch(requests(3...6), after: 2, using: loader)
        try await waitUntil { loader.started.count == 6 && loader.cancelled.count == 2 }

        #expect(loader.cancelled == urls(7...8))
        #expect(Set(loader.started) == urls(3...8))
    }

    @Test func scrollingForwardKeepsEarlierRequests() async throws {
        prefetcher.prefetch(requests(1...4), after: 0, using: loader)
        prefetcher.prefetch(requests(3...6), after: 2, using: loader)
        try await waitUntil { loader.started.count == 6 }

        #expect(Set(loader.started) == urls(1...6))
        #expect(loader.cancelled.isEmpty)
    }
}
