import SwiftUI

struct SuggestedSearchesSection: View {
    let queries: [String]
    let onSelect: (String) -> Void

    var body: some View {
        Section("Suggestions") {
            ForEach(queries, id: \.self) { query in
                SearchSuggestionRow(query: query, systemImage: "magnifyingglass", onSelect: onSelect)
            }
        }
    }
}
