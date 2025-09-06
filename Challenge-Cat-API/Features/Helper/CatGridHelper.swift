//
//  CatGridHelper.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 05/09/2025.
//

import SwiftUI
import ComposableArchitecture

struct CatGridHelper {
    
    static func catsGrid(
        for cats: [Cat],
        viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>
    ) -> some View {
        let spacing: CGFloat = 20
        let baseWidth: CGFloat = 125
        
        return ZStack {
            ScrollView {
                if !cats.isEmpty {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: baseWidth), spacing: spacing)],
                        spacing: spacing
                    ) {
                        ForEach(Array(cats.enumerated()), id: \.element.uuID) { index, cat in
                            CatGridHelper.catGridItem(
                                cat: cat,
                                index: index,
                                catsCount: cats.count,
                                baseWidth: baseWidth,
                                viewStore: viewStore
                            )
                        }
                    }
                    .padding(.horizontal, spacing)
                    .padding(.vertical, spacing)
                }
            }
            
            if cats.isEmpty && viewStore.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("Loading cats…")
                        .foregroundColor(.secondary)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if viewStore.isLoadingMore {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            }
        }
    }
    
    static func catGridItem(
        cat: Cat,
        index: Int,
        catsCount: Int,
        baseWidth: CGFloat,
        viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>
    ) -> some View {
        Button {
            viewStore.send(.selectCat(cat.id ?? ""))
        } label: {
            CatCellView(
                cat: cat,
                width: baseWidth,
                isFavorite: viewStore.favorites.contains(cat.id ?? ""),
                toggleFavorite: { viewStore.send(.toggleFavorite(id: cat.id ?? "")) }
            )
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .onAppear {
            if index == catsCount - 1 {
                viewStore.send(.loadMore)
            }
        }
    }
    
    static func catDetailStore(
        for cat: Cat,
        viewStore: ViewStore<CatListFeature.State, CatListFeature.Action>
    ) -> StoreOf<CatDetailFeature> {
        let initialState = CatDetailFeature.State(
            uuid: cat.uuID,
            id: cat.id ?? "",
            url: cat.url,
            breeds: cat.breeds,
            isFavorite: viewStore.favorites.contains(cat.id ?? "")
        )
        return Store(
            initialState: initialState
        ) {
            CatDetailFeature()
        }
    }
}
