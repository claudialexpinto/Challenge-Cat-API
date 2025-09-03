//
//  CatListFeature.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//

import SwiftUI
import ComposableArchitecture
import Foundation

// MARK: - Feature

public struct CatListFeature: Reducer {
    
    // MARK: - State
    public struct State: Equatable {
        public var cats: [Cat] = []
        public var currentPage: Int = 1
        public var isLoading: Bool = false
        public var canLoadMore: Bool = true
        public var alert: AlertState<Action>? = nil
    }
    
    // MARK: - Action
    public enum Action: Equatable {
        case onAppear
        case loadMore
        case catsResponse([Cat])
        case failedToLoad(String)
        case errorDismissed
    }
    
    // MARK: - Environment
    public struct Environment {
        var apiClient: CatAPIClientProtocol
        var persistenceController: PersistenceController
        var mainQueue: AnySchedulerOf<DispatchQueue>
    }
    
    private let environment: Environment
    
    public init(environment: Environment) {
        self.environment = environment
    }
    
    // MARK: - Reducer
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .onAppear:
                state.cats = environment.persistenceController.fetchCats()
                state.isLoading = true
                
                let page = state.currentPage
                let api = environment.apiClient
                let persistence = environment.persistenceController
                
                return .run { send in
                    do {
                        let cats = try await api.fetchCats(page: page, limit: 20)
                        persistence.saveCats(cats)
                        await send(.catsResponse(cats))
                    } catch {
                        await send(.failedToLoad(error.localizedDescription))
                    }
                }
                
            case .loadMore:
                guard state.canLoadMore, !state.isLoading else { return .none }
                state.isLoading = true
                
                let nextPage = state.currentPage
                let api = environment.apiClient
                let persistence = environment.persistenceController
                
                return .run { send in
                    do {
                        let cats = try await api.fetchCats(page: nextPage, limit: 20)
                        persistence.saveCats(cats)
                        await send(.catsResponse(cats))
                    } catch {
                        await send(.failedToLoad(error.localizedDescription))
                    }
                }
                
            case let .catsResponse(cats):
                state.isLoading = false
                if state.currentPage == 1 {
                    state.cats = cats
                } else {
                    state.cats.append(contentsOf: cats)
                }
                state.currentPage += 1
                state.canLoadMore = !cats.isEmpty
                return .none
                
            case let .failedToLoad(message):
                state.isLoading = false
                state.alert = AlertState<CatListFeature.Action>(
                    title: { TextState("Error") },
                    actions: {
                        ButtonState(action: .send(.errorDismissed), label: { TextState("OK") })
                    },
                    message: {TextState(message)})
                return .none
                
            case .errorDismissed:
                state.alert = nil
                return .none
            }
        }
    }
}
