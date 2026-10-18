import SwiftUI

struct PhotoGridView<Empty: View>: View {
    let model: PhotoGridViewModel
    private let empty: Empty

    @Environment(\.displayScale) private var displayScale
    @Environment(\.imageLoader) private var imageLoader
    @Environment(\.isOnline) private var isOnline
    @State private var width: CGFloat = 0
    @State private var detail: PhotoDetailRoute?
    @State private var prefetcher = ImagePrefetcher()
    @Namespace private var zoomNamespace

    init(model: PhotoGridViewModel, @ViewBuilder empty: () -> Empty) {
        self.model = model
        self.empty = empty()
    }

    var body: some View {
        content
            .task(id: ObjectIdentifier(model)) {
                prefetcher.cancelAll()
                await model.loadFirstPage()
            }
            .onDisappear {
                prefetcher.cancelAll()
            }
            .onChange(of: isOnline) { _, isOnline in
                guard isOnline else { return }
                prefetcher.cancelAll()
                Task {
                    await model.reconnect()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch (model.state, model.items.isEmpty) {
        case (.idle, true), (.loadingFirst, true):
            SkeletonGridView()
        case (.failed(let error), true):
            ContentUnavailableView {
                Label("Couldn't Load Photos", systemImage: "photo.on.rectangle.angled")
            } description: {
                Text(error.message)
            } actions: {
                retryButton
                    .buttonStyle(.borderedProminent)
            }
        case (.exhausted, true):
            empty
        default:
            grid
        }
    }

    private var cellPixelSize: PixelSize? {
        let cellWidth = (width - PhotoGridLayout.spacing) / 2
        guard cellWidth > 0 else { return nil }
        return PixelSize(points: CGSize(width: cellWidth, height: cellWidth / PhotoCellView.aspectRatio), scale: displayScale)
    }

    private var grid: some View {
        ScrollViewReader { proxy in
            scrollView
                .sensoryFeedback(.impact(flexibility: .soft), trigger: detail?.id) { _, id in id != nil }
                .fullScreenCover(item: $detail) { route in
                    PhotoDetailView(route: route, namespace: zoomNamespace) { id in
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
        }
    }

    private var scrollView: some View {
        ScrollView {
            LazyVGrid(columns: PhotoGridLayout.columns, spacing: PhotoGridLayout.spacing) {
                if let cellPixelSize {
                    ForEach(Array(model.items.enumerated()), id: \.element.id) { index, photo in
                        Button {
                            open(photo, previewPixelSize: cellPixelSize)
                        } label: {
                            PhotoCellView(model: PhotoCellModel(photo: photo), pixelSize: cellPixelSize)
                                .equatable()
                        }
                        .buttonStyle(.plain)
                        .zoomTransitionSource(id: photo.id, in: zoomNamespace)
                        .onAppear {
                            model.onItemAppear(photo.id)
                            prefetch(after: index, pixelSize: cellPixelSize)
                        }
                    }
                }
            }
            footer
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .refreshable {
            await model.refresh()
        }
    }

    private func prefetch(after index: Int, pixelSize: PixelSize) {
        let upcoming = model.items.dropFirst(index + 1).prefix(ImagePrefetcher.distance)
        let requests = upcoming.map {
            ImagePrefetcher.Request(url: PhotoCellModel(photo: $0).imageURL(covering: pixelSize), size: pixelSize)
        }
        prefetcher.prefetch(requests, after: index, using: imageLoader)
    }

    private func open(_ photo: Photo, previewPixelSize: PixelSize) {
        ZoomTransition.present {
            detail = PhotoDetailRoute(photos: model.items, selectedID: photo.id, previewPixelSize: previewPixelSize)
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch model.state {
        case .loadingMore:
            ProgressView()
                .padding()
        case .failed(let error):
            VStack(spacing: 8) {
                Text(error.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                retryButton
                    .buttonStyle(.bordered)
            }
            .padding()
        case .exhausted:
            Text("You're all caught up")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding()
        case .idle, .loadingFirst, .loaded:
            EmptyView()
        }
    }

    private var retryButton: some View {
        Button("Try Again") {
            Task {
                await model.retry()
            }
        }
    }
}

extension PhotoGridView where Empty == ContentUnavailableView<Label<Text, Image>, Text?, EmptyView> {
    init(model: PhotoGridViewModel) {
        self.init(model: model) {
            ContentUnavailableView("No Photos", systemImage: "photo.on.rectangle")
        }
    }
}
