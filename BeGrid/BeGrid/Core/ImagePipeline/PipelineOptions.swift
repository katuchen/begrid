import Foundation

nonisolated struct PipelineOptions: Equatable, Sendable {
    var deduplication = true
    var downsampling = true
    var memoryCache = true

    #if DEBUG
    static func overridden(by defaults: UserDefaults = .standard) -> PipelineOptions {
        func flag(_ name: String) -> Bool {
            let key = "pipeline.\(name)"
            return defaults.object(forKey: key) == nil || defaults.bool(forKey: key)
        }
        return PipelineOptions(
            deduplication: flag("dedup"),
            downsampling: flag("downsample"),
            memoryCache: flag("memoryCache")
        )
    }
    #endif
}
