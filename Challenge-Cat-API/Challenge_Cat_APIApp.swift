//
//  Challenge_Cat_APIApp.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//

import SwiftUI
import ComposableArchitecture

@main
struct Challenge_Cat_APIApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView(
                store: Store(
                    initialState: CatListFeature.State(),
                    reducer: { CatListFeature(environment: .init(
                        apiClient: CatAPIClient(),
                        persistenceController: PersistenceController.shared,
                        mainQueue: .main
                    )) }
                )
            )
            .accentColor(Color.teal) 
        }
    }
}
