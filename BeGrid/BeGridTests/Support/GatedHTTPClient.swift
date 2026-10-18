import Foundation
@testable import BeGrid

actor GatedHTTPClient: HTTPClient {
    private let response: StubHTTPClient.Response
    private var isOpen: Bool
    private(set) var requestCount = 0
    private(set) var cancelledCount = 0
    private(set) var priority: TaskPriority?

    init(_ response: StubHTTPClient.Response, isOpen: Bool = true) {
        self.response = response
        self.isOpen = isOpen
    }

    func open() {
        isOpen = true
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requestCount += 1
        do {
            while !isOpen {
                try await Task.sleep(for: .milliseconds(5))
            }
        } catch {
            cancelledCount += 1
            throw error
        }
        priority = Task.currentPriority
        return try response.result(for: request)
    }
}
