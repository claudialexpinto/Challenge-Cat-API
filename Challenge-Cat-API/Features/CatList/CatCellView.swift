//
//  CatCellView.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 03/09/2025.
//

import SwiftUI

struct CatCellView: View {
    let cat: Cat
    let width: CGFloat
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if let url = cat.url, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: width)
                            .clipped()
                            .cornerRadius(12)
                            .padding(6)
                    } placeholder: {
                        ProgressView()
                            .frame(width: width, height: width)
                    }
                }

                Text(cat.breeds?.first?.name ?? "Unknown Breed")
                    .font(.caption)
                    .lineLimit(1)
                    .frame(width: width)
                    .padding(.vertical, 4)
                    .foregroundColor(.primary)
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)


            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.yellow)
                    .padding(3)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)

            }
            .offset(x: 8, y: -8)

        }
    }
}
