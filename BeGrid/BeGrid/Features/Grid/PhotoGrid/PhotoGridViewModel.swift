import Foundation
import Observation

@Observable
final class PhotoGridViewModel {
    enum State: Equatable {
        case idle
        case loadingFirst
        case loaded
        case loadingMore
        case failed(APIError)
        case exhausted
    }

    static let prefetchDistance = 10

    private(set) var items: [Photo] = []
    private(set) var state: State = .idle
    private var failure: APIError?
    private var isOnline = true

    @ObservationIgnored private(set) var needsRefresh = false
    @ObservationIgnored private let source: any PhotoSource
    @ObservationIgnored private var seenIDs: Set<Photo.ID> = []
    @ObservationIgnored private var nextPage = 1
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    init(source: any PhotoSource) {
        self.source = source
    }

    var alert: APIError? {
        isOnline ? failure : nil
    }

    func loadFirstPage() async {
        guard state == .idle else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        await startNextPage()?.value
    }

    func onItemAppear(_ id: Photo.ID) {
        guard items.suffix(Self.prefetchDistance).contains(where: { $0.id == id }) else { return }
        startNextPage()
    }

    func retry() async {
        guard case .failed = state else { return }
        state = items.isEmpty ? .idle : .loaded
        await loadNextPage()
    }

    func connectivityChanged(isOnline: Bool) async {
        self.isOnline = isOnline
        failure = nil
        if isOnline {
            await recover()
        }
    }

    func recover() async {
        failure = nil
        if needsRefresh {
            await refresh()
        } else {
            await retry()
        }
    }

    func refresh() async {
        loadTask?.cancel()
        state = .loadingFirst
        await start(page: 1, replacing: true).value
    }

    func dismissAlert() {
        failure = nil
    }

    func cancel() {
        loadTask?.cancel()
    }

    @discardableResult
    private func startNextPage() -> Task<Void, Never>? {
        guard state == .idle || state == .loaded else { return nil }
        state = items.isEmpty ? .loadingFirst : .loadingMore
        return start(page: nextPage, replacing: false)
    }

    private func start(page: Int, replacing: Bool) -> Task<Void, Never> {
        let task = Task { await load(page: page, replacing: replacing) }
        loadTask = task
        return task
    }

    private func load(page number: Int, replacing: Bool) async {
        do {
            let page = try await source.page(number)
            guard !Task.isCancelled else { return }

            if replacing {
                seenIDs.removeAll()
            }
            let fresh = page.photos.filter { seenIDs.insert($0.id).inserted }
            if replacing {
                items = fresh
            } else {
                items.append(contentsOf: fresh)
            }
            if replacing {
                needsRefresh = false
            }
            if let reason = page.staleReason {
                markStale(reason)
            }
            nextPage = number + 1
            state = page.hasMore ? .loaded : .exhausted
        } catch {
            guard !Task.isCancelled else { return }
            let error = APIError.from(error)
            if replacing && !items.isEmpty {
                markStale(error)
            }
            state = .failed(error)
        }
    }

    private func markStale(_ error: APIError) {
        needsRefresh = true
        failure = error
    }
}
