import Network
import Observation
import SwiftUI

@Observable
final class ConnectivityMonitor {
    private(set) var isOnline = true

    func monitor() async {
        for await path in NWPathMonitor() {
            let isOnline = path.status == .satisfied
            if isOnline != self.isOnline {
                self.isOnline = isOnline
            }
        }
    }
}

extension EnvironmentValues {
    @Entry var isOnline = true
}
