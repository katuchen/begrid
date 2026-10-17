import Foundation

actor PageCache {
    private struct Entry {
        let storedAt: Date
        var pages: [Int: Page] = [:]
    }

    private let sourceLimit: Int
    private let lifetime: TimeInterval
    private let now: @Sendable () -> Date
    private var entries: [String: Entry] = [:]
    private var recentSources: [String] = []

    init(sourceLimit: Int = 10, lifetime: TimeInterval = 5 * 60, now: @escaping @Sendable () -> Date = Date.init) {
        self.sourceLimit = sourceLimit
        self.lifetime = lifetime
        self.now = now
    }

    func page(_ number: Int, of source: String) -> Page? {
        guard let entry = liveEntry(for: source), let page = entry.pages[number] else { return nil }
        markRecent(source)
        return page
    }

    func insert(_ page: Page, number: Int, of source: String) {
        var entry = liveEntry(for: source) ?? Entry(storedAt: now())
        entry.pages[number] = page
        entries[source] = entry
        markRecent(source)
        if recentSources.count > sourceLimit {
            entries.removeValue(forKey: recentSources.removeFirst())
        }
    }

    private func liveEntry(for source: String) -> Entry? {
        guard let entry = entries[source] else { return nil }
        guard now().timeIntervalSince(entry.storedAt) < lifetime else {
            entries.removeValue(forKey: source)
            recentSources.removeAll { $0 == source }
            return nil
        }
        return entry
    }

    private func markRecent(_ source: String) {
        guard recentSources.last != source else { return }
        recentSources.removeAll { $0 == source }
        recentSources.append(source)
    }
}
