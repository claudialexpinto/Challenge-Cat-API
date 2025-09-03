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
        container = NSPersistentContainer(name: "Challenge-Cat-API")
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
            return try context.fetch(request).map(Cat.init(entity:))
        } catch {
            print("❌ Failed to fetch cats: \(error)")
            return []
        }
    }
    
    func saveCats(_ cats: [Cat]) {
        let context = container.viewContext
        
        for cat in cats {
            let request: NSFetchRequest<CatEntity> = CatEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", cat.id ?? "")
            
            if let existing = try? context.fetch(request).first {
                // Atualiza
                existing.url = cat.url
            } else {
                // Cria novo
                let entity = CatEntity(context: context)
                entity.id = cat.id ?? UUID().uuidString
                entity.url = cat.url
            }
        }
        
        do {
            try context.save()
        } catch {
            print("❌ Failed to save cats: \(error)")
        }
    }
}

