//
//  CatFiltersView.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 04/09/2025.
//

import SwiftUI
import ComposableArchitecture

struct CatFiltersView: View {
    var allCatsAction: (() -> Void)? = nil
    var favoritesAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            Button("All Cats") {
                allCatsAction?()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Favorites") {
                favoritesAction?()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

