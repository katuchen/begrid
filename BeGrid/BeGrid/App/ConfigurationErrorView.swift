import SwiftUI

struct ConfigurationErrorView: View {
    let error: ConfigurationError

    var body: some View {
        ContentUnavailableView {
            Label("Missing Unsplash key", systemImage: "key.slash")
        } description: {
            Text(message)
        }
    }

    private var message: String {
        switch error {
        case .missingAccessKey:
            "Copy BeGrid/Config/Secrets.example.xcconfig to BeGrid/Config/Secrets.xcconfig, add your Unsplash Access Key, and rebuild."
        }
    }
}

#Preview {
    ConfigurationErrorView(error: .missingAccessKey)
}
