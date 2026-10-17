import SwiftUI

struct SearchSuggestionRow: View {
    let query: String
    let systemImage: String
    let onSelect: (String) -> Void

    var body: some View {
        Button {
            onSelect(query)
        } label: {
            Label(query, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
