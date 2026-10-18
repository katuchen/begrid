import Foundation
import Observation

@Observable
final class SearchViewModel {
    struct Results {
        let query: String
        let grid: PhotoGridViewModel
    }

    static let debounce: Duration = .milliseconds(500)
    static let recentLimit = 10
    static let suggestions = ["Nature", "Architecture", "Travel", "Street", "Animals", "Food"]
    private static let minimumQueryLength = 2
    private static let recentsKey = "search.recentQueries"

    var query = "" {
        didSet { queryChanged() }
    }

    private(set) var results: Results? {
        willSet { results?.grid.cancel() }
    }
    private(set) var recentQueries: [String]

    @ObservationIgnored private let repository: any PhotoRepository
    @ObservationIgnored private let clock: any Clock<Duration>
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var pendingSearch: Task<Void, Never>?

    init(repository: any PhotoRepository, clock: any Clock<Duration> = ContinuousClock(), defaults: UserDefaults = .standard) {
        self.repository = repository
        self.clock = clock
        self.defaults = defaults
        recentQueries = defaults.stringArray(forKey: Self.recentsKey) ?? []
    }

    var isStale: Bool {
        results.map { $0.query != normalizedQuery } ?? false
    }

    func submit() {
        pendingSearch?.cancel()
        guard let query = searchableQuery else { return }
        remember(query)
        search(query)
    }

    func select(_ suggestion: String) {
        query = suggestion
        submit()
    }

    func clearRecents() {
        recentQueries = []
        defaults.removeObject(forKey: Self.recentsKey)
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchableQuery: String? {
        let query = normalizedQuery
        return query.count >= Self.minimumQueryLength ? query : nil
    }

    private func queryChanged() {
        pendingSearch?.cancel()
        if normalizedQuery.isEmpty {
            results = nil
            return
        }
        guard let query = searchableQuery, query != results?.query else { return }
        pendingSearch = Task { [clock] in
            try? await clock.sleep(for: Self.debounce)
            guard !Task.isCancelled else { return }
            search(query)
        }
    }

    private func search(_ query: String) {
        if let results, results.query == query {
            if case .failed = results.grid.state {
                Task { await results.grid.recover() }
            }
            return
        }
        results = Results(query: query, grid: PhotoGridViewModel(source: repository.searchSource(query: query)))
    }

    private func remember(_ query: String) {
        var recents = recentQueries.filter { $0.caseInsensitiveCompare(query) != .orderedSame }
        recents.insert(query, at: 0)
        recentQueries = Array(recents.prefix(Self.recentLimit))
        defaults.set(recentQueries, forKey: Self.recentsKey)
        Task { [repository] in
            await repository.keepOffline(query: query)
        }
    }
}
