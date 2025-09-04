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
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack {
                     catsGrid(viewStore: viewStore)
                    
                    CatFiltersView(
                        allCatsAction: nil,
                        favoritesAction: {
                            viewStore.send(.navigateToFavorites)
                        }
                    )
                }
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
                .navigationDestination(
                    store: store.scope(
                        state: \.$favoritesSheet,
                        action: CatListFeature.Action.favoritesSheet
                    )
                ) { favoritesStore in
                    FavoritesView(store: favoritesStore)
                }
            }
        }
    }

    // MARK: - Grid Subview
    private func catsGrid(viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> some View {
        let spacing: CGFloat = 20
        let baseWidth: CGFloat = 125

        let displayedCats: [Cat] = {
            if viewStore.searchText.isEmpty {
                return viewStore.cats
            } else {
                return viewStore.cats.filter { cat in
                    cat.breeds?.first?.name.localizedCaseInsensitiveContains(viewStore.searchText) ?? false
                }
            }
        }()

        return ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: baseWidth), spacing: spacing)],
                spacing: spacing
            ) {
                ForEach(Array(displayedCats.enumerated()), id: \.element.uuID) { index, cat in
                    CatCellView(
                        cat: cat,
                        width: baseWidth,
                        isFavorite: viewStore.favorites.contains(cat.uuID),
                        toggleFavorite: { viewStore.send(.toggleFavorite(cat.uuID)) }
                    )
                    .aspectRatio(1, contentMode: .fit) // quadrado
                    .onAppear {
                        if index == displayedCats.count - 1 {
                            viewStore.send(.loadMore)
                        }
                    }
                }
            }
            .padding(.horizontal, spacing)
            .padding(.vertical, spacing)
        }
    }
}
