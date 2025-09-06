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
                    CatImageView(urlString: viewStore.url)

                    if let breeds = viewStore.breeds, !breeds.isEmpty {
                        ForEach(breeds) { breed in
                            BreedInfoView(breed: breed)
                        }
                    } else {
                        Text("No breed information available.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    FavoriteButton(isFavorite: viewStore.isFavorite) {
                        viewStore.send(.toggleFavorite)
                    }
                }
                .padding()
            }
            .navigationTitle("Breed Details")
            .accentColor(.teal)
            .alert(store: store.scope(state: \.$alert, action: CatDetailFeature.Action.alert))
        }
    }
}

// MARK: - Subviews

struct CatImageView: View {
    let urlString: String?

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
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
                    PlaceholderImage()
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            PlaceholderImage()
        }
    }

    private func PlaceholderImage() -> some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "cat")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .cornerRadius(12)
    }
}

struct BreedInfoView: View {
    let breed: CatBreed

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(breed.name)
                .font(.title2)
                .bold()

            if let origin = breed.origin {
                Text("Origin: \(origin)")
                    .font(.subheadline)
            }

            if let temperament = breed.temperament {
                Text("Temperament: \(temperament)")
                    .font(.body)
            }

            if let life = breed.life_span {
                Text("Life span: \(life)")
                    .font(.subheadline)
            }

            if let desc = breed.description {
                Text(desc)
                    .font(.body)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            } else {
                Text("No description available")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            if let wiki = breed.wikipediaUrl, let wikiURL = URL(string: wiki) {
                Link("Open in Wikipedia", destination: wikiURL)
                    .font(.footnote)
                    .padding(.top, 4)
            }

            Divider()
        }
    }
}

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                Text(isFavorite ? "Remove from Favorites" : "Add to Favorites")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isFavorite ? Color.red : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}
