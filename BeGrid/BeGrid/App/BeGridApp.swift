import SwiftUI

@main
struct BeGridApp: App {
    private let environment = Result { () throws(ConfigurationError) in try AppEnvironment.live() }
    @State private var connectivity = ConnectivityMonitor()

    var body: some Scene {
        WindowGroup {
            switch environment {
            case .success(let environment):
                RootView(repository: environment.repository)
                    .environment(\.imageLoader, environment.imageLoader)
                    .environment(\.isOnline, connectivity.isOnline)
                    .task {
                        await connectivity.monitor()
                    }
            case .failure(let error):
                ConfigurationErrorView(error: error)
            }
        }
    }
}
