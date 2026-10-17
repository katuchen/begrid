import SwiftUI

struct PhotoCreditView: View {
    let photo: Photo

    private var credit: AttributedString {
        AttributedString("Photo by ")
            + link(photo.photographer.name, to: photo.photographer.profileURL)
            + AttributedString(" on ")
            + link("Unsplash", to: URL(string: "https://unsplash.com"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if photo.summary != PhotoMapper.untitledSummary {
                Text(photo.summary)
                    .font(.subheadline)
                    .lineLimit(3)
            }
            Text(credit)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .tint(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func link(_ text: String, to url: URL?) -> AttributedString {
        var link = AttributedString(text)
        link.link = url
        link.font = .footnote.weight(.semibold)
        return link
    }
}
