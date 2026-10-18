import Foundation
import Testing
@testable import BeGrid

@MainActor
struct PhotoGridViewModelTests {
    private struct Failure: Error {}

    private func ids(_ model: PhotoGridViewModel) -> [String] {
        model.items.map(\.id)
    }

    @Test func pagesAreAppendedInOrder() async {
        let source = ScriptedSource(pages: [.of("a", "b"), .of("c", "d")])
        let model = PhotoGridViewModel(source: source)

        await model.loadNextPage()
        #expect(model.state == .loaded)
        await model.loadNextPage()

        #expect(ids(model) == ["a", "b", "c", "d"])
        #expect(await source.requestedPages == [1, 2])
    }

    @Test func loadingTheFirstPageAgainDoesNothing() async {
        let source = ScriptedSource(pages: [.of("a"), .of("b")])
        let model = PhotoGridViewModel(source: source)

        await model.loadFirstPage()
        await model.loadFirstPage()

        #expect(ids(model) == ["a"])
        #expect(await source.requestedPages == [1])
    }

    @Test func duplicatesAcrossPagesAreRemoved() async {
        let model = PhotoGridViewModel(source: ScriptedSource(pages: [.of("a", "b", "c"), .of("c", "a", "d")]))

        await model.loadNextPage()
        await model.loadNextPage()

        #expect(ids(model) == ["a", "b", "c", "d"])
    }

    @Test func secondLoadDuringALoadDoesNotStartAnother() async throws {
        let source = ScriptedSource(pages: [.of("a"), .of("b")])
        let model = PhotoGridViewModel(source: source)
        await model.loadNextPage()

        await source.close()
        model.onItemAppear("a")
        model.onItemAppear("a")
        await model.loadNextPage()
        #expect(model.state == .loadingMore)

        await source.open()
        try await waitUntil { model.state == .loaded }
        #expect(await source.requestedPages == [1, 2])
        #expect(ids(model) == ["a", "b"])
    }

    @Test(arguments: [(0, false), (9, false), (10, true), (19, true)])
    func itemNearTheEndLoadsTheNextPage(index: Int, loads: Bool) async throws {
        let firstPage = Page(photos: (0..<20).map { Photo.stub(id: "\($0)") }, hasMore: true)
        let source = ScriptedSource(pages: [firstPage, .of("next")])
        let model = PhotoGridViewModel(source: source)
        await model.loadNextPage()

        model.onItemAppear("\(index)")

        #expect(model.state == (loads ? .loadingMore : .loaded))
        try await waitUntil { model.state == .loaded }
        #expect(await source.requestedPages.count == (loads ? 2 : 1))
    }

    @Test func lastPageExhaustsTheFeed() async {
        let source = ScriptedSource(pages: [.of("a"), .of("b", hasMore: false)])
        let model = PhotoGridViewModel(source: source)

        await model.loadNextPage()
        await model.loadNextPage()
        #expect(model.state == .exhausted)

        await model.loadNextPage()
        model.onItemAppear("b")

        #expect(await source.requestedPages == [1, 2])
        #expect(model.state == .exhausted)
    }

    @Test func failedFirstLoadRecoversOnRetry() async {
        let source = ScriptedSource([1: [.failure(APIError.offline), .success(.of("a"))]])
        let model = PhotoGridViewModel(source: source)

        await model.loadNextPage()
        #expect(model.state == .failed(.offline))
        #expect(model.items.isEmpty)

        await model.retry()

        #expect(model.state == .loaded)
        #expect(ids(model) == ["a"])
        #expect(await source.requestedPages == [1, 1])
    }

    @Test func failedLaterPageKeepsItemsAndRetriesThatPage() async {
        let source = ScriptedSource([1: [.success(.of("a"))], 2: [.failure(APIError.rateLimited), .success(.of("b"))]])
        let model = PhotoGridViewModel(source: source)

        await model.loadNextPage()
        await model.loadNextPage()
        #expect(model.state == .failed(.rateLimited))
        #expect(ids(model) == ["a"])

        model.onItemAppear("a")
        await model.loadNextPage()
        #expect(await source.requestedPages == [1, 2])

        await model.retry()

        #expect(ids(model) == ["a", "b"])
        #expect(await source.requestedPages == [1, 2, 2])
    }

