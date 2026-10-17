import SwiftUI

struct RootView: View {
    @State private var feed: PhotoGridViewModel

    init(repository: any PhotoRepository) {
        _feed = State(initialValue: PhotoGridViewModel(source: repository.feedSource()))
    }

    var body: some View {
        NavigationStack {
            FeedView(model: feed)
        }
    }
}
