import Foundation
import Testing
@testable import BeGrid

@MainActor
struct SearchViewModelTests {
    private let clock = ManualClock()
    private let repository = RecordingRepository()
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard

    private func makeModel() -> SearchViewModel {
        SearchViewModel(repository: repository, clock: clock, defaults: defaults)
    }

    @Test func burstOfKeystrokesMakesOneSearch() async throws {
        let model = makeModel()

        for prefix in ["ca", "cat", "cats"] {
            model.query = prefix
        }
        try await waitUntil { clock.sleeperCount == 1 }
        #expect(model.results == nil)

        clock.advance(by: SearchViewModel.debounce)

        try await waitUntil { model.results != nil }
        #expect(repository.searchedQueries == ["cats"])
        #expect(model.results?.query == "cats")
    }

    @Test func searchWaitsForTheDebounce() async throws {
        let model = makeModel()

        model.query = "cats"
        try await waitUntil { clock.sleeperCount == 1 }
        clock.advance(by: .milliseconds(499))
        #expect(clock.sleeperCount == 1)
        #expect(repository.searchedQueries.isEmpty)

        clock.advance(by: .milliseconds(1))
        try await waitUntil { model.results != nil }
        #expect(repository.searchedQueries == ["cats"])
    }

    @Test func newKeystrokeCancelsThePendingSearch() async throws {
        let model = makeModel()

        model.query = "cats"
        try await waitUntil { clock.sleeperCount == 1 }
        clock.advance(by: .milliseconds(300))
        model.query = "dogs"
        try await waitUntil { clock.sleeperCount == 1 }
        clock.advance(by: .milliseconds(300))
        #expect(repository.searchedQueries.isEmpty)

        clock.advance(by: .milliseconds(200))
        try await waitUntil { model.results != nil }
        #expect(repository.searchedQueries == ["dogs"])
    }

    @Test func submitSearchesImmediately() {
        let model = makeModel()

        model.query = "cats"
        model.submit()

        #expect(model.results != nil)
        #expect(repository.searchedQueries == ["cats"])
    }

    @Test(arguments: ["", "c", " c "])
    func shortQueryIsIgnored(query: String) {
        let model = makeModel()

        model.query = query
        model.submit()

        #expect(clock.sleeperCount == 0)
        #expect(model.results == nil)
        #expect(repository.searchedQueries.isEmpty)
    }

    @Test func newQueryCreatesANewGrid() throws {
        let model = makeModel()

        model.select("cats")
        let first = try #require(model.results?.grid)
        model.select("dogs")
        let second = try #require(model.results?.grid)

        #expect(first !== second)
        #expect(repository.searchedQueries == ["cats", "dogs"])
    }

    @Test func sameQueryKeepsTheGrid() throws {
        let model = makeModel()

        model.select("cats")
        let first = try #require(model.results?.grid)
        model.query = " cats "
        model.submit()

        #expect(model.results?.grid === first)
        #expect(clock.sleeperCount == 0)
        #expect(repository.searchedQueries == ["cats"])
    }

    @Test func resubmittingAFailedQueryRetriesIt() async throws {
        let source = ScriptedSource([1: [.failure(APIError.offline), .success(.of("a"))]])
        let model = SearchViewModel(repository: RecordingRepository { _ in source }, clock: clock, defaults: defaults)
        model.select("cats")
        let grid = try #require(model.results?.grid)
        await grid.loadNextPage()
        #expect(grid.state == .failed(.offline))

        model.submit()

        try await waitUntil { grid.state == .loaded }
        #expect(model.results?.grid === grid)
        #expect(await source.requestedPages == [1, 1])
    }

    @Test func replacingResultsCancelsThePreviousLoad() async throws {
        let source = ScriptedSource(pages: [.of("a")], isOpen: false)
        let repository = RecordingRepository { query in query == "cats" ? source : ScriptedSource(pages: [.of("b")]) }
        let model = SearchViewModel(repository: repository, clock: clock, defaults: defaults)
        model.select("cats")
        let cats = try #require(model.results?.grid)
        Task { await cats.loadNextPage() }
        try await waitUntil { await source.requestedPages == [1] }

        model.select("dogs")
        await source.open()
        try await Task.sleep(for: .milliseconds(50))

        #expect(cats.items.isEmpty)
    }

    @Test func clearingTheQueryDropsResults() {
        let model = makeModel()
        model.select("cats")

        model.query = ""

        #expect(model.results == nil)
            }

    @Test func editingMarksResultsStale() {
        let model = makeModel()
        model.select("cats")
        #expect(!model.isStale)

        model.query = "cat"

        #expect(model.isStale)
        #expect(model.results?.query == "cats")
    }

    @Test func submittedQueriesAreRememberedMostRecentFirst() {
        let model = makeModel()

        model.select("cats")
        model.select("dogs")
        model.select("Cats")

        #expect(model.recentQueries == ["Cats", "dogs"])
        #expect(makeModel().recentQueries == ["Cats", "dogs"])
    }

    @Test func clearingRecentsForgetsThem() {
        let model = makeModel()
        model.select("cats")

        model.clearRecents()

        #expect(model.recentQueries.isEmpty)
        #expect(makeModel().recentQueries.isEmpty)
    }

    @Test func recentQueriesAreCapped() {
        let model = makeModel()

        for index in 0..<(SearchViewModel.recentLimit + 3) {
            model.select("query \(index)")
        }

        #expect(model.recentQueries.count == SearchViewModel.recentLimit)
        #expect(model.recentQueries.first == "query \(SearchViewModel.recentLimit + 2)")
    }
}
