import Foundation

actor PageStore {
    private struct Snapshot: Codable {
        let photos: [Photo]
        let hasMore: Bool
    }

    private let directory: URL
    private let pageLimit: Int
    private let sourceLimit: Int
    private let now: @Sendable () -> Date
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(directory: URL, pageLimit: Int = 3, sourceLimit: Int = 5, now: @escaping @Sendable () -> Date = { .now }) {
        self.directory = directory
        self.pageLimit = pageLimit
        self.sourceLimit = sourceLimit
        self.now = now
    }

    func page(_ number: Int, of source: String) -> Page? {
        guard let data = try? Data(contentsOf: fileURL(for: number, in: folderURL(for: source))),
              let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return nil }
        return Page(photos: snapshot.photos, hasMore: snapshot.hasMore)
    }

    func save(_ page: Page, number: Int, of source: String) {
        guard number <= pageLimit,
              let data = try? encoder.encode(Snapshot(photos: page.photos, hasMore: page.hasMore)) else { return }
        let folder = folderURL(for: source)
        let isNewSource = !FileManager.default.fileExists(atPath: folder.path(percentEncoded: false))
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: number, in: folder), options: .atomic)
            try FileManager.default.setAttributes([.modificationDate: now()], ofItemAtPath: folder.path(percentEncoded: false))
        } catch {
            return
        }
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
        }
    }

    private func folderURL(for source: String) -> URL {
        directory.appending(path: source.sha256, directoryHint: .isDirectory)
    }

    private func fileURL(for number: Int, in folder: URL) -> URL {
        folder.appending(path: "\(number).json", directoryHint: .notDirectory)
    }
}
