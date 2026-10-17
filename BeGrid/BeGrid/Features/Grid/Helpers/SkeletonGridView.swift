import SwiftUI

struct SkeletonGridView: View {
    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                LazyVGrid(columns: PhotoGridLayout.columns, spacing: PhotoGridLayout.spacing) {
                    ForEach(0..<8, id: \.self) { _ in
                        Color.photoPlaceholder
                            .aspectRatio(PhotoCellView.aspectRatio, contentMode: .fit)
                    }
                }
                .shimmering()
            }
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading photos")
    }
}
