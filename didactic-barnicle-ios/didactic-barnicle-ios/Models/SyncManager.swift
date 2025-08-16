import Foundation
import CoreData
import Combine

enum SyncAction: String {
    case create = "create"
    case update = "update"
    case delete = "delete"
}

enum SyncStatus: String {
    case pending = "pending"
    case syncing = "syncing"
    case completed = "completed"
    case failed = "failed"
}

class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncErrors: [String] = []
    
    private let persistenceController = PersistenceController.shared
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 30
    private let maxRetryCount = 3
    
    init() {
        startAutoSync()
        loadLastSyncDate()
    }
    
    private func startAutoSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { _ in
            Task {
                await self.syncIfNeeded()
            }
        }
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
    }
    
    func syncIfNeeded() async {
        guard !isSyncing else { return }
        
        await MainActor.run {
            self.isSyncing = true
        }
        
        do {
            await processSyncQueue()
            await pullRemoteChanges()
            await pushLocalChanges()
            
            await MainActor.run {
                self.lastSyncDate = Date()
                self.saveLastSyncDate()
                self.isSyncing = false
            }
        } catch {
            await MainActor.run {
                self.syncErrors.append(error.localizedDescription)
                self.isSyncing = false
            }
        }
    }
    
    private func processSyncQueue() async {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CDSyncQueue")
        fetchRequest.predicate = NSPredicate(format: "status == %@", SyncStatus.pending.rawValue)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            let queueItems = try context.fetch(fetchRequest)
            
            for item in queueItems {
                guard let entityType = item.value(forKey: "entityType") as? String,
                      let entityId = item.value(forKey: "entityId") as? UUID,
                      let action = item.value(forKey: "action") as? String else {
                    continue
                }
                
                let retryCount = item.value(forKey: "retryCount") as? Int32 ?? 0
                
                if retryCount >= maxRetryCount {
                    item.setValue(SyncStatus.failed.rawValue, forKey: "status")
                    continue
                }
                
                item.setValue(SyncStatus.syncing.rawValue, forKey: "status")
                item.setValue(Date(), forKey: "lastAttempt")
                
                let success = await performSyncAction(
                    entityType: entityType,
                    entityId: entityId,
                    action: SyncAction(rawValue: action) ?? .create,
                    payload: item.value(forKey: "payload") as? Data
                )
                
                if success {
                    context.delete(item)
                } else {
                    item.setValue(SyncStatus.pending.rawValue, forKey: "status")
                    item.setValue(retryCount + 1, forKey: "retryCount")
                }
            }
            
            try context.save()
        } catch {
            print("Error processing sync queue: \(error)")
        }
    }
    
    private func performSyncAction(entityType: String, entityId: UUID, action: SyncAction, payload: Data?) async -> Bool {
        return true
    }
    
    private func pullRemoteChanges() async {
        
    }
    
    private func pushLocalChanges() async {
        let context = persistenceController.container.viewContext
        
        let treasureFetch: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CDTreasure")
        treasureFetch.predicate = NSPredicate(format: "needsSync == YES")
        
        let discoveryFetch: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CDDiscovery")
        discoveryFetch.predicate = NSPredicate(format: "needsSync == YES")
        
        do {
            let treasures = try context.fetch(treasureFetch)
            let discoveries = try context.fetch(discoveryFetch)
            
            for treasure in treasures {
                await syncTreasure(treasure)
            }
            
            for discovery in discoveries {
                await syncDiscovery(discovery)
            }
            
            try context.save()
        } catch {
            print("Error pushing local changes: \(error)")
        }
    }
    
    private func syncTreasure(_ treasure: NSManagedObject) async {
        treasure.setValue(false, forKey: "needsSync")
        treasure.setValue(Date(), forKey: "lastSyncDate")
    }
    
    private func syncDiscovery(_ discovery: NSManagedObject) async {
        discovery.setValue(false, forKey: "needsSync")
        discovery.setValue(Date(), forKey: "lastSyncDate")
    }
    
    func addToSyncQueue(entityType: String, entityId: UUID, action: SyncAction, payload: Data? = nil) {
        let context = persistenceController.container.viewContext
        
        let queueItem = NSEntityDescription.insertNewObject(forEntityName: "CDSyncQueue", into: context)
        queueItem.setValue(UUID(), forKey: "id")
        queueItem.setValue(entityType, forKey: "entityType")
        queueItem.setValue(entityId, forKey: "entityId")
        queueItem.setValue(action.rawValue, forKey: "action")
        queueItem.setValue(payload, forKey: "payload")
        queueItem.setValue(Date(), forKey: "createdAt")
        queueItem.setValue(0, forKey: "retryCount")
        queueItem.setValue(SyncStatus.pending.rawValue, forKey: "status")
        
        do {
            try context.save()
        } catch {
            print("Error adding to sync queue: \(error)")
        }
    }
    
    func resolveConflict(local: NSManagedObject, remote: [String: Any]) -> NSManagedObject {
        guard let localUpdated = local.value(forKey: "lastSyncDate") as? Date,
              let remoteUpdated = remote["updated_at"] as? Date else {
            return local
        }
        
        if remoteUpdated > localUpdated {
            for (key, value) in remote {
                if local.entity.attributesByName.keys.contains(key) {
                    local.setValue(value, forKey: key)
                }
            }
        }
        
        return local
    }
    
    deinit {
        syncTimer?.invalidate()
    }
}