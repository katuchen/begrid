import SwiftUI

struct FeedView: View {
    let model: PhotoGridViewModel
    let isActive: Bool

    var body: some View {
        PhotoGridView(model: model, isActive: isActive)
            .navigationTitle("Editorial")
    }
}
