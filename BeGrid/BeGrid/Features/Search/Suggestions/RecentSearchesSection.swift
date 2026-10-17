import SwiftUI

struct RecentSearchesSection: View {
    let queries: [String]
    let onSelect: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        Section {
            ForEach(queries, id: \.self) { query in
                SearchSuggestionRow(query: query, systemImage: "clock.arrow.circlepath", onSelect: onSelect)
            }
        } header: {
            HStack {
                Text("Recent")
                Spacer()
                Button("Clear", action: onClear)
            }
        }
    }
}
