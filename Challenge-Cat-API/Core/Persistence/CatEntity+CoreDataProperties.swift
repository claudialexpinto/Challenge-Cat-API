//
//  CatEntity+CoreDataProperties.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 04/09/2025.
//
//

import Foundation
import CoreData


extension CatEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CatEntity> {
        return NSFetchRequest<CatEntity>(entityName: "CatEntity")
    }

    @NSManaged public var height: Int64
    @NSManaged public var id: String?
    @NSManaged public var url: String?
    @NSManaged public var width: Int64
    @NSManaged public var uuID: UUID?
    @NSManaged public var breed: NSSet?

}

// MARK: Generated accessors for breed
extension CatEntity {

    @objc(addBreedObject:)
    @NSManaged public func addToBreed(_ value: BreedEntity)

    @objc(removeBreedObject:)
    @NSManaged public func removeFromBreed(_ value: BreedEntity)

    @objc(addBreed:)
    @NSManaged public func addToBreed(_ values: NSSet)

    @objc(removeBreed:)
    @NSManaged public func removeFromBreed(_ values: NSSet)

}

extension CatEntity : Identifiable {

}
