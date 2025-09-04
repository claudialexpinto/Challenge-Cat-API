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
    
    public let uuID: UUID
    
    public var displayID: UUID { uuID }
    
    enum CodingKeys: String, CodingKey {
        case id, url, width, height, breeds
    }
}


extension Cat {
    // customised init to generate UUID
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        breeds = try container.decodeIfPresent([CatBreed].self, forKey: .breeds)
        uuID = UUID()
    }
    
    // Manual init for CoreData
    init(entity: CatEntity) {
        self.id = entity.id ?? UUID().uuidString
        self.url = entity.url ?? ""
        self.width = Int(entity.width)
        self.height = Int(entity.height)
        self.uuID = entity.uuID ?? UUID()
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
    let life_span: String?
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
        self.life_span = entity.life_span
        self.wikipediaUrl = entity.wikipediaUrl
        self.countryCode = entity.countryCode
        self.weight = CatBreedWeight(imperial: entity.weightImperial, metric: entity.weightMetric)
    }
}
