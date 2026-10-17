import SwiftUI

struct PhotoGridView: View {
    static let spacing: CGFloat = 2
    static let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)

    let model: PhotoGridViewModel

    @Environment(\.displayScale) private var displayScale
    @State private var width: CGFloat = 0

    var body: some View {
        content
            .task {
                await model.loadNextPage()
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
        default:
            grid
        }
    }

    private var cellPixelSize: PixelSize? {
        let cellWidth = (width - Self.spacing) / 2
        guard cellWidth > 0 else { return nil }
        return PixelSize(
            width: Int((cellWidth * displayScale).rounded(.up)),
            height: Int((cellWidth / PhotoCellView.aspectRatio * displayScale).rounded(.up))
        )
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: Self.columns, spacing: Self.spacing) {
                if let cellPixelSize {
                    ForEach(model.items) { photo in
                        PhotoCellView(model: PhotoCellModel(photo: photo), pixelSize: cellPixelSize)
                            .equatable()
                            .onAppear {
                                model.onItemAppear(photo.id)
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
