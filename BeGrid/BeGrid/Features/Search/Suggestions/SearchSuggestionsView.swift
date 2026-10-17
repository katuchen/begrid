import SwiftUI

struct SearchSuggestionsView: View {
    let model: SearchViewModel
    let onSelect: (String) -> Void

    var body: some View {
        if !model.recentQueries.isEmpty {
            RecentSearchesSection(queries: model.recentQueries, onSelect: onSelect, onClear: model.clearRecents)
        }
        SuggestedSearchesSection(queries: SearchViewModel.suggestions, onSelect: onSelect)
    }
}
