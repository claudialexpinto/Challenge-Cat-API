//
//  FavoritesFeature.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 04/09/2025.
//

import SwiftUI
import ComposableArchitecture

public struct FavoritesFeature: Reducer {

    // MARK: - State
    @ObservableState
    public struct State: Equatable {
        
        public var cats: [Cat] = []
        public var favorites: Set<UUID> = []
        @Presents public var alert: AlertState<Action>?

        public var favoriteCats: [Cat] {
            cats.filter { favorites.contains($0.uuID) }
        }

        public var averageLifespan: Double? {
            let lifespans: [Double] = favoriteCats.compactMap { cat in
                guard let breed = cat.breeds?.first,
                      let life = breed.lifeSpan else { return nil }
                let parts = life
                    .components(separatedBy: "-")
                    .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                return parts.last
            }
            guard !lifespans.isEmpty else { return nil }
            return lifespans.reduce(0, +) / Double(lifespans.count)
        }

        public init(cats: [Cat] = [], favorites: Set<UUID> = []) {
            self.cats = cats
            self.favorites = favorites
        }
    }

    // MARK: - Action
    public enum Action: Equatable {
        case removeFavorite(UUID)
        case alert(PresentationAction<Action>)
        case errorDismissed
        case closeFavorites

        case updateParentFavorites(Set<UUID>)
    }

    // MARK: - Environment
    public struct Environment {}

    // MARK: - Reducer
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .removeFavorite(catID):
                state.favorites.remove(catID)
                return .send(.updateParentFavorites(state.favorites))

            case .updateParentFavorites:
                return .none

            case .alert(.presented(.errorDismissed)):
                state.alert = nil
                return .none

            case .alert(.dismiss):
                return .none
            
            case .closeFavorites:
                return .none
                
            default:
                return .none
            }
        }
    }
}
