//
//  CatDetailView.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 04/09/2025.
//

import SwiftUI
import ComposableArchitecture

struct CatDetailView: View {
    let store: StoreOf<CatDetailFeature>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let urlString = viewStore.url, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(12)
                            case .failure:
                                Color.gray.frame(height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .foregroundColor(.secondary)
                    }

                    Text(viewStore.breeds?.first?.name ?? "Unknown")
                        .font(.title)
                        .bold()

                    Text("Origin: \(viewStore.breeds?.first?.origin ?? "Unknown")")
                        .font(.subheadline)

                    Text("Temperament: \(viewStore.breeds?.first?.temperament ?? "Unknown")")
                        .font(.body)

                    Text(viewStore.breeds?.first?.description ?? "No description")
                        .font(.body)
                        .padding(.top, 8)

                    Button {
                        viewStore.send(.toggleFavorite)
                    } label: {
                        HStack {
                            Image(systemName: viewStore.isFavorite ? "heart.fill" : "heart")
                            Text(viewStore.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewStore.isFavorite ? Color.red : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Breed Details")
            .alert(store: store.scope(state: \.$alert, action: CatDetailFeature.Action.alert))
        }
    }
}

