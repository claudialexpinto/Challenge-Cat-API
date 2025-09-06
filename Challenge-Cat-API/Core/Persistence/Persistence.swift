//
//  Persistence.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//

import CoreData

public protocol PersistenceControllerProtocol {
    func saveCats(_ cats: [Cat])
    func fetchCats() -> [Cat]
    func saveContext()
    func fetchFavoriteCats() -> [Cat]
    func toggleFavorite(catID: String)
}

final class PersistenceController: PersistenceControllerProtocol {
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
        if context.hasChanges {
            try? context.save()
        }
    }
    
    func fetchCats() -> [Cat] {
        let request: NSFetchRequest<CatEntity> = CatEntity.fetchRequest()
        let entities = (try? context.fetch(request)) ?? []
        return entities.map { entity in
            var cat = Cat(entity: entity)
            cat.breeds = entity.breed?.compactMap { ($0 as? BreedEntity).map { breed in
                CatBreed(
                    id: breed.id!,
                    name: breed.name ?? "",
                    origin: breed.origin,
                    temperament: breed.temperament,
                    description: breed.descriptionText,
                    life_span: breed.life_span,
                    wikipediaUrl: breed.wikipediaUrl,
                    countryCode: breed.countryCode,
                    weight: CatBreedWeight(imperial: breed.weightImperial, metric: breed.weightMetric)
                )
            }}
            return cat
        }
    }

    
    func fetchFavoriteCats() -> [Cat] {
        let request: NSFetchRequest<CatEntity> = CatEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == true")
        let entities = (try? context.fetch(request)) ?? []
        return entities.map { Cat(entity: $0) }
    }
    
    func saveCats(_ cats: [Cat]) {
        for cat in cats {
            guard let apiID = cat.id else { continue }
            
            let request: NSFetchRequest<CatEntity> = CatEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", apiID)
            
            let entity: CatEntity
            if let existing = try? context.fetch(request).first {
                entity = existing
            } else {
                entity = CatEntity(context: context)
                entity.uuID = UUID()
            }
            
            entity.id = apiID
            entity.url = cat.url
            entity.width = Int64(cat.width ?? 0)
            entity.height = Int64(cat.height ?? 0)
            
            if entity.isFavorite == false {
                entity.isFavorite = cat.isFavorite
            }
            
            entity.removeFromBreed(entity.breed ?? NSSet())
            if let breeds = cat.breeds {
                for breed in breeds {
                    let breedEntity = breedEntity(for: breed, context: context)
                    entity.addToBreed(breedEntity)
                }
            }
        }
        
        saveContext()
    }
    
    func toggleFavorite(catID: String) {
        let request: NSFetchRequest<CatEntity> = CatEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", catID)
        
        if let cat = try? context.fetch(request).first {
            cat.isFavorite.toggle()
            saveContext()
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
}
