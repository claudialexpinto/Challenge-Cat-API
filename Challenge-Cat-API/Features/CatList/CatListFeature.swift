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
        public var favorites: Set<String> = []
        
        public var currentPage: Int = 1
        public var isLoading: Bool = false
        public var canLoadMore: Bool = true
        public var isLoadingMore: Bool = false
        public var pageSize: Int = 10
        
        public var hasLoaded: Bool = false
        
        @PresentationState public var alert: AlertState<Action>?
        @PresentationState public var selectedCat: CatDetailFeature.State?
        
        public var searchText: String = ""
        
        public init() {}
    }
    
    // MARK: - Action
    // Dentro de CatListFeature.Action
    public enum Action: Equatable {
        case onAppear
        case loadMore

        case catsResponse([Cat])
        case retryLoad
        case failedToLoad(String)
        case errorDismissed

        case toggleFavorite(id: String)
        
        case alert(PresentationAction<CatListFeature.Action>)
        
        case selectCat(String)
        case selectedCat(PresentationAction<CatDetailFeature.Action>)
        
        case searchTextChanged(String)

        case toggleFavoriteBatch(ids: Set<String>)
    }

    
    // MARK: - Environment
    public struct Environment {
        var apiClient: CatAPIClientProtocol
        var persistenceController: PersistenceControllerProtocol
        var mainQueue: AnySchedulerOf<DispatchQueue>
        var pageSize: Int
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
                guard !state.hasLoaded else { return .none }
                state.hasLoaded = true
                state.isLoading = true

                state.favorites = Set(environment.persistenceController.fetchFavoriteCats().compactMap { $0.id })

                let page = state.currentPage
                let api = environment.apiClient
                let persistence = environment.persistenceController
                let limit = state.pageSize

                return .run { send in
                    do {
                        let cats = try await api.fetchCats(page: page, limit: limit)
                        persistence.saveCats(cats)
                        await send(.catsResponse(cats))
                    } catch {
                        await send(.failedToLoad(error.localizedDescription))
                    }
                }


            case .loadMore:
                guard state.canLoadMore, !state.isLoading, !state.isLoadingMore else { return .none }
                state.isLoadingMore = true
                
                let nextPage = state.currentPage
                let api = environment.apiClient
                let persistence = environment.persistenceController
                let limit = state.pageSize
                
                return .run { send in
                    do {
                        let cats = try await api.fetchCats(page: nextPage, limit: limit)
                        persistence.saveCats(cats)
                        await send(.catsResponse(cats))
                    } catch {
                        await send(.failedToLoad(error.localizedDescription))
                    }
                }
                
         
            case let .catsResponse(cats):
                state.isLoading = false
                state.isLoadingMore = false

                let updatedCats = cats.map { cat -> Cat in
                    var c = cat
                    if let id = cat.id {
                        c.isFavorite = state.favorites.contains(id)
                    }
                    return c
                }

                if state.currentPage == 1 {
                    state.cats = updatedCats
                } else {
                    state.cats.append(contentsOf: updatedCats)
                }

                state.currentPage += 1
                state.canLoadMore = !cats.isEmpty
                return .none

                
            case .retryLoad:
                state.currentPage = 1
                state.isLoading = true
                let api = environment.apiClient
                let persistence = environment.persistenceController
                let limit = state.pageSize
                return .run { send in
                    do {
                        let cats = try await api.fetchCats(page: 1, limit: limit)
                        persistence.saveCats(cats)
                        await send(.catsResponse(cats))
                    } catch {
                        await send(.failedToLoad(error.localizedDescription))
                    }
                }
                
            case let .failedToLoad(message):
                state.isLoading = false
                state.isLoadingMore = false
                state.alert = AlertState(
                    title: { TextState("Error") },
                    actions: {
                        ButtonState(action: .send(.retryLoad), label: { TextState("Retry") })
                        ButtonState(action: .send(.errorDismissed), label: { TextState("Cancel") })
                    },
                    message: { TextState(message) }
                )
                return .none
                
            case .alert(.presented(.errorDismissed)):
                state.alert = nil
                return .none
                
            case .alert(.dismiss):
                return .none
                
            case let .toggleFavorite(catID):
                environment.persistenceController.toggleFavorite(catID: catID)

                let updatedFavorites = Set(environment.persistenceController.fetchFavoriteCats().compactMap { $0.id })
                state.favorites = updatedFavorites

                if var selected = state.selectedCat, selected.id == catID {
                    selected.isFavorite.toggle()
                    state.selectedCat = selected
                }
                return .none
                
            case let .toggleFavoriteBatch(ids):
                state.favorites = ids
                return .none
                
            case let .searchTextChanged(text):
                state.searchText = text
                let allCats = environment.persistenceController.fetchCats()
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    state.cats = allCats
                } else {
                    let lower = text.localizedLowercase
                    state.cats = allCats.filter { cat in
                        guard let breeds = cat.breeds else { return false }
                        return breeds.contains { breed in
                            (breed.name.localizedCaseInsensitiveContains(lower))
                            || (breed.origin?.localizedCaseInsensitiveContains(lower) ?? false)
                            || (breed.temperament?.localizedCaseInsensitiveContains(lower) ?? false)
                        }
                    }
                }
                return .none
                
            case .selectCat(let id):
                guard let cat = state.cats.first(where: { $0.id == id }) else { return .none }
                state.selectedCat = CatDetailFeature.State(
                    uuid: cat.uuID,
                    id: cat.id ?? UUID().uuidString,
                    url: cat.url,
                    breeds: cat.breeds,
                    isFavorite: state.favorites.contains(cat.id ?? "")
                )
                return .none
                
            case .selectedCat(.presented(.toggleFavorite)):
                if let id = state.selectedCat?.id {
                    return .send(.toggleFavorite(id: id))
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

// MARK: - Helper Action para atualizar batch de favoritos
extension CatListFeature.Action {
    static func toggleFavoriteBatch(_ ids: Set<String>) -> Self {
        .toggleFavoriteBatch(ids)
    }
}
