//
//  BreedEntity+CoreDataProperties.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 03/09/2025.
//
//

import Foundation
import CoreData


extension BreedEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BreedEntity> {
        return NSFetchRequest<BreedEntity>(entityName: "BreedEntity")
    }

    @NSManaged public var descriptionText: String?
    @NSManaged public var id: String?
    @NSManaged public var lifeSpan: String?
    @NSManaged public var name: String?
    @NSManaged public var origin: String?
    @NSManaged public var temperament: String?
    @NSManaged public var wikipediaUrl: String?
    @NSManaged public var countryCode: String?
    @NSManaged public var weightImperial: String?
    @NSManaged public var weightMetric: String?
    @NSManaged public var images: NSSet?

}

// MARK: Generated accessors for images
extension BreedEntity {

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: CatEntity)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: CatEntity)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSSet)

}

extension BreedEntity : Identifiable {

}
