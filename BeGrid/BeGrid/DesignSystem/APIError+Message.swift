import Foundation

extension APIError {
    var message: String {
        switch self {
        case .offline: "You're offline. Check your connection and try again."
        case .rateLimited: "Unsplash's hourly request limit was reached. Try again later."
        case .unauthorized: "Unsplash rejected the access key."
        case .server: "Unsplash is having trouble right now. Try again."
        case .decoding: "Unsplash sent a response the app couldn't read."
        }
    }
}
