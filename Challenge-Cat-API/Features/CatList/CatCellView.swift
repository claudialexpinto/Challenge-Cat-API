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
                            .cornerRadius(10)
                    } placeholder: {
                        ProgressView()
                            .frame(width: width, height: width)
                    }
                }
                Text(cat.breeds?.first?.name ?? "Unknown Breed")
                    .font(.caption)
                    .lineLimit(1)
                    .frame(width: width)
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)

            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .padding(5)
            }
        }
    }
}
