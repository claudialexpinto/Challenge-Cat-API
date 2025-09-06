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
        public var favorites: Set<UUID> = []

        public var currentPage: Int = 1
        public var isLoading: Bool = false
        public var canLoadMore: Bool = true
        public var isLoadingMore: Bool = false
        public var pageSize: Int = 10
        
        @PresentationState public var alert: AlertState<Action>?
        @PresentationState public var selectedCat: CatDetailFeature.State?
        
        public var searchText: String = ""
        
        public init() {}
    }
    
    // MARK: - Action
    public enum Action: Equatable {
        case onAppear
        case loadMore
        
        case catsResponse([Cat])
        case retryLoad
        case failedToLoad(String)
        case errorDismissed
        
        case toggleFavorite(id: UUID)
        
        case alert(PresentationAction<CatListFeature.Action>)
        
        case selectCat(UUID)
        case selectedCat(PresentationAction<CatDetailFeature.Action>)
        
        case searchTextChanged(String)
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
                state.cats = environment.persistenceController.fetchCats()
                state.isLoading = true
                state.favorites = Set(environment.persistenceController.fetchFavoriteCats().map { $0.uuID })

                
                let page = state.currentPage
                let api = environment.apiClient
                let persistence = environment.persistenceController
                let limit = environment.pageSize
                
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
                let limit = environment.pageSize

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
                
                if state.currentPage == 1 {
                    state.cats = cats
                } else {
                    state.cats.append(contentsOf: cats)
                }
                
                state.currentPage += 1
                state.canLoadMore = !cats.isEmpty
                return .none
                
            case .retryLoad:
                state.currentPage = 1
                    state.isLoading = true
                    let api = environment.apiClient
                    let persistence = environment.persistenceController
                    let limit = environment.pageSize
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
                environment.persistenceController.toggleFavorite(catUUID: catID)
                state.favorites = Set(environment.persistenceController.fetchFavoriteCats().map { $0.uuID })
                if var selected = state.selectedCat, selected.id == catID {
                    selected.isFavorite.toggle()
                    state.selectedCat = selected
                }
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
                guard let cat = state.cats.first(where: { $0.uuID == id }) else { return .none }
                state.selectedCat = CatDetailFeature.State(
                    id: cat.uuID,
                    url: cat.url,
                    breeds: cat.breeds,
                    isFavorite: state.favorites.contains(cat.uuID)
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
