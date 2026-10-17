import Foundation

final class ImagePrefetcher {
    nonisolated struct Request: Hashable, Sendable {
        let url: URL
        let size: PixelSize
    }

    private struct Prefetch {
        let index: Int
        let task: Task<Void, Never>
    }

    static let distance = 12

    private var prefetches: [Request: Prefetch] = [:]

    func prefetch(_ requests: [Request], after index: Int, using loader: any ImageLoading) {
        let window = (index + 1)..<(index + 1 + requests.count)
        for (request, prefetch) in prefetches where !window.contains(prefetch.index) {
            if prefetch.index >= window.upperBound {
                prefetch.task.cancel()
            }
            prefetches[request] = nil
        }
        for (offset, request) in requests.enumerated() where prefetches[request] == nil {
            guard loader.cachedImage(for: request.url, targetPixelSize: request.size) == nil else { continue }
            let task = Task(priority: .utility) {
                await loader.prefetchImage(for: request.url, targetPixelSize: request.size)
            }
            prefetches[request] = Prefetch(index: window.lowerBound + offset, task: task)
        }
    }
}
