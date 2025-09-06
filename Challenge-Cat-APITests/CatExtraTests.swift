//
//  CatExtraTests.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 06/09/2025.
//

import XCTest
import ComposableArchitecture
@testable import Challenge_Cat_API

final class CatExtraTests: XCTestCase {
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

    func testFetchCatsEmptyResponse() async {
        apiClient.fetchCatsResult = .success([])

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

        await store.send(.onAppear) { state in
            state.isLoading = true
            state.hasLoaded = true
        }

        await scheduler.advance()

        await store.receive(.catsResponse([])) { state in
            state.isLoading = false
            state.cats = []
            state.currentPage = 2
            state.canLoadMore = false
        }
    }

    func testSearchTextNoResults() async {
        let sampleCats = [cat1, cat2]
        apiClient.fetchCatsResult = .success(sampleCats)
        persistence.setFavoriteCats([])

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

        await store.send(.searchTextChanged("NoMatch")) { state in
            state.searchText = "NoMatch"
            state.cats = []
            state.currentPage = 1
            state.isLoading = false
            state.canLoadMore = true
            state.hasLoaded = false
        }

        XCTAssertNoDifference(store.state.cats, [])
    }

   /* func testPaginationIncrementsPage() async {
        let sampleCatsPage1 = [cat1, cat2]
        let cat3 = Cat(
            id: "3",
            url: "url3",
            width: 130,
            height: 130,
            breeds: [breedSiamese],
            uuID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        )
        let sampleCatsPage2 = [cat3]

        apiClient.fetchCatsResult = .success(sampleCatsPage1)
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

        await store.send(.onAppear) { state in
            state.isLoading = true
            state.hasLoaded = true
            state.favorites = Set([self.cat1.id ?? ""])
        }

        await scheduler.advance()

        await store.receive(.catsResponse(sampleCatsPage1)) { state in
            state.isLoading = false
            state.currentPage = 2
            state.cats = sampleCatsPage1
            state.canLoadMore = true
        }

        apiClient.fetchCatsResult = .success(sampleCatsPage2)
        await store.send(.loadMore) { state in
            state.isLoadingMore = true
        }

        await scheduler.advance()

        await store.receive(.catsResponse(sampleCatsPage2)) { state in
            state.isLoadingMore = false
            state.currentPage = 3
            state.cats += sampleCatsPage2
            state.canLoadMore = true
        }
    }


    func testFetchCatsFailure() async {
        enum TestError: Error { case fail }
        apiClient.fetchCatsResult = .failure(TestError.fail)

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

        await store.send(.onAppear) { state in
            state.isLoading = true
            state.hasLoaded = true
        }

        await scheduler.advance()

        await store.receive({ action in
            if case .failedToLoad = action { return true }
            return false
        }) { state in
            state.isLoading = false
            XCTAssertNotNil(state.alert)
        }
    }*/

}
