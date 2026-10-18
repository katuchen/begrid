import UIKit

actor ImagePipeline: ImageLoading {
    private struct Key: Hashable {
        let url: URL
        let size: PixelSize

        var cacheKey: String {
            "\(size.width)x\(size.height)|\(url.absoluteString)"
        }
    }

    private struct InFlight {
        let id: UUID
        let task: Task<Void, Never>
        var priority: TaskPriority
        var waiters: [UUID: CheckedContinuation<UIImage, any Error>] = [:]
    }

    private let fetcher: ImageFetcher
    private let options: PipelineOptions
    private let memoryCache: MemoryImageCache
    private var inFlight: [Key: InFlight] = [:]

    init(
        client: any HTTPClient = URLSessionHTTPClient(session: URLSessionHTTPClient.makeSession(cachesResponses: false)),
        options: PipelineOptions = PipelineOptions(),
        memoryCache: MemoryImageCache = MemoryImageCache(),
        diskCache: DiskImageCache = DiskImageCache()
    ) {
        fetcher = ImageFetcher(client: client, diskCache: options.diskCache ? diskCache : nil)
        self.options = options
        self.memoryCache = memoryCache
    }

    func image(for url: URL, targetPixelSize: PixelSize) async throws -> UIImage {
        if let cached = cachedImage(for: url, targetPixelSize: targetPixelSize) {
            return cached
        }
        let key = Key(url: url, size: targetPixelSize)
        guard options.deduplication else {
            let image = try await fetch(key)
            store(image, for: key)
            return image
        }
        return try await join(key)
    }

    nonisolated func cachedImage(for url: URL, targetPixelSize: PixelSize) -> UIImage? {
        guard options.memoryCache else { return nil }
        return memoryCache.image(for: Key(url: url, size: targetPixelSize).cacheKey)
    }

    func prefetchImage(for url: URL, targetPixelSize: PixelSize) async {
        guard options.prefetch else { return }
        _ = try? await image(for: url, targetPixelSize: targetPixelSize)
    }

    func waiterCount(for url: URL, targetPixelSize: PixelSize) -> Int {
        inFlight[Key(url: url, size: targetPixelSize)]?.waiters.count ?? 0
    }

    private func join(_ key: Key) async throws -> UIImage {
        try Task.checkCancellation()
        if inFlight[key] == nil {
            start(key)
        } else {
            escalate(key)
        }
        let waiterID = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                inFlight[key]?.waiters[waiterID] = continuation
            }
        } onCancel: {
            Task { await self.leave(waiterID, key: key) }
        }
    }

    private func start(_ key: Key) {
        let id = UUID()
        let task = Task {
            let result = await Result { try await fetch(key) }
            finish(id, key: key, with: result)
        }
        inFlight[key] = InFlight(id: id, task: task, priority: Task.currentPriority)
    }

    private func escalate(_ key: Key) {
        let priority = Task.currentPriority
        guard #available(iOS 26, *), let flight = inFlight[key], priority > flight.priority else { return }
        flight.task.escalatePriority(to: priority)
        inFlight[key]?.priority = priority
    }

    private func leave(_ waiterID: UUID, key: Key) {
        guard let continuation = inFlight[key]?.waiters.removeValue(forKey: waiterID) else { return }
        continuation.resume(throwing: CancellationError())
        if inFlight[key]?.waiters.isEmpty == true {
            inFlight.removeValue(forKey: key)?.task.cancel()
        }
    }

    private func finish(_ flightID: UUID, key: Key, with result: Result<UIImage, any Error>) {
        if case .success(let image) = result {
            store(image, for: key)
        }
        guard inFlight[key]?.id == flightID, let flight = inFlight.removeValue(forKey: key) else { return }
        flight.waiters.values.forEach { $0.resume(with: result) }
    }

    private func fetch(_ key: Key) async throws -> UIImage {
        try await fetcher.image(for: key.url, targetPixelSize: options.downsampling ? key.size : nil)
    }

    private func store(_ image: UIImage, for key: Key) {
        guard options.memoryCache else { return }
        memoryCache.insert(image, for: key.cacheKey)
    }
}
