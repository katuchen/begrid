import Foundation

nonisolated extension Photo {
    var accessibilityLabel: String {
        summary ?? "Photo by \(photographer.name)"
    }
}
