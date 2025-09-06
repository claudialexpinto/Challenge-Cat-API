//
//  Challenge_Cat_APITests.swift
//  Challenge-Cat-APITests
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//

import XCTest
import ComposableArchitecture
@testable import Challenge_Cat_API

final class CatListFeatureTests: XCTestCase {
    
    var apiClient: MockCatAPIClient!
    var persistence: MockPersistenceController!
    var scheduler: TestSchedulerOf<DispatchQueue>!

    lazy var breedSiamese: CatBreed = {
        CatBreed.mock(
            id: "siamese-id",
            name: "Siamese",
            origin: "Thailand",
            temperament: "Affectionate",
            description: "A friendly cat"
        )
    }()

    lazy var breedPersian: CatBreed = {
        CatBreed.mock(
            id: "persian-id",
            name: "Persian",
            origin: "Iran",
            temperament: "Calm",
            description: "A fluffy cat"
        )
    }()

    lazy var cat1: Cat = {
        Cat(
            id: "1",
            url: "url1",
            width: 100,
            height: 100,
            breeds: [breedSiamese],
            uuID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        )
    }()

    lazy var cat2: Cat = {
        Cat(
            id: "2",
            url: "url2",
            width: 120,
            height: 120,
            breeds: [breedPersian],
            uuID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        )
    }()

    
    override func setUp() {
        super.setUp()
        apiClient = MockCatAPIClient()
        persistence = MockPersistenceController()
        scheduler = DispatchQueue.test
    }
    
    func testOnAppearLoadsCats() async {
        let sampleCats = [cat1, cat2]
        apiClient.fetchCatsResult = .success(sampleCats)
        persistence.setFavoriteCats([cat1])
        
        let store = TestStore(
            initialState: CatListFeature.State(),
            reducer: {
                CatListFeature(
                    environment: .init(
                        apiClient: apiClient,
                        persistenceController: persistence,
                        mainQueue: scheduler.eraseToAnyScheduler(),
                        pageSize: 10
                    )
                ).body
            }
        )

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.hasLoaded = true
            $0.cats = []
            $0.favorites = Set([self.cat1.id ?? ""])
        }

        await scheduler.advance()

        await store.receive(.catsResponse(sampleCats)) {
            $0.isLoading = false
            let favorites = $0.favorites
            $0.cats = sampleCats.map { cat in
                var c = cat
                if let id = cat.id {
                    c.isFavorite = favorites.contains(id)
                }
                return c
            }
            $0.currentPage = 2
            $0.canLoadMore = true
        }

    }

    
    func testToggleFavoriteAddsAndRemoves() async {
        let cat = Cat(
            id: "1",
            url: "url",
            width: 100,
            height: 100,
            breeds: nil,
            isFavorite: false,
            uuID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        )
        
        persistence.saveCats([cat])
        
        let store = TestStore(
            initialState: CatListFeature.State(),
            reducer: {
                CatListFeature(
                    environment: .init(
                        apiClient: apiClient,
                        persistenceController: persistence,
                        mainQueue: scheduler.eraseToAnyScheduler(),
                        pageSize: 10
                    )
                ).body
            }
        )
        
        await store.send(.toggleFavorite(id: cat.id ?? "")) {
            $0.favorites = [cat.id ?? ""]
        }
        
        XCTAssertTrue(persistence.favoriteCats.contains(where: { $0.id == cat.id }))
        
        await store.send(.toggleFavorite(id: cat.id ?? "")) {
            $0.favorites = []
        }
        
        XCTAssertFalse(persistence.favoriteCats.contains(where: { $0.id == cat.id }))
    }
    
    func testSearchTextFiltersCats() async {
        let sampleCats = [cat1, cat2]
        apiClient.fetchCatsResult = .success(sampleCats)
        persistence.setFavoriteCats([cat1])

        let store = TestStore(
            initialState: CatListFeature.State(),
            reducer: {
                CatListFeature(
                    environment: .init(
                        apiClient: apiClient,
                        persistenceController: persistence,
                        mainQueue: scheduler.eraseToAnyScheduler(),
                        pageSize: 10
                    )
                ).body
            }
        )

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.hasLoaded = true
            $0.cats = []
            $0.favorites = Set([self.cat1.id ?? ""])
        }

        await scheduler.advance()

        await store.receive(.catsResponse(sampleCats)) {
            $0.isLoading = false
            $0.cats = sampleCats.map { cat in
                var c = cat
                c.isFavorite = store.state.favorites.contains(cat.id ?? "")
                return c
            }
            $0.currentPage = 2
            $0.canLoadMore = true
        }

        await store.send(.searchTextChanged("Siamese")) {
            $0.searchText = "Siamese"
            $0.cats = $0.cats.filter { $0.breeds?.contains(where: { $0.name == "Siamese" }) ?? false }
        }

        XCTAssertEqual(store.state.cats.count, 1)
        XCTAssertEqual(store.state.cats.first?.breeds?.first?.name, "Siamese")
    }


}


struct MockCatAPIClient: CatAPIClientProtocol {
    var fetchCatsResult: Result<[Cat], Error> = .success([])
    
    func fetchCats(page: Int, limit: Int) async throws -> [Cat] {
        switch fetchCatsResult {
        case .success(let cats):
            return cats
        case .failure(let error):
            throw error
        }
    }
}

class MockPersistenceController: PersistenceControllerProtocol {
    private(set) var savedCats: [Cat] = []
    private(set) var favoriteCats: [Cat] = []
    
    func setFavoriteCats(_ cats: [Cat]) {
           favoriteCats = cats
       }
    
    func saveCats(_ cats: [Cat]) {
        savedCats.append(contentsOf: cats)
    }
    
    func fetchCats() -> [Cat] {
        return savedCats.map { cat in
                    var c = cat
                    if favoriteCats.contains(where: { $0.uuID == cat.uuID }) {
                        c.isFavorite = true
                    }
                    return c
                }
    }
    
    func fetchFavoriteCats() -> [Cat] { favoriteCats }
    
    func toggleFavorite(catID : String) {
        if let index = favoriteCats.firstIndex(where: { $0.id == catID }) {
            favoriteCats.remove(at: index)
        } else if let cat = savedCats.first(where: { $0.id == catID }) {
            favoriteCats.append(cat)
        }
    }
    
    func saveContext() {}
}

extension CatBreed {
    static func mock(
        id: String = UUID().uuidString,
        name: String,
        origin: String? = nil,
        temperament: String? = nil,
        description: String? = nil,
        life_span: String? = nil,
        wikipediaUrl: String? = nil,
        countryCode: String? = nil,
        weight: CatBreedWeight? = nil
    ) -> CatBreed {
        CatBreed(
            id: id,
            name: name,
            origin: origin,
            temperament: temperament,
            description: description,
            life_span: life_span,
            wikipediaUrl: wikipediaUrl,
            countryCode: countryCode,
            weight: weight
        )
    }
}
