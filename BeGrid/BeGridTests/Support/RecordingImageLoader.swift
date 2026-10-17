import Foundation
import os
import UIKit
@testable import BeGrid

final class RecordingImageLoader: ImageLoading {
    private struct State {
        var started: [URL] = []
        var cancelled: Set<URL> = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    var started: [URL] {
        state.withLock { $0.started }
    }

    var cancelled: Set<URL> {
        state.withLock { $0.cancelled }
    }

    func image(for url: URL, targetPixelSize: PixelSize) async throws -> UIImage {
        throw CancellationError()
    }

    func cachedImage(for url: URL, targetPixelSize: PixelSize) -> UIImage? {
        nil
    }

    func prefetchImage(for url: URL, targetPixelSize: PixelSize) async {
        state.withLock { $0.started.append(url) }
        do {
            try await Task.sleep(for: .seconds(60))
        } catch {
            state.withLock { _ = $0.cancelled.insert(url) }
        }
    }
}
