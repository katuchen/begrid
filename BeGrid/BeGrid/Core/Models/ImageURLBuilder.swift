import Foundation

nonisolated enum ImageURLBuilder {
    private static let managedParameters: Set<String> = ["w", "dpr", "q", "fm"]

    static func url(from base: URL, pixelWidth: Int) -> URL {
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return base }

        let kept = (components.percentEncodedQueryItems ?? []).filter { !managedParameters.contains($0.name) }
        components.percentEncodedQueryItems = kept + [
            URLQueryItem(name: "w", value: String(max(pixelWidth, 1))),
            URLQueryItem(name: "dpr", value: "1"),
            URLQueryItem(name: "q", value: "80"),
            URLQueryItem(name: "fm", value: "jpg")
        ]
        return components.url ?? base
    }
}
