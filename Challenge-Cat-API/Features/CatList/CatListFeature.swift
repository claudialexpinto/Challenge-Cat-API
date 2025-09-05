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
        public var hasLoadedInitialCats: Bool = false

        public var cats: [Cat] = []
        public var favorites: Set<UUID> = []

        public var currentPage: Int = 1
        public var isLoading: Bool = false
        public var canLoadMore: Bool = true

        @PresentationState public var alert: AlertState<Action>?
        @PresentationState public var selectedCat: CatDetailFeature.State?
        
        public var showFavorites: Bool = false
        public var searchText: String = ""
        
        public init() {}
    }
    
    // MARK: - Action
    public enum Action: Equatable {
        case onAppear
        case loadMore
        
        case catsResponse([Cat])
        case failedToLoad(String)
        case errorDismissed
        
        case toggleFavorite(UUID)
        
        case alert(PresentationAction<CatListFeature.Action>)
        
        case selectCat(UUID)
        case selectedCat(PresentationAction<CatDetailFeature.Action>)
        
        case searchTextChanged(String)
        
        case showAllCats
        case showFavorites
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
                let savedCats = environment.persistenceController.fetchCats()
                
                if !savedCats.isEmpty && savedCats.allSatisfy({ !($0.breeds?.isEmpty ?? true) }) {
                    state.cats = savedCats
                    state.isLoading = false
                    state.currentPage = (savedCats.count / 10) + 1
                    state.hasLoadedInitialCats = true
                    return .none
                } else {
                    state.cats = []
                    state.isLoading = true
                    state.currentPage = 1
                    state.hasLoadedInitialCats = false
                }

                let page = state.currentPage
                let api = environment.apiClient
                let persistence = environment.persistenceController

                return .run { send in
                    do {
                        let cats = try await api.fetchCats(page: page, limit: 10)
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
                        let cats = try await api.fetchCats(page: nextPage, limit: 10)
                        persistence.saveCats(cats)
                        await send(.catsResponse(cats))
                    } catch {
                        await send(.failedToLoad(error.localizedDescription))
                    }
                }
                
            case let .catsResponse(cats):
                state.isLoading = false
                state.hasLoadedInitialCats = true
                
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
                state.alert = AlertState(
                    title: { TextState("Error") },
                    actions: {
                        ButtonState(action: .send(.errorDismissed), label: { TextState("OK") })
                    },
                    message: { TextState(message) }
                )
                return .none
                
            case .alert(.presented(.errorDismissed)):
                state.alert = nil
                return .none
                
            case .alert(.dismiss):
                return .none
                
            case let .toggleFavorite(catUuid):
                toggleFavorite(id: catUuid, state: &state)
                return .none
         
            case let .searchTextChanged(text):
                state.searchText = text
                return .none

            case .showAllCats:
                state.showFavorites = false
                return .none
                
            case .showFavorites:
                state.showFavorites = true
                return .none
                
            case .selectCat(let id):
                guard let cat = state.cats.first(where: { $0.uuID == id }) else { return .none }

                state.selectedCat = CatDetailFeature.State(
                    id: cat.uuID,
                    url: cat.url,
                    breeds: cat.breeds,
                    isFavorite: state.favorites.contains(cat.uuID)
                )
                return .none

            case .selectedCat(.presented(.toggleFavorite)):
                guard let id = state.selectedCat?.id else { return .none }

                if state.favorites.contains(id) {
                    state.favorites.remove(id)
                } else {
                    state.favorites.insert(id)
                }

                if var selected = state.selectedCat {
                    selected.isFavorite.toggle()
                    state.selectedCat = selected
                }

                return .none


            case .selectedCat(.dismiss):
                state.selectedCat = nil
                return .none

            case .selectedCat(.presented):
                return .none
                
            default:
                return .none
            }
        }
    }
}

// MARK: - Helpers
private func toggleFavorite(id: UUID, state: inout CatListFeature.State) {
    let wasFavorite = state.favorites.contains(id)

    if wasFavorite {
        state.favorites.remove(id)
    } else {
        state.favorites.insert(id)
    }

    // Atualiza também o selectedCat
    if var selected = state.selectedCat, selected.id == id {
        selected.isFavorite = !wasFavorite
        state.selectedCat = selected
    }
}
