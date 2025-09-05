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
                if viewStore.searchText.isEmpty {
                    return viewStore.cats
                } else {
                    return viewStore.cats.filter { cat in
                        cat.breeds?.first?.name.localizedCaseInsensitiveContains(viewStore.searchText) ?? false
                    }
                }
            }()

            NavigationStack {
                VStack {
                    CatGridHelper.catsGrid(for: catsToShow, viewStore: viewStore)
                }
                .navigationTitle(viewStore.showFavorites ? "Favorites" :"Cats By Breeds")
                .if(!viewStore.showFavorites) { view in
                    view.searchable(
                        text: Binding(
                            get: { viewStore.searchText },
                            set: { viewStore.send(.searchTextChanged($0)) }
                        ),
                        prompt: "Search cats"
                    )
                }
                .onAppear { viewStore.send(.onAppear) }
                .alert(store: store.scope(state: \.$alert, action: CatListFeature.Action.alert))
                .navigationDestination(
                    store: store.scope(
                        state: \.$selectedCat,
                        action: CatListFeature.Action.selectedCat
                    )
                ) { detailStore in
                    CatDetailView(store: detailStore)
                }
            }
        }
    }
}
