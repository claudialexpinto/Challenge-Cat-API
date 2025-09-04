//
//  FavouritesListView.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 04/09/2025.
//

import SwiftUI
import ComposableArchitecture

struct FavoritesView: View {
    let store: Store<FavoritesFeature.State, FavoritesFeature.Action>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                if viewStore.favorites.isEmpty {
                        Text("No favorites yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 20)], spacing: 20) {
                                ForEach(viewStore.cats.filter { viewStore.favorites.contains($0.uuID) }) { cat in
                                    CatCellView(
                                        cat: cat,
                                        width: 125,
                                        isFavorite: true,
                                        toggleFavorite: { viewStore.send(.removeFavorite(cat.uuID)) }
                                    )
                                    .aspectRatio(1, contentMode: .fit)
                                }
                            }
                            .padding()
                        }

                        Text("Average Lifespan: \(calculateAverageLifespan(for: viewStore)) years")
                            .font(.headline)
                            .padding()
                    }
                CatFiltersView(
                       allCatsAction: {
                           viewStore.send(.closeFavorites)
                       },
                       favoritesAction: nil // já estamos nos favoritos
                   )
            }
            .navigationTitle("Favorites")
        }
    }

    private func calculateAverageLifespan(for viewStore: ViewStore<FavoritesFeature.State, FavoritesFeature.Action>) -> Int {
        let favCats = viewStore.cats.filter { viewStore.favorites.contains($0.uuID) }
        let lifespans = favCats.compactMap { $0.breeds?.first?.lifeSpan }
        let numbers = lifespans.compactMap { span -> Int? in
            let parts = span.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            return parts.first.flatMap { Int($0) } // usar valor mínimo
        }
        guard !numbers.isEmpty else { return 0 }
        let total = numbers.reduce(0, +)
        return total / numbers.count
    }
}
