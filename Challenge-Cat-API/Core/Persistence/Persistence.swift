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

    private func breedEntity(for breed: CatBreed, context: NSManagedObjectContext) -> BreedEntity {
            let request: NSFetchRequest<BreedEntity> = BreedEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", breed.id)
            request.fetchLimit = 1

            if let existing = try? context.fetch(request).first {
                return existing
            }

            let newBreed = BreedEntity(context: context)
            newBreed.id = breed.id
            newBreed.name = breed.name
            newBreed.origin = breed.origin
            newBreed.temperament = breed.temperament
            newBreed.descriptionText = breed.descriptionText
            newBreed.life_span = breed.life_span
            newBreed.wikipediaUrl = breed.wikipediaUrl
            newBreed.countryCode = breed.countryCode
            newBreed.weightImperial = breed.weight?.imperial
            newBreed.weightMetric = breed.weight?.metric
            return newBreed
        }

        func saveCats(_ cats: [Cat]) {
            let context = container.viewContext

            for cat in cats {
                let entity = CatEntity(context: context)
                entity.id = cat.id ?? UUID().uuidString
                entity.url = cat.url
                entity.width = Int64(cat.width ?? 0)
                entity.height = Int64(cat.height ?? 0)
                entity.uuID = cat.uuID

                if let breeds = cat.breeds {
                    for breed in breeds {
                        let breedEntity = breedEntity(for: breed, context: context)
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

