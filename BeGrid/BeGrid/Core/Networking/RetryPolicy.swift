import Foundation

nonisolated struct RetryPolicy: Sendable {
    var maxAttempts = 3
    var baseDelay: Duration = .milliseconds(500)
    var clock: any Clock<Duration> = ContinuousClock()

    func run<T>(_ operation: () async throws -> T) async throws -> T {
        var attempt = 1
        while true {
            do {
                return try await operation()
            } catch let error as APIError where error.isTransient && attempt < maxAttempts {
                try await clock.sleep(for: baseDelay * (1 << (attempt - 1)))
                attempt += 1
            }
        }
    }
}
