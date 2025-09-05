//
//  MainTabView.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 05/09/2025.
//

import SwiftUI
import ComposableArchitecture

struct MainTabView: View {
    let store: StoreOf<CatListFeature>
    
    var body: some View {
        TabView {
            CatListView(store: store)
                .tabItem {
                    Label("All Cats", systemImage: "cat")
                }
            FavoritesView(store: store)
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
        }
    }
}
