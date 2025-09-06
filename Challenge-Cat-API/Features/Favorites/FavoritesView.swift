//
//  FavoritesView.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 05/09/2025.
//

import SwiftUI
import ComposableArchitecture
import Foundation

struct FavoritesView: View {
    let store: StoreOf<CatListFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            let catsToShow = viewStore.cats.filter { viewStore.favorites.contains($0.uuID) }

            NavigationStack {
                VStack {
                    if catsToShow.isEmpty {
                        Spacer()
                        Text("No favorites yet").foregroundColor(.secondary).font(.headline)
                        Spacer()
                    } else {
                        CatGridHelper.catsGrid(for: catsToShow, viewStore: viewStore)
                        Spacer()
                        Text("Average Lifespan: \(Int(calculateAverageLifespan(for: viewStore))) years")
                            .font(.headline)
                            .padding()
                        Spacer()
                    }
                }
                .navigationTitle("Favorites")
                .onAppear { viewStore.send(.onAppear) }
                .alert(store: store.scope(state: \.$alert, action: CatListFeature.Action.alert))
                .fullScreenCover(
                    store: store.scope(
                        state: \.$selectedCat,
                        action: CatListFeature.Action.selectedCat
                    ),
                    onDismiss: { viewStore.send(.selectedCat(.dismiss)) }
                ) { detailStore in
                    NavigationStack {
                            CatDetailView(store: detailStore)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Close") {
                                            viewStore.send(.selectedCat(.dismiss))
                                        }
                                    }
                                }
                        }
                    .accentColor(.teal)
                }

            }
        }
    }
}

extension FavoritesView {
    private func calculateAverageLifespan(for viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> Double {
        let favCats = viewStore.cats.filter { viewStore.favorites.contains($0.uuID) }
        let lifespans = favCats.compactMap { $0.breeds?.first?.life_span }
        let numbers = lifespans.compactMap { span -> Double? in
            let digits = span.split(whereSeparator: { !$0.isNumber && $0 != "." })
            let parsed = digits.compactMap { Double($0) }
            if parsed.isEmpty { return nil }
            if parsed.count == 1 { return parsed.first }
            return (parsed.first! + parsed.last!) / 2
        }
        guard !numbers.isEmpty else { return 0 }
        return numbers.reduce(0, +) / Double(numbers.count)
    }
}
