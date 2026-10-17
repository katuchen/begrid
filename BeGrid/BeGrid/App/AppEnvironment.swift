import Foundation

struct AppEnvironment {
    let repository: any PhotoRepository
    let imageLoader: any ImageLoading

    static func live() throws(ConfigurationError) -> AppEnvironment {
        let configuration = try AppConfiguration.load()
        let api = UnsplashAPI(client: URLSessionHTTPClient(), accessKey: configuration.unsplashAccessKey)
        return AppEnvironment(
            repository: UnsplashPhotoRepository(api: api),
            imageLoader: ImagePipeline(options: pipelineOptions)
        )
    }

    private static var pipelineOptions: PipelineOptions {
        #if DEBUG
        PipelineOptions.overridden()
        #else
        PipelineOptions()
        #endif
    }
}
