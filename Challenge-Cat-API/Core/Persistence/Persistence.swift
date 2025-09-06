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
            
            return entities.map { entity in
                var cat = Cat(
                    id: entity.id,
                    url: entity.url,
                    width: Int(entity.width),
                    height: Int(entity.height),
                    breeds: [],
                    uuID: entity.uuID ?? UUID()
                )
                
                if let breedEntities = entity.breed as? Set<BreedEntity> {
                    cat.breeds = breedEntities.map { CatBreed(entity: $0) }
                } else {
                    cat.breeds = []
                }
                
                return cat
            }
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
            let request: NSFetchRequest<CatEntity> = CatEntity.fetchRequest()
            request.predicate = NSPredicate(format: "uuID == %@", cat.uuID as CVarArg)
            let entity: CatEntity
            if let existing = try? context.fetch(request).first {
                entity = existing
            } else {
                entity = CatEntity(context: context)
            }

            entity.id = cat.id ?? UUID().uuidString
            entity.url = cat.url
            entity.width = Int64(cat.width ?? 0)
            entity.height = Int64(cat.height ?? 0)
            entity.uuID = cat.uuID

            // Atualizar breeds
            entity.removeFromBreed(entity.breed ?? NSSet())
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
    
    func toggleFavorite(catUUID: UUID) {
        let context = container.viewContext
        let request: NSFetchRequest<CatEntity> = CatEntity.fetchRequest()
        request.predicate = NSPredicate(format: "uuID == %@", catUUID as CVarArg)
        if let cat = try? context.fetch(request).first {
            cat.isFavorite.toggle()
            try? context.save()
        }
    }
    
    func fetchFavoriteCats() -> [Cat] {
        let context = container.viewContext
        let request: NSFetchRequest<CatEntity> = CatEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == true")
        let entities = (try? context.fetch(request)) ?? []
        return entities.map { Cat(entity: $0) }
    }


}
