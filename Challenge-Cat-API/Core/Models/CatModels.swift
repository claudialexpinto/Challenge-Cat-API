//
//  CatModels.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//

import Foundation

public struct Cat: Identifiable, Equatable, Decodable {
    public let id: String?
    public let url: String?
    public let width: Int?
    public let height: Int?
    public let breeds: [CatBreed]?
    public let uiID = UUID()
    public var displayID: UUID { uiID }
}

extension Cat {
    init(entity: CatEntity) {
        self.id = entity.id ?? UUID().uuidString
        self.url = entity.url ?? ""
        self.width = Int(entity.width)
        self.height = Int(entity.height)
        
        if let breedEntities = entity.breed as? Set<BreedEntity> {
            self.breeds = breedEntities.map { CatBreed(entity: $0) }
        } else {
            self.breeds = []
        }
    }
}

public struct CatBreed: Identifiable, Equatable, Decodable {
    public let id: String
    public let name: String
    let origin: String?
    let temperament: String?
    let descriptionText: String?
    let lifeSpan: String?
    let wikipediaUrl: String?
    let countryCode: String?
    let weight: CatBreedWeight?
}

public struct CatBreedWeight: Equatable, Decodable {
    let imperial: String?
    let metric: String?
}

extension CatBreed {
    init(entity: BreedEntity) {
        self.id = entity.id ?? ""
        self.name = entity.name ?? ""
        self.origin = entity.origin
        self.temperament = entity.temperament
        self.descriptionText = entity.descriptionText
        self.lifeSpan = entity.lifeSpan
        self.wikipediaUrl = entity.wikipediaUrl
        self.countryCode = entity.countryCode
        self.weight = CatBreedWeight(imperial: entity.weightImperial, metric: entity.weightMetric)
    }
}
