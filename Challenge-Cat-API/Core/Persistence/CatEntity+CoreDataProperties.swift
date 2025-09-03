//
//  CatEntity+CoreDataProperties.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//
//

import Foundation
import CoreData


extension CatEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CatEntity> {
        return NSFetchRequest<CatEntity>(entityName: "CatEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var url: String?
    @NSManaged public var breed: BreedEntity?

}

extension CatEntity : Identifiable {

}
