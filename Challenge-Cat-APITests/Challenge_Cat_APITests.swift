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
        let sampleCats = [
            cat1, cat2
        ]
        apiClient.fetchCatsResult = .success(sampleCats)
        
        let store = TestStore(
            initialState: CatListFeature.State(),
            reducer: {
                CatListFeature(
                    environment: .init(
                        apiClient: apiClient,
                        persistenceController: persistence,
                        mainQueue: scheduler.eraseToAnyScheduler()
                    )
                ).body
            }
        )
        
        await store.send(.onAppear) {
            $0.isLoading = true
            $0.cats = []
            $0.favorites = []
        }
        
        await store.receive(.catsResponse(sampleCats)) {
            $0.isLoading = false
            $0.cats = sampleCats
            $0.currentPage = 2
            $0.canLoadMore = true
        }
    }
    
    func testToggleFavoriteAddsAndRemoves() async {
        let cat = Cat(
            id: nil,
            url: "url",
            width: nil,
            height: nil,
            breeds: nil,
            isFavorite: false,
            uuID: UUID()
        )
        
        persistence.saveCats([cat])
        
        let store = TestStore(
            initialState: CatListFeature.State(),
            reducer: {
                CatListFeature(
                    environment: .init(
                        apiClient: apiClient,
                        persistenceController: persistence,
                        mainQueue: scheduler.eraseToAnyScheduler()
                    )
                ).body
            }
        )
        
        await store.send(.toggleFavorite(id: cat.uuID)) {
            $0.favorites = [cat.uuID]
        }
        
        await store.send(.toggleFavorite(id: cat.uuID)) {
            $0.favorites = []
        }
    }
    
    // Teste atualizado
    func testSearchTextFiltersCats() async {
        // Configurar o mock API para retornar os cats
        let fetchedCats = [cat1, cat2]
        apiClient.fetchCatsResult = .success(fetchedCats)

        let store = TestStore(
            initialState: CatListFeature.State(),
            reducer: {
                CatListFeature(
                    environment: .init(
                        apiClient: apiClient,
                        persistenceController: persistence,
                        mainQueue: scheduler.eraseToAnyScheduler()
                    )
                ).body
            }
        )

        // onAppear vai buscar do persistence (vazio neste caso)
        await store.send(.onAppear) {
            $0.isLoading = true
            $0.cats = [] // persistence vazio
            $0.favorites = []
        }

        // Avançar o scheduler para o efeito assíncrono
        await scheduler.advance()

        // Receber a ação do API mock
        await store.receive(.catsResponse(fetchedCats)) {
            $0.isLoading = false
            $0.cats = fetchedCats
            $0.currentPage = 2
            $0.canLoadMore = true
        }

        // Testar filtragem
        await store.send(.searchTextChanged("Siamese")) {
            $0.searchText = "Siamese"
            $0.cats = [fetchedCats[0]] // usa exatamente o objeto que veio da API
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
    
    func saveCats(_ cats: [Cat]) {
        savedCats.append(contentsOf: cats)
    }
    
    func fetchCats() -> [Cat] { savedCats }
    
    func fetchFavoriteCats() -> [Cat] { favoriteCats }
    
    func toggleFavorite(catUUID: UUID) {
        if let index = favoriteCats.firstIndex(where: { $0.uuID == catUUID }) {
            favoriteCats.remove(at: index)
        } else if let cat = savedCats.first(where: { $0.uuID == catUUID }) {
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
