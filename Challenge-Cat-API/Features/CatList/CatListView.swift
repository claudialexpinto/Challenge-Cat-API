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
                    // Scrollable Grid responsiva
                    catsGrid(viewStore: viewStore)
                    
                    // Botões de filtro
                    filters(viewStore: viewStore)
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
            }
        }
    }

    // MARK: - Grid Subview
    private func catsGrid(viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> some View {
        let spacing: CGFloat = 20
        let baseWidth: CGFloat = 125

        let displayedCats = viewStore.showFavorites
            ? viewStore.cats.filter { viewStore.favorites.contains($0.uiID) }
            : viewStore.cats

        return ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: baseWidth), spacing: spacing)],
                spacing: spacing
            ) {
                ForEach(Array(displayedCats.enumerated()), id: \.element.uiID) { index, cat in
                    CatCellView(
                        cat: cat,
                        width: baseWidth,
                        isFavorite: viewStore.favorites.contains(cat.uiID),
                        toggleFavorite: { viewStore.send(.toggleFavorite(cat.uiID)) }
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


    // MARK: - Filtros
    private func filters(viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>) -> some View {
        HStack(spacing: 16) {
            Button("All Cats") { viewStore.send(.showAllCats) }
                .buttonStyle(FilterButtonStyle(isSelected: !viewStore.showFavorites))
                .frame(maxWidth: .infinity)
            
            Button("Favorites") { viewStore.send(.showFavorites) }
                .buttonStyle(FilterButtonStyle(isSelected: viewStore.showFavorites))
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Button Style
struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
