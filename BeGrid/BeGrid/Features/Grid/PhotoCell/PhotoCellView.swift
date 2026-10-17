import SwiftUI

struct PhotoCellView: View, nonisolated Equatable {
    static let aspectRatio = 4.0 / 5.0

    let model: PhotoCellModel
    let pixelSize: PixelSize

    var body: some View {
        Color.clear
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .overlay {
                RemoteImage(
                    url: model.imageURL(covering: pixelSize),
                    targetPixelSize: pixelSize,
                    blurHash: model.blurHash,
                    placeholder: model.color
                )
            }
            .overlay(alignment: .bottom) {
                caption
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.summary)
            .accessibilityAddTraits(.isImage)
    }

    private var caption: some View {
        Text(model.summary)
            .font(.caption)
            .foregroundStyle(.white)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 24)
            .padding(.bottom, 8)
            .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
    }
}
