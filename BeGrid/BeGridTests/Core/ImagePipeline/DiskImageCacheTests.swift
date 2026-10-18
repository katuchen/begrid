import Foundation
import Testing
@testable import BeGrid

struct DiskImageCacheTests {
    private let directory = TemporaryDirectory.make()
    private let clock = SteppingDate()

    private func makeCache(sizeLimit: Int = DiskImageCache.defaultSizeLimit) -> DiskImageCache {
        DiskImageCache(directory: directory, sizeLimit: sizeLimit, now: clock.next)
    }

    private func url(_ name: String) -> URL {
        URL(filePath: "/\(name).jpg")
    }

    private func bytes(_ count: Int) -> Data {
        Data(repeating: 1, count: count)
    }

    @Test func storedDataIsReadBack() async {
        let cache = makeCache()
        await cache.store(Data("photo".utf8), for: url("a"))

        #expect(await cache.data(for: url("a")) == Data("photo".utf8))
        #expect(await cache.data(for: url("b")) == nil)
    }

    @Test func storedDataSurvivesANewInstance() async {
        await makeCache().store(Data("photo".utf8), for: url("a"))

        #expect(await makeCache().data(for: url("a")) == Data("photo".utf8))
    }

    @Test func exceedingTheLimitEvictsLeastRecentlyUsed() async {
        let cache = makeCache(sizeLimit: 300)
        for name in ["a", "b", "c"] {
            await cache.store(bytes(100), for: url(name))
        }
        _ = await cache.data(for: url("a"))

        await cache.store(bytes(100), for: url("d"))

        #expect(await cache.data(for: url("a")) != nil)
        #expect(await cache.data(for: url("b")) == nil)
        #expect(await cache.data(for: url("c")) == nil)
        #expect(await cache.data(for: url("d")) != nil)
    }

    @Test func replacingAnEntryDoesNotCountItTwice() async {
        let cache = makeCache(sizeLimit: 300)
        for name in ["a", "b", "a", "a", "c"] {
            await cache.store(bytes(100), for: url(name))
        }

        for name in ["a", "b", "c"] {
            #expect(await cache.data(for: url(name)) != nil)
        }
    }

    @Test func dataLargerThanTheLimitIsNotStored() async {
        let cache = makeCache(sizeLimit: 100)
        await cache.store(bytes(101), for: url("a"))

        #expect(await cache.data(for: url("a")) == nil)
    }
}
