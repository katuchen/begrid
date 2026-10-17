import Foundation
import os
@testable import BeGrid

final class RecordingRepository: PhotoRepository {
    private let queries = OSAllocatedUnfairLock(initialState: [String]())
    private let makeSource: @Sendable (String) -> any PhotoSource

    init(makeSource: @escaping @Sendable (String) -> any PhotoSource = RecordingRepository.onePage) {
        self.makeSource = makeSource
    }

    private static func onePage(_ query: String) -> any PhotoSource {
        ScriptedSource(pages: [.of("a")])
    }

    var searchedQueries: [String] {
        queries.withLock { $0 }
    }

    func feedSource() -> any PhotoSource {
        ScriptedSource(pages: [])
    }

    func searchSource(query: String) -> any PhotoSource {
        queries.withLock { $0.append(query) }
        return makeSource(query)
    }
}
