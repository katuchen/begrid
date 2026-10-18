import Foundation

actor PageStore {
    private struct Snapshot: Codable {
        let photos: [Photo]
        let hasMore: Bool
    }

    private let directory: URL
    private let pageLimit: Int
    private let sourceLimit: Int
    private let requiresPin: Bool
    private let now: @Sendable () -> Date
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var pinned: Set<String> = []
    private var pending: (source: String, pages: [Int: Page])?
    private var written: [String: [Int: Page]] = [:]

    init(
        directory: URL,
        pageLimit: Int = 3,
        sourceLimit: Int = 5,
        requiresPin: Bool = false,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.directory = directory
        self.pageLimit = pageLimit
        self.sourceLimit = sourceLimit
        self.requiresPin = requiresPin
        self.now = now
    }

    func pin(_ source: String) {
        pinned.insert(source)
        guard let pending, pending.source == source else { return }
        self.pending = nil
        for (number, page) in pending.pages {
            write(page, number: number, of: source)
        }
    }

    func page(_ number: Int, of source: String) -> Page? {
        guard let data = try? Data(contentsOf: fileURL(for: number, in: folderURL(for: source))),
              let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return nil }
        return Page(photos: snapshot.photos, hasMore: snapshot.hasMore)
    }

    func save(_ page: Page, number: Int, of source: String) {
        guard number <= pageLimit else { return }
        guard !requiresPin || pinned.contains(source) else {
            var pages = pending?.source == source ? pending?.pages ?? [:] : [:]
            pages[number] = page
            pending = (source, pages)
            return
        }
        write(page, number: number, of: source)
    }

    private func write(_ page: Page, number: Int, of source: String) {
        let folder = folderURL(for: source)
        guard written[folder.lastPathComponent]?[number] != page else {
            touch(folder)
            return
        }
        guard let data = try? encoder.encode(Snapshot(photos: page.photos, hasMore: page.hasMore)) else { return }
        let isNewSource = !FileManager.default.fileExists(atPath: folder.path(percentEncoded: false))
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: number, in: folder), options: .atomic)
        } catch {
            return
        }
        touch(folder)
        written[folder.lastPathComponent, default: [:]][number] = page
        if isNewSource {
            evictOldSources()
        }
    }

    private func evictOldSources() {
        let key = URLResourceKey.contentModificationDateKey
        let folders = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [key])) ?? []
        let dated = folders.map { ($0, (try? $0.resourceValues(forKeys: [key]).contentModificationDate) ?? .distantPast) }
        for (folder, _) in dated.sorted(by: { $0.1 > $1.1 }).dropFirst(sourceLimit) {
            try? FileManager.default.removeItem(at: folder)
            written[folder.lastPathComponent] = nil
        }
    }

    private func touch(_ folder: URL) {
        try? FileManager.default.setAttributes([.modificationDate: now()], ofItemAtPath: folder.path(percentEncoded: false))
    }

    private func folderURL(for source: String) -> URL {
        directory.appending(path: source.sha256, directoryHint: .isDirectory)
    }

    private func fileURL(for number: Int, in folder: URL) -> URL {
        folder.appending(path: "\(number).json", directoryHint: .notDirectory)
    }
}
