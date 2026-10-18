import Foundation
import os

final class SteppingDate: Sendable {
    private let seconds = OSAllocatedUnfairLock(initialState: 0.0)

    func next() -> Date {
        seconds.withLock {
            $0 += 1
            return Date(timeIntervalSinceReferenceDate: $0)
        }
    }
}
