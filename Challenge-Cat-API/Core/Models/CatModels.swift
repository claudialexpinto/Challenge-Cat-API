//
//  CatModels.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//

import Foundation

public struct Cat: Identifiable, Equatable, Decodable {
    public let id: String?
    let url: String?
    let breed: CatBreed?
}

extension Cat {
    init(entity: CatEntity) {
        self.id = entity.id ?? ""
        self.url = entity.url ?? ""
        self.breed = nil 
    }
}

public struct CatBreed: Identifiable, Equatable, Decodable {
    public let id: String?
    let  name: String?
    let  origin: String?
    let  temperament: String?
    let  descriptionText: String?
    let  lifeSpan: String?
    let  wikipediaUrl: String?
}
