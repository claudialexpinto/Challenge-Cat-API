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
            let catsToShow: [Cat] = {
                if viewStore.showFavorites {
                    return viewStore.cats.filter { viewStore.favorites.contains($0.uuID) }
                } else if viewStore.searchText.isEmpty {
                    return viewStore.cats
                } else {
                    return viewStore.cats.filter { cat in
                        cat.breeds?.first?.name.localizedCaseInsensitiveContains(viewStore.searchText) ?? false
                    }
                }
            }()

            NavigationStack {
                VStack {
                    if viewStore.showFavorites && catsToShow.isEmpty {
                        Spacer()
                        Text("No favorites yet")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        Spacer()
                    } else {
                        catsGrid(for: catsToShow, viewStore: viewStore)
                        
                        if viewStore.showFavorites {
                            Text("Average Lifespan: \(Int(calculateAverageLifespan(for: viewStore))) years")
                                .font(.headline)
                                .padding()
                        }
                    }
                    
                    addFilterButtons(for: viewStore)
                }
                .navigationTitle(viewStore.showFavorites ? "Favorites" :"Cats By Breeds")
                .searchable(
                    text: Binding(
                        get: { viewStore.searchText },
                        set: { viewStore.send(.searchTextChanged($0)) }
                    ),
                    prompt: "Search cats"
                )
                .onAppear { viewStore.send(.onAppear) }
                .alert(store: store.scope(state: \.$alert, action: CatListFeature.Action.alert))
            }
        }
    }
}

extension CatListView {
    
    private func catsGrid(for cats: [Cat], viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> some View {
        let spacing: CGFloat = 20
        let baseWidth: CGFloat = 125
        
        return ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: baseWidth), spacing: spacing)], spacing: spacing) {
                ForEach(Array(cats.enumerated()), id: \.element.uuID) { index, cat in
                    CatCellView(
                        cat: cat,
                        width: baseWidth,
                        isFavorite: viewStore.favorites.contains(cat.uuID),
                        toggleFavorite: { viewStore.send(.toggleFavorite(cat.uuID)) }
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .onAppear {
                        if index == cats.count - 1 && !viewStore.showFavorites {
                            viewStore.send(.loadMore)
                        }
                    }
                }
            }
            .padding(.horizontal, spacing)
            .padding(.vertical, spacing)
        }
    }
    
    private func calculateAverageLifespan(for viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> Double {
        let favCats = viewStore.cats.filter { viewStore.favorites.contains($0.uuID) }
        
        let lifespans = favCats.compactMap { $0.breeds?.first?.life_span }
        
        let numbers = lifespans.compactMap { span -> Double? in
            let parts = span.split(separator: "-").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard let min = parts.first.flatMap({ Double($0) }),
                  let max = parts.last.flatMap({ Double($0) }) else { return nil }
            return (min + max) / 2
        }
        
        guard !numbers.isEmpty else { return 0 }
        let total = numbers.reduce(0, +)
        return total / Double(numbers.count)
    }

    
    private func addFilterButtons(for viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> some View {
        HStack(spacing: 16) {
            Button("All Cats") { viewStore.send(.showAllCats) }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(!viewStore.showFavorites ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(!viewStore.showFavorites ? .white : .primary)
                .cornerRadius(8)

            Button("Favorites") { viewStore.send(.showFavorites) }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(viewStore.showFavorites ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(viewStore.showFavorites ? .white : .primary)
                .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
