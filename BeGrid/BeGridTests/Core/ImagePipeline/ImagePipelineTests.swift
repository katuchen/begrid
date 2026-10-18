import Foundation
import Testing
import UIKit
@testable import BeGrid

struct ImagePipelineTests {
    private let url = URL(filePath: "/photo.jpg")
    private let size = PixelSize(width: 100, height: 100)
    private let directory = TemporaryDirectory.make()

    private func makePipeline(
        _ response: StubHTTPClient.Response? = nil,
        isOpen: Bool = true,
        options: PipelineOptions = PipelineOptions()
    ) throws -> (ImagePipeline, GatedHTTPClient) {
        let client = try GatedHTTPClient(response ?? .success(ImageFixture.png(width: 400, height: 300)), isOpen: isOpen)
        return (ImagePipeline(client: client, options: options, diskCache: DiskImageCache(directory: directory)), client)
    }

    @Test func concurrentRequestsShareOneDownload() async throws {
        let (pipeline, client) = try makePipeline(isOpen: false, options: PipelineOptions(memoryCache: false))
        let tasks = (0..<5).map { _ in Task { try await pipeline.image(for: url, targetPixelSize: size) } }
        try await waitUntil { await pipeline.waiterCount(for: url, targetPixelSize: size) == 5 }

        await client.open()
        for task in tasks {
            _ = try await task.value
        }

        #expect(await client.requestCount == 1)
    }

    @Test func requestsWithoutDeduplicationDownloadSeparately() async throws {
        let (pipeline, client) = try makePipeline(options: PipelineOptions(deduplication: false, memoryCache: false))
        let tasks = (0..<5).map { _ in Task { try await pipeline.image(for: url, targetPixelSize: size) } }
        for task in tasks {
            _ = try await task.value
        }

        #expect(await client.requestCount == 5)
    }

    @Test func cancellingOneWaiterKeepsLoadForTheOther() async throws {
        let (pipeline, client) = try makePipeline(isOpen: false)
        let cancelled = Task { try await pipeline.image(for: url, targetPixelSize: size) }
        let kept = Task { try await pipeline.image(for: url, targetPixelSize: size) }
        try await waitUntil { await pipeline.waiterCount(for: url, targetPixelSize: size) == 2 }

        cancelled.cancel()
        await #expect(throws: CancellationError.self) { try await cancelled.value }

        await client.open()
        _ = try await kept.value
        #expect(await client.requestCount == 1)
        #expect(await client.cancelledCount == 0)
    }

    @Test func cancellingAllWaitersCancelsDownload() async throws {
        let (pipeline, client) = try makePipeline(isOpen: false)
        let tasks = (0..<2).map { _ in Task { try await pipeline.image(for: url, targetPixelSize: size) } }
        try await waitUntil { await pipeline.waiterCount(for: url, targetPixelSize: size) == 2 }

        tasks.forEach { $0.cancel() }
        for task in tasks {
            await #expect(throws: CancellationError.self) { try await task.value }
        }
        try await waitUntil { await client.cancelledCount == 1 }

        await client.open()
        _ = try await pipeline.image(for: url, targetPixelSize: size)
        #expect(await client.requestCount == 2)
    }

    @Test func memoryCacheHitSkipsNetwork() async throws {
        let (pipeline, client) = try makePipeline()
        let first = try await pipeline.image(for: url, targetPixelSize: size)
        let second = try await pipeline.image(for: url, targetPixelSize: size)

        #expect(first === second)
        #expect(await client.requestCount == 1)
    }

    @Test func cachedImageIsAvailableSynchronouslyAfterLoad() async throws {
        let (pipeline, _) = try makePipeline()
        #expect(pipeline.cachedImage(for: url, targetPixelSize: size) == nil)

        let loaded = try await pipeline.image(for: url, targetPixelSize: size)

        #expect(pipeline.cachedImage(for: url, targetPixelSize: size) === loaded)
        #expect(pipeline.cachedImage(for: url, targetPixelSize: PixelSize(width: 50, height: 50)) == nil)
    }

