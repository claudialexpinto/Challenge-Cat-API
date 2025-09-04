//
//  CatListView.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//

import SwiftUI
import ComposableArchitecture

struct CatListView: View {
    let store: StoreOf<CatListFeature>

        var body: some View {
            WithViewStore(
                self.store,
                observe: { (state: CatListFeature.State) in state }
            ) { (viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) in

                NavigationView {
                    content(viewStore: viewStore)
                        .navigationTitle("Cats By Breeds")
                        .onAppear { viewStore.send(.onAppear) }
                        .alert(store: store.scope(state: \.$alert, action: CatListFeature.Action.alert))
                        .searchable(
                            text: Binding(
                                get: { viewStore.searchText },
                                set: { viewStore.send(.searchTextChanged($0)) }
                            ),
                            prompt: "Search cats"
                        )
                }
            }
        }

        // MARK: - Content dividido
        private func content(viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> some View {
            VStack {
                ScrollView {
                    catsGrid(viewStore: viewStore)
                }

                filters(viewStore: viewStore)
            }
        }

        private func filters(viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> some View {
            HStack(spacing: 16) {
                Button("All Cats") { viewStore.send(.showAllCats) }
                    .buttonStyle(FilterButtonStyle(isSelected: !viewStore.showFavorites))
                Button("Favorites") { viewStore.send(.showFavorites) }
                    .buttonStyle(FilterButtonStyle(isSelected: viewStore.showFavorites))
            }
            .padding()
        }


    // MARK: - Grid Subview
    private func catsGrid(viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> some View {
        let spacing: CGFloat = 5
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3)

        let displayedCats = viewStore.showFavorites
            ? viewStore.cats.filter { viewStore.favorites.contains($0.uiID) }
            : viewStore.cats

        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(displayedCats.enumerated()), id: \.element.uiID) { index, cat in
                CatCellView(
                    cat: cat,
                    width: 100,
                    isFavorite: viewStore.favorites.contains(cat.uiID),
                    toggleFavorite: { viewStore.send(.toggleFavorite(cat.uiID)) }
                )
                .onAppear {
                    if index == displayedCats.count - 1 {
                        viewStore.send(.loadMore)
                    }
                }
            }
        }
        .padding(spacing)
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search cats", text: $text)
                .textFieldStyle(.roundedBorder)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Filter Button Style
struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(isSelected ? .white : .black)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
