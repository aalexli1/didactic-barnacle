import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TreasureHunt")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError.localizedDescription)")
            }
        }
    }
    
    func deleteAll() {
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDUser")
        let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        
        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDTreasure")
        let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        
        let fetchRequest3: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDDiscovery")
        let deleteRequest3 = NSBatchDeleteRequest(fetchRequest: fetchRequest3)
        
        let fetchRequest4: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDSyncQueue")
        let deleteRequest4 = NSBatchDeleteRequest(fetchRequest: fetchRequest4)
        
        do {
            try container.viewContext.execute(deleteRequest1)
            try container.viewContext.execute(deleteRequest2)
            try container.viewContext.execute(deleteRequest3)
            try container.viewContext.execute(deleteRequest4)
            try container.viewContext.save()
        } catch {
            print("Error deleting all data: \(error)")
        }
    }
}

extension PersistenceController {
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        for i in 0..<5 {
            let newTreasure = NSEntityDescription.insertNewObject(forEntityName: "CDTreasure", into: viewContext)
            newTreasure.setValue(UUID(), forKey: "id")
            newTreasure.setValue("Sample Treasure \(i)", forKey: "title")
            newTreasure.setValue(UUID(), forKey: "creatorId")
            newTreasure.setValue(37.7749 + Double(i) * 0.01, forKey: "latitude")
            newTreasure.setValue(-122.4194 + Double(i) * 0.01, forKey: "longitude")
            newTreasure.setValue(Date(), forKey: "createdAt")
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
}