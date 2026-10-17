import SwiftUI

@main
struct BeGridApp: App {
    private let environment = Result { () throws(ConfigurationError) in try AppEnvironment.live() }

    var body: some Scene {
        WindowGroup {
            switch environment {
            case .success(let environment):
                RootView(repository: environment.repository)
                    .environment(\.imageLoader, environment.imageLoader)
            case .failure(let error):
                ConfigurationErrorView(error: error)
            }
        }
    }
}
