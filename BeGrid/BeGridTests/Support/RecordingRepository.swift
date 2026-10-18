import Foundation
import os
@testable import BeGrid

final class RecordingRepository: PhotoRepository {
    private let queries = OSAllocatedUnfairLock(initialState: [String]())
    private let offlineQueries = OSAllocatedUnfairLock(initialState: [String]())
    private let makeSource: @Sendable (String) -> any PhotoSource

    init(makeSource: @escaping @Sendable (String) -> any PhotoSource = RecordingRepository.onePage) {
        self.makeSource = makeSource
    }

    private static func onePage(_ query: String) -> any PhotoSource {
        CountingSource(.success(.of("a", hasMore: false)))
    }

    var searchedQueries: [String] {
        queries.withLock { $0 }
    }

    var keptOfflineQueries: [String] {
        offlineQueries.withLock { $0 }
    }

    func feedSource() -> any PhotoSource {
        CountingSource()
    }

    func searchSource(query: String) -> any PhotoSource {
        queries.withLock { $0.append(query) }
        return makeSource(query)
    }

    func keepOffline(query: String) async {
        offlineQueries.withLock { $0.append(query) }
    }
}
