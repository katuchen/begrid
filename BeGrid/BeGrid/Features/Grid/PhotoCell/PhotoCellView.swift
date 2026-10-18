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
                caption(model.accessibilityLabel)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.accessibilityLabel)
            .accessibilityAddTraits(.isImage)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(.white)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 24)
            .padding(.bottom, 8)
            .background(LinearGradient.captionScrim)
    }
}
