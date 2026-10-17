import SwiftUI

struct SearchResultsView: View {
    let results: SearchViewModel.Results
    let isStale: Bool

    var body: some View {
        PhotoGridView(model: results.grid) {
            ContentUnavailableView.search(text: results.query)
        }
        .opacity(isStale ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.2), value: isStale)
    }
}
