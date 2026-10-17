import SwiftUI
import UIKit

// UIKit is used here because SwiftUI's ScrollView can't pinch-zoom. UIScrollView provides pinch,
// pan, zoom limits, bounce and anchored double-tap zoom out of the box.
struct ZoomableView<Content: View>: UIViewRepresentable {
    let aspectRatio: Double
    let onZoomChange: (Bool) -> Void
    @ViewBuilder let content: Content

    func makeUIView(context: Context) -> ZoomingScrollView {
        let host = UIHostingController(rootView: content)
        host.safeAreaRegions = []
        host.view.backgroundColor = .clear
        context.coordinator.host = host
        return ZoomingScrollView(zoomedView: host.view)
    }

    func updateUIView(_ view: ZoomingScrollView, context: Context) {
        context.coordinator.host?.rootView = content
        view.aspectRatio = aspectRatio
        view.onZoomChange = onZoomChange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var host: UIHostingController<Content>?
    }
}

final class ZoomingScrollView: UIScrollView, UIScrollViewDelegate {
    static let doubleTapScale: CGFloat = 2.5

    var aspectRatio: Double = 1 {
        didSet {
            if aspectRatio != oldValue {
                laidOutSize = .zero
                setNeedsLayout()
            }
        }
    }
    var onZoomChange: (Bool) -> Void = { _ in }

    private let zoomedView: UIView
    private var laidOutSize: CGSize = .zero
    private var isZoomed = false

    init(zoomedView: UIView) {
        self.zoomedView = zoomedView
        super.init(frame: .zero)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 4
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        decelerationRate = .fast
        addSubview(zoomedView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(toggleZoom(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != laidOutSize {
            laidOutSize = bounds.size
            zoomScale = 1
            let width = min(bounds.width, bounds.height * aspectRatio)
            let fitted = CGSize(width: width, height: width / aspectRatio)
            zoomedView.frame = CGRect(origin: .zero, size: fitted)
            contentSize = fitted
        }
        centerContent()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        zoomedView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
        let isZoomed = zoomScale > minimumZoomScale
        guard isZoomed != self.isZoomed else { return }
        self.isZoomed = isZoomed
        onZoomChange(isZoomed)
    }

    @objc private func toggleZoom(_ recognizer: UITapGestureRecognizer) {
        guard zoomScale == minimumZoomScale else {
            setZoomScale(minimumZoomScale, animated: true)
            return
        }
        let point = recognizer.location(in: zoomedView)
        let size = CGSize(width: bounds.width / Self.doubleTapScale, height: bounds.height / Self.doubleTapScale)
        zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height), animated: true)
    }

    private func centerContent() {
        let horizontal = max(0, (bounds.width - contentSize.width) / 2)
        let vertical = max(0, (bounds.height - contentSize.height) / 2)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}
