import SwiftUI

struct FeedView: View {
    let model: PhotoGridViewModel

    var body: some View {
        PhotoGridView(model: model)
            .navigationTitle("Editorial")
    }
}
