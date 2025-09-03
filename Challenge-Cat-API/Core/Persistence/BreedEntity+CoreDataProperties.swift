//
//  BreedEntity+CoreDataProperties.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//
//

import Foundation
import CoreData


extension BreedEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BreedEntity> {
        return NSFetchRequest<BreedEntity>(entityName: "BreedEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var origin: String?
    @NSManaged public var temperament: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var lifeSpan: String?
    @NSManaged public var wikipediaUrl: String?
    @NSManaged public var images: CatEntity?

}

extension BreedEntity : Identifiable {

}
