//
//  Persistence.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    var context: NSManagedObjectContext { container.viewContext }
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Challenge_Cat_API")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { desc, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
    }
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

}


extension PersistenceController {
    
    func fetchCats() -> [Cat] {
        let context = container.viewContext
        let request: NSFetchRequest<CatEntity> = CatEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CatEntity.id, ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            return entities.map { Cat(entity: $0) }
        } catch {
            print("❌ Failed to fetch cats: \(error)")
            return []
        }
    }

    
    func saveCats(_ cats: [Cat]) {
        let context = container.viewContext

        for cat in cats {
            let entity = CatEntity(context: context)
            entity.id = cat.id ?? UUID().uuidString
            entity.url = cat.url
            entity.width = Int64(cat.width ?? 0)
            entity.height = Int64(cat.height ?? 0)

            if let breeds = cat.breeds {
                for breed in breeds {
                    let breedEntity = BreedEntity(context: context)
                    breedEntity.id = breed.id
                    breedEntity.name = breed.name
                    breedEntity.origin = breed.origin
                    breedEntity.temperament = breed.temperament
                    breedEntity.descriptionText = breed.descriptionText
                    breedEntity.lifeSpan = breed.lifeSpan
                    breedEntity.wikipediaUrl = breed.wikipediaUrl
                    breedEntity.countryCode = breed.countryCode
                    breedEntity.weightImperial = breed.weight?.imperial
                    breedEntity.weightMetric = breed.weight?.metric

                    entity.addToBreed(breedEntity)
                }
            }
        }

        do {
            try context.save()
        } catch {
            print("❌ Failed to save cats: \(error)")
        }
    }
}

