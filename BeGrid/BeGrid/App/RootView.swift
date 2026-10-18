import SwiftUI

struct RootView: View {
    @State private var feed: PhotoGridViewModel
    @State private var search: SearchViewModel
    @FocusState private var isSearchFocused: Bool
    @Environment(\.isOnline) private var isOnline

    init(repository: any PhotoRepository) {
        _feed = State(initialValue: PhotoGridViewModel(source: repository.feedSource()))
        _search = State(initialValue: SearchViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FeedView(model: feed, isActive: !showsResults)
                    .opacity(showsResults ? 0 : 1)
                    .allowsHitTesting(!showsResults)
                    .accessibilityHidden(showsResults)
                if let results = search.results {
                    SearchResultsView(results: results, isStale: search.isStale)
                        .id(ObjectIdentifier(results.grid))
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: search.results.map { ObjectIdentifier($0.grid) })
            .safeAreaInset(edge: .bottom) {
                if !isOnline {
                    OfflineBanner()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isOnline)
            .scrollDismissesKeyboard(.immediately)
            .searchable(text: $search.query, prompt: "Search photos")
            .modifier(SearchFocus(isFocused: $isSearchFocused))
            .searchSuggestions {
                if search.query.isEmpty {
                    SearchSuggestionsView(model: search) { query in
                        search.select(query)
                        isSearchFocused = false
                    }
                }
            }
            .onSubmit(of: .search) {
                search.submit()
                isSearchFocused = false
            }
        }
    }

    private var showsResults: Bool {
        search.results != nil
    }
}

private struct SearchFocus: ViewModifier {
    let isFocused: FocusState<Bool>.Binding

    func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.searchFocused(isFocused)
        } else {
            content
        }
    }
}
