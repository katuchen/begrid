import Foundation

nonisolated struct FallbackSource: PhotoSource {
    private let id: String
    private let upstream: any PhotoSource
    private let store: PageStore

    init(id: String, upstream: any PhotoSource, store: PageStore) {
        self.id = id
        self.upstream = upstream
        self.store = store
    }

    func page(_ number: Int) async throws -> Page {
        do {
            let page = try await upstream.page(number)
            await store.save(page, number: number, of: id)
            return page
        } catch {
            guard !(error is CancellationError), !Task.isCancelled,
                  var saved = await store.page(number, of: id) else { throw error }
            saved.staleReason = error as? APIError ?? .server(statusCode: nil)
            return saved
        }
    }
}
