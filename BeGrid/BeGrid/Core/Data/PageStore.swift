import CryptoKit
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

    init(directory: URL, pageLimit: Int = 3, sourceLimit: Int = 5, now: @escaping @Sendable () -> Date = { .now }) {
        self.directory = directory
        self.pageLimit = pageLimit
        self.sourceLimit = sourceLimit
        self.now = now
    }

    func page(_ number: Int, of source: String) -> Page? {
        guard let data = try? Data(contentsOf: fileURL(for: number, of: source)),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return nil }
        return Page(photos: snapshot.photos, hasMore: snapshot.hasMore)
    }

    func save(_ page: Page, number: Int, of source: String) {
        guard number <= pageLimit,
              let data = try? JSONEncoder().encode(Snapshot(photos: page.photos, hasMore: page.hasMore)) else { return }
        let folder = folderURL(for: source)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: number, of: source), options: .atomic)
            try FileManager.default.setAttributes([.modificationDate: now()], ofItemAtPath: folder.path(percentEncoded: false))
        } catch {
            return
        }
        evictOldSources()
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
        let digest = SHA256.hash(data: Data(source.utf8))
        return directory.appending(path: digest.map { String(format: "%02x", $0) }.joined(), directoryHint: .isDirectory)
    }

    private func fileURL(for number: Int, of source: String) -> URL {
        folderURL(for: source).appending(path: "\(number).json", directoryHint: .notDirectory)
    }
}
