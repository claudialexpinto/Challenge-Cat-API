//
//  CatDetailFeature.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 04/09/2025.
//

import SwiftUI
import ComposableArchitecture
import Foundation

public struct CatDetailFeature: Reducer {
    public struct State: Equatable {
        let uuid: UUID
        let id: String
        let url: String?
        var breeds: [CatBreed]?
        var isFavorite: Bool
       
        @PresentationState var alert: AlertState<Action>?
    }

    public enum Action: Equatable {
        case toggleFavorite
        case alert(PresentationAction<Action>)
    }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .toggleFavorite:
            state.isFavorite.toggle()
            return .none
        case .alert:
            return .none
        }
    }
}