    @Test func savedPhotosRaiseAnAlertAndRecoveringReplacesThem() async {
        let saved = Page(photos: [.stub(id: "old")], hasMore: true, staleReason: .rateLimited)
        let source = ScriptedSource([1: [.success(saved), .success(.of("new"))]])
        let model = PhotoGridViewModel(source: source)

        await model.loadNextPage()
        #expect(model.needsRefresh)
        #expect(model.alert == .rateLimited)

        await model.recover()

        #expect(!model.needsRefresh)
        #expect(model.alert == nil)
        #expect(ids(model) == ["new"])
        #expect(await source.requestedPages == [1, 1])
    }

    @Test func recoveringRetriesAFailedLoad() async {
        let source = ScriptedSource([1: [.success(.of("a"))], 2: [.failure(APIError.offline), .success(.of("b"))]])
        let model = PhotoGridViewModel(source: source)
        await model.loadNextPage()
        await model.loadNextPage()
        #expect(model.alert == nil)

        await model.recover()

        #expect(ids(model) == ["a", "b"])
        #expect(await source.requestedPages == [1, 2, 2])
    }

    @Test func recoveringAFreshGridDoesNothing() async {
        let source = ScriptedSource(pages: [.of("a"), .of("b")])
        let model = PhotoGridViewModel(source: source)
        await model.loadNextPage()

        await model.recover()

        #expect(await source.requestedPages == [1])
    }

    @Test func failedRefreshKeepsItemsRaisesAnAlertAndRecoveringRefreshesAgain() async {
        let source = ScriptedSource([1: [.success(.of("a")), .failure(APIError.server(statusCode: 500)), .success(.of("new"))]])
        let model = PhotoGridViewModel(source: source)
        await model.loadNextPage()

        await model.refresh()
        #expect(model.alert == .server(statusCode: 500))
        #expect(ids(model) == ["a"])

        await model.recover()

        #expect(model.alert == nil)
        #expect(ids(model) == ["new"])
        #expect(await source.requestedPages == [1, 1, 1])
    }

    @Test func failedFirstLoadDoesNotRaiseAnAlert() async {
        let model = PhotoGridViewModel(source: ScriptedSource([1: [.failure(APIError.server(statusCode: 500))]]))

        await model.refresh()

        #expect(model.alert == nil)
        #expect(model.state == .failed(.server(statusCode: 500)))
    }

    @Test func alertIsHiddenWhileOfflineAndClearedOnReconnect() async {
        let saved = Page(photos: [.stub(id: "old")], hasMore: true, staleReason: .offline)
        let source = ScriptedSource([1: [.success(saved), .success(.of("new"))]])
        let model = PhotoGridViewModel(source: source)
        await model.connectivityChanged(isOnline: false)

        await model.loadNextPage()
        #expect(model.alert == nil)

        await model.connectivityChanged(isOnline: true)

        #expect(model.alert == nil)
        #expect(ids(model) == ["new"])
    }

    @Test func dismissingClearsTheAlert() async {
        let saved = Page(photos: [.stub(id: "old")], hasMore: true, staleReason: .offline)
        let model = PhotoGridViewModel(source: ScriptedSource([1: [.success(saved)]]))
        await model.loadNextPage()

        model.dismissAlert()

        #expect(model.alert == nil)
        #expect(model.needsRefresh)
    }

    @Test func unknownErrorIsReportedAsServerError() async {
        let model = PhotoGridViewModel(source: ScriptedSource([1: [.failure(Failure())]]))

        await model.loadNextPage()

        #expect(model.state == .failed(.server(statusCode: nil)))
    }

    @Test func refreshReplacesItemsAndRestartsPaging() async {
        let source = ScriptedSource([1: [.success(.of("a")), .success(.of("z"))], 2: [.success(.of("b"))]])
        let model = PhotoGridViewModel(source: source)
        await model.loadNextPage()
        await model.loadNextPage()

        await model.refresh()
        #expect(ids(model) == ["z"])
        #expect(model.state == .loaded)

        await model.loadNextPage()
        #expect(ids(model) == ["z", "b"])
        #expect(await source.requestedPages == [1, 2, 1, 2])
    }

    @Test func refreshDiscardsTheLoadInFlight() async throws {
        let source = ScriptedSource([1: [.success(.of("a")), .success(.of("z"))], 2: [.success(.of("b"))]])
        let model = PhotoGridViewModel(source: source)
        await model.loadNextPage()

        await source.close()
        model.onItemAppear("a")
        try await waitUntil { await source.requestedPages.count == 2 }
        async let refreshed: Void = model.refresh()
        try await waitUntil { await source.requestedPages.count == 3 }
        await source.open()
        await refreshed

        #expect(ids(model) == ["z"])
        #expect(model.state == .loaded)
        await model.loadNextPage()
        #expect(ids(model) == ["z", "b"])
    }
}
