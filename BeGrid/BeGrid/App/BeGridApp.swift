import SwiftUI

@main
struct BeGridApp: App {
    private let configuration = Result { () throws(ConfigurationError) in try AppConfiguration.load() }

    var body: some Scene {
        WindowGroup {
            switch configuration {
            case .success:
                ContentView()
            case .failure(let error):
                ConfigurationErrorView(error: error)
            }
        }
    }
}
