import SwiftUI

struct RemoteImage: View {
    private struct Request: Hashable {
        let url: URL
        let size: PixelSize
    }

    private struct Attempt: Hashable {
        let request: Request
        let isOnline: Bool
    }

    private struct Loaded {
        let request: Request
        let image: UIImage
    }

    let url: URL
    let targetPixelSize: PixelSize
    let blurHash: String?
    let placeholder: Color
    var preview: UIImage?

    @Environment(\.imageLoader) private var loader
    @Environment(\.isOnline) private var isOnline
    @State private var loaded: Loaded?
    @State private var blur: UIImage?

    private var request: Request {
        Request(url: url, size: targetPixelSize)
    }

    private var isSized: Bool {
        targetPixelSize.width > 0 && targetPixelSize.height > 0
    }

    private var image: UIImage? {
        if let loaded, loaded.request == request {
            return loaded.image
        }
        return isSized ? loader.cachedImage(for: url, targetPixelSize: targetPixelSize) : nil
    }

    var body: some View {
        placeholder
            .overlay {
                if let backdrop = preview ?? blur {
                    fill(backdrop)
                }
            }
            .overlay {
                if let image {
                    fill(image)
                        .transition(.opacity)
                }
            }
            .clipped()
            .task(id: blurHash) {
                guard let blurHash, preview == nil, image == nil else { return }
                blur = await BlurHash.decodedImage(from: blurHash)
            }
            .task(id: Attempt(request: request, isOnline: isOnline)) {
                await load(request)
            }
    }

    private func fill(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
    }

    private func load(_ request: Request) async {
        guard isSized else { return }
        if let cached = loader.cachedImage(for: request.url, targetPixelSize: request.size) {
            loaded = Loaded(request: request, image: cached)
            return
        }
        guard let image = try? await loader.image(for: request.url, targetPixelSize: request.size) else { return }
        withAnimation(.easeIn(duration: 0.2)) {
            loaded = Loaded(request: request, image: image)
        }
    }
}

extension EnvironmentValues {
    @Entry var imageLoader: any ImageLoading = UnavailableImageLoader()
}
