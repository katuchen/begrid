import SwiftUI

struct PhotoDetailView: View {
    let route: PhotoDetailRoute
    let namespace: Namespace.ID
    let onPhotoChange: (Photo.ID) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.imageLoader) private var loader
    @State private var currentID: Photo.ID?
    @State private var isZoomed = false
    @State private var isPresented = ZoomTransition.isAvailable

    init(route: PhotoDetailRoute, namespace: Namespace.ID, onPhotoChange: @escaping (Photo.ID) -> Void) {
        self.route = route
        self.namespace = namespace
        self.onPhotoChange = onPhotoChange
        _currentID = State(initialValue: route.selectedID)
    }

    private var currentPhoto: Photo? {
        route.photos.first { $0.id == currentID }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            pager
                .scaleEffect(isPresented ? 1 : 0.92)
            chrome
                .opacity(isZoomed ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: isZoomed)
        }
        .opacity(isPresented ? 1 : 0)
        .statusBarHidden()
        .preferredColorScheme(.dark)
        .presentationBackground(.clear)
        .zoomTransition(sourceID: currentID ?? route.selectedID, in: namespace)
        .onChange(of: currentID) { _, id in
            if let id {
                onPhotoChange(id)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                isPresented = true
            }
        }
    }

    private var pager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(route.photos) { photo in
                    ZoomableView(aspectRatio: photo.aspectRatio) { isZoomed = $0 } content: {
                        DetailPhotoImage(photo: photo, previewPixelSize: route.previewPixelSize)
                            .environment(\.imageLoader, loader)
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(photo.summary)
                    .accessibilityAddTraits(.isImage)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentID)
        .scrollDisabled(isZoomed)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
    }

    private var chrome: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Close", systemImage: "xmark", action: close)
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.horizontal, 16)
            Spacer()
            if let currentPhoto {
                PhotoCreditView(photo: currentPhoto)
                    .padding(.horizontal, 16)
                    .padding(.top, 32)
                    .padding(.bottom, 8)
                    .background {
                        LinearGradient.captionScrim
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
            }
        }
        .foregroundStyle(.white)
    }

    private func close() {
        guard !ZoomTransition.isAvailable else {
            dismiss()
            return
        }
        withAnimation(.easeIn(duration: 0.2)) {
            isPresented = false
        } completion: {
            ZoomTransition.withoutAnimation {
                dismiss()
            }
        }
    }
}