    @Test func disabledMemoryCacheRefetches() async throws {
        let (pipeline, client) = try makePipeline(options: PipelineOptions(memoryCache: false, diskCache: false))
        _ = try await pipeline.image(for: url, targetPixelSize: size)
        _ = try await pipeline.image(for: url, targetPixelSize: size)

        #expect(pipeline.cachedImage(for: url, targetPixelSize: size) == nil)
        #expect(await client.requestCount == 2)
    }

    @Test func memoryCacheMissFallsBackToDisk() async throws {
        let (first, _) = try makePipeline()
        _ = try await first.image(for: url, targetPixelSize: size)

        let (second, client) = try makePipeline()
        _ = try await second.image(for: url, targetPixelSize: size)

        #expect(await client.requestCount == 0)
    }

    @Test func disabledDiskCacheRefetches() async throws {
        let (first, _) = try makePipeline()
        _ = try await first.image(for: url, targetPixelSize: size)

        let (second, client) = try makePipeline(options: PipelineOptions(diskCache: false))
        _ = try await second.image(for: url, targetPixelSize: size)

        #expect(await client.requestCount == 1)
    }

    @Test func undecodableDataIsNotStoredOnDisk() async throws {
        let (pipeline, _) = try makePipeline(.success(Data("nope".utf8)))
        _ = try? await pipeline.image(for: url, targetPixelSize: size)

        let (second, client) = try makePipeline()
        _ = try await second.image(for: url, targetPixelSize: size)

        #expect(await client.requestCount == 1)
    }

    @Test func prefetchFillsMemoryCache() async throws {
        let (pipeline, _) = try makePipeline()
        await pipeline.prefetchImage(for: url, targetPixelSize: size)

        #expect(pipeline.cachedImage(for: url, targetPixelSize: size) != nil)
    }

    @Test func joiningAPrefetchRaisesItsPriority() async throws {
        guard #available(iOS 26, *) else { return }
        let (pipeline, client) = try makePipeline(isOpen: false)
        let prefetch = Task(priority: .utility) {
            await pipeline.prefetchImage(for: url, targetPixelSize: size)
        }
        try await waitUntil { await pipeline.waiterCount(for: url, targetPixelSize: size) == 1 }

        let load = Task(priority: .userInitiated) {
            try await pipeline.image(for: url, targetPixelSize: size)
        }
        try await waitUntil { await pipeline.waiterCount(for: url, targetPixelSize: size) == 2 }
        await client.open()
        _ = try await load.value
        await prefetch.value

        #expect(await client.priority == .userInitiated)
    }

    @Test func disabledPrefetchDoesNothing() async throws {
        let (pipeline, client) = try makePipeline(options: PipelineOptions(prefetch: false))
        await pipeline.prefetchImage(for: url, targetPixelSize: size)

        #expect(await client.requestCount == 0)
    }

    @Test func failedLoadIsNotCached() async throws {
        let (pipeline, client) = try makePipeline(.success(Data(), status: 500))

        for _ in 0..<2 {
            await #expect(throws: APIError.server(statusCode: 500)) {
                try await pipeline.image(for: url, targetPixelSize: size)
            }
        }
        #expect(await client.requestCount == 2)
    }

    @Test func undecodableDataThrowsDecoding() async throws {
        let (pipeline, _) = try makePipeline(.success(Data("nope".utf8)))

        await #expect(throws: APIError.decoding) {
            try await pipeline.image(for: url, targetPixelSize: size)
        }
    }

    @Test(arguments: [
        (PixelSize(width: 200, height: 150), 200, 150),
        (PixelSize(width: 40, height: 30), 40, 30),
        (PixelSize(width: 1000, height: 750), 400, 300)
    ])
    func decodedImageMatchesTargetPixelSize(target: PixelSize, width: Int, height: Int) async throws {
        let (pipeline, _) = try makePipeline()
        let cgImage = try #require(try await pipeline.image(for: url, targetPixelSize: target).cgImage)

        #expect(cgImage.width == width)
        #expect(cgImage.height == height)
    }

    @Test func disabledDownsamplingKeepsFullSize() async throws {
        let (pipeline, _) = try makePipeline(options: PipelineOptions(downsampling: false))
        let cgImage = try #require(try await pipeline.image(for: url, targetPixelSize: size).cgImage)

        #expect(cgImage.width == 400)
        #expect(cgImage.height == 300)
    }
}
