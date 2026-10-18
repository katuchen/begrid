import Foundation

actor DiskImageCache {
    private struct Entry {
        let file: URL
        let size: Int
        let lastAccess: Date
    }

    nonisolated static let defaultSizeLimit = 200 * 1024 * 1024
    nonisolated static let trimRatio = 0.75

    private let directory: URL
    private let sizeLimit: Int
    private let now: @Sendable () -> Date
    private var totalSize: Int?

    init(
        directory: URL = URL.cachesDirectory.appending(path: "Images", directoryHint: .isDirectory),
        sizeLimit: Int = DiskImageCache.defaultSizeLimit,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.directory = directory
        self.sizeLimit = sizeLimit
        self.now = now
    }

    func data(for url: URL) -> Data? {
        let file = fileURL(for: url)
        guard let data = try? Data(contentsOf: file) else { return nil }
        touch(file)
        return data
    }

    func store(_ data: Data, for url: URL) {
        guard data.count <= sizeLimit else { return }
        let file = fileURL(for: url)
        var total = currentTotalSize() - (size(of: file) ?? 0)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: file, options: .atomic)
        } catch {
            totalSize = nil
            return
        }
        touch(file)
        total += data.count
        totalSize = total > sizeLimit ? evict(downTo: Int(Double(sizeLimit) * Self.trimRatio)) : total
    }

    private func evict(downTo target: Int) -> Int {
        let entries = entries().sorted { $0.lastAccess < $1.lastAccess }
        var total = entries.reduce(0) { $0 + $1.size }
        for entry in entries where total > target {
            if (try? FileManager.default.removeItem(at: entry.file)) != nil {
                total -= entry.size
            }
        }
        return total
    }

    private func currentTotalSize() -> Int {
        if let totalSize { return totalSize }
        let total = entries().reduce(0) { $0 + $1.size }
        totalSize = total
        return total
    }

    private func entries() -> [Entry] {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: Array(keys))) ?? []
        return files.compactMap { file in
            guard let values = try? file.resourceValues(forKeys: keys),
                  let size = values.fileSize,
                  let lastAccess = values.contentModificationDate else { return nil }
            return Entry(file: file, size: size, lastAccess: lastAccess)
        }
    }

    private func size(of file: URL) -> Int? {
        try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize
    }

    private func touch(_ file: URL) {
        try? FileManager.default.setAttributes([.modificationDate: now()], ofItemAtPath: file.path(percentEncoded: false))
    }

    private func fileURL(for url: URL) -> URL {
        directory.appending(path: url.absoluteString.sha256, directoryHint: .notDirectory)
    }
}
