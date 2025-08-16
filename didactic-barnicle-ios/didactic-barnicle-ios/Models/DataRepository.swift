import Foundation
import CoreData
import Combine
import CoreLocation

class DataRepository: ObservableObject {
    static let shared = DataRepository()
    
    private let persistenceController = PersistenceController.shared
    private let syncManager = SyncManager.shared
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    @Published var currentUser: User?
    @Published var nearbyTreasures: [Treasure] = []
    @Published var userDiscoveries: [Discovery] = []
    
    private init() {}
    
    func saveUser(_ user: User) async throws {
        let cdUser = NSEntityDescription.insertNewObject(forEntityName: "CDUser", into: context)
        updateCDUser(cdUser, from: user)
        
        try context.save()
        await syncManager.addToSyncQueue(
            entityType: "user",
            entityId: user.id,
            action: .create
        )
    }
    
    func updateUser(_ user: User) async throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CDUser")
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
        
        let results = try context.fetch(fetchRequest)
        guard let cdUser = results.first else {
            throw DataError.notFound
        }
        
        updateCDUser(cdUser, from: user)
        cdUser.setValue(true, forKey: "needsSync")
        
        try context.save()
        await syncManager.addToSyncQueue(
            entityType: "user",
            entityId: user.id,
            action: .update
        )
    }
    
    func fetchUser(by id: UUID) async throws -> User? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CDUser")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let results = try context.fetch(fetchRequest)
        guard let cdUser = results.first else {
            return nil
        }
        
        return userFromCoreData(cdUser)
    }
    
    func saveTreasure(_ treasure: Treasure) async throws {
        let cdTreasure = NSEntityDescription.insertNewObject(forEntityName: "CDTreasure", into: context)
        updateCDTreasure(cdTreasure, from: treasure)
        
        try context.save()
        await syncManager.addToSyncQueue(
            entityType: "treasure",
            entityId: treasure.id,
            action: .create
        )
    }
    
    func fetchNearbyTreasures(location: CLLocation, radius: Double) async throws -> [Treasure] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CDTreasure")
        
        let minLat = location.coordinate.latitude - (radius / 111000.0)
        let maxLat = location.coordinate.latitude + (radius / 111000.0)
        let minLon = location.coordinate.longitude - (radius / (111000.0 * cos(location.coordinate.latitude * .pi / 180)))
        let maxLon = location.coordinate.longitude + (radius / (111000.0 * cos(location.coordinate.latitude * .pi / 180)))
        
        fetchRequest.predicate = NSPredicate(
            format: "latitude >= %f AND latitude <= %f AND longitude >= %f AND longitude <= %f AND isActive == YES",
            minLat, maxLat, minLon, maxLon
        )
        
        let results = try context.fetch(fetchRequest)
        var treasures: [Treasure] = []
        
        for cdTreasure in results {
            if let treasure = treasureFromCoreData(cdTreasure) {
                let treasureLocation = CLLocation(
                    latitude: treasure.location.latitude,
                    longitude: treasure.location.longitude
                )
                let distance = location.distance(from: treasureLocation)
                
                if distance <= radius {
                    treasures.append(treasure)
                }
            }
        }
        
        treasures.sort { t1, t2 in
            let loc1 = CLLocation(latitude: t1.location.latitude, longitude: t1.location.longitude)
            let loc2 = CLLocation(latitude: t2.location.latitude, longitude: t2.location.longitude)
            return location.distance(from: loc1) < location.distance(from: loc2)
        }
        
        return treasures
    }
    
    func saveDiscovery(_ discovery: Discovery) async throws {
        let cdDiscovery = NSEntityDescription.insertNewObject(forEntityName: "CDDiscovery", into: context)
        updateCDDiscovery(cdDiscovery, from: discovery)
        
        try context.save()
        await syncManager.addToSyncQueue(
            entityType: "discovery",
            entityId: discovery.id,
            action: .create
        )
    }
    
    func fetchUserDiscoveries(userId: UUID) async throws -> [Discovery] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CDDiscovery")
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "discoveredAt", ascending: false)]
        
        let results = try context.fetch(fetchRequest)
        return results.compactMap { discoveryFromCoreData($0) }
    }
    
    private func updateCDUser(_ cdUser: NSManagedObject, from user: User) {
        cdUser.setValue(user.id, forKey: "id")
        cdUser.setValue(user.username, forKey: "username")
        cdUser.setValue(user.email, forKey: "email")
        cdUser.setValue(user.avatarURL, forKey: "avatarURL")
        cdUser.setValue(user.level, forKey: "level")
        cdUser.setValue(user.experience, forKey: "experience")
        cdUser.setValue(user.joinedAt, forKey: "joinedAt")
        cdUser.setValue(user.treasuresCreated, forKey: "treasuresCreated")
        cdUser.setValue(user.treasuresFound, forKey: "treasuresFound")
        cdUser.setValue(user.points, forKey: "points")
        cdUser.setValue(user.bio, forKey: "bio")
        cdUser.setValue(user.isActive, forKey: "isActive")
        
        if let settingsData = try? JSONEncoder().encode(user.settings) {
            cdUser.setValue(settingsData, forKey: "settingsData")
        }
    }
    
    private func updateCDTreasure(_ cdTreasure: NSManagedObject, from treasure: Treasure) {
        cdTreasure.setValue(treasure.id, forKey: "id")
        cdTreasure.setValue(treasure.creatorId, forKey: "creatorId")
        cdTreasure.setValue(treasure.title, forKey: "title")
        cdTreasure.setValue(treasure.description, forKey: "treasureDescription")
        cdTreasure.setValue(treasure.message, forKey: "message")
        cdTreasure.setValue(treasure.location.latitude, forKey: "latitude")
        cdTreasure.setValue(treasure.location.longitude, forKey: "longitude")
        cdTreasure.setValue(treasure.altitude, forKey: "altitude")
        cdTreasure.setValue(treasure.arAnchorData, forKey: "arAnchorData")
        cdTreasure.setValue(treasure.type.rawValue, forKey: "type")
        cdTreasure.setValue(treasure.mediaURL, forKey: "mediaURL")
        cdTreasure.setValue(treasure.visibility.rawValue, forKey: "visibility")
        cdTreasure.setValue(treasure.difficulty.rawValue, forKey: "difficulty")
        cdTreasure.setValue(treasure.hint, forKey: "hint")
        cdTreasure.setValue(treasure.points, forKey: "points")
        cdTreasure.setValue(treasure.maxDiscoveries, forKey: "maxDiscoveries")
        cdTreasure.setValue(treasure.isActive, forKey: "isActive")
        cdTreasure.setValue(treasure.createdAt, forKey: "createdAt")
        cdTreasure.setValue(treasure.expiresAt, forKey: "expiresAt")
        
        if let arObjectData = try? JSONEncoder().encode(treasure.arObject) {
            cdTreasure.setValue(arObjectData, forKey: "arObjectData")
        }
    }
    
    private func updateCDDiscovery(_ cdDiscovery: NSManagedObject, from discovery: Discovery) {
        cdDiscovery.setValue(discovery.id, forKey: "id")
        cdDiscovery.setValue(discovery.treasureId, forKey: "treasureId")
        cdDiscovery.setValue(discovery.userId, forKey: "userId")
        cdDiscovery.setValue(discovery.discoveredAt, forKey: "discoveredAt")
        cdDiscovery.setValue(discovery.photoURL, forKey: "photoURL")
        cdDiscovery.setValue(discovery.comment, forKey: "comment")
        cdDiscovery.setValue(discovery.reactionType?.rawValue, forKey: "reactionType")
        cdDiscovery.setValue(discovery.pointsEarned, forKey: "pointsEarned")
        cdDiscovery.setValue(discovery.timeToFind, forKey: "timeToFind")
        cdDiscovery.setValue(discovery.distanceFromTreasure, forKey: "distanceFromTreasure")
    }
    
    private func userFromCoreData(_ cdUser: NSManagedObject) -> User? {
        guard let id = cdUser.value(forKey: "id") as? UUID,
              let username = cdUser.value(forKey: "username") as? String,
              let email = cdUser.value(forKey: "email") as? String else {
            return nil
        }
        
        var settings = UserSettings()
        if let settingsData = cdUser.value(forKey: "settingsData") as? Data,
           let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: settingsData) {
            settings = decodedSettings
        }
        
        return User(
            id: id,
            username: username,
            email: email,
            avatarURL: cdUser.value(forKey: "avatarURL") as? String,
            level: cdUser.value(forKey: "level") as? Int ?? 1,
            experience: cdUser.value(forKey: "experience") as? Int ?? 0,
            joinedAt: cdUser.value(forKey: "joinedAt") as? Date ?? Date(),
            friends: [],
            settings: settings,
            treasuresCreated: cdUser.value(forKey: "treasuresCreated") as? Int ?? 0,
            treasuresFound: cdUser.value(forKey: "treasuresFound") as? Int ?? 0,
            points: cdUser.value(forKey: "points") as? Int ?? 0,
            bio: cdUser.value(forKey: "bio") as? String,
            isActive: cdUser.value(forKey: "isActive") as? Bool ?? true
        )
    }
    
    private func treasureFromCoreData(_ cdTreasure: NSManagedObject) -> Treasure? {
        guard let id = cdTreasure.value(forKey: "id") as? UUID,
              let creatorId = cdTreasure.value(forKey: "creatorId") as? UUID,
              let title = cdTreasure.value(forKey: "title") as? String,
              let latitude = cdTreasure.value(forKey: "latitude") as? Double,
              let longitude = cdTreasure.value(forKey: "longitude") as? Double else {
            return nil
        }
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        var arObject = ARObjectConfig()
        if let arObjectData = cdTreasure.value(forKey: "arObjectData") as? Data,
           let decodedARObject = try? JSONDecoder().decode(ARObjectConfig.self, from: arObjectData) {
            arObject = decodedARObject
        }
        
        return Treasure(
            id: id,
            creatorId: creatorId,
            title: title,
            description: cdTreasure.value(forKey: "treasureDescription") as? String,
            message: cdTreasure.value(forKey: "message") as? String,
            location: location,
            altitude: cdTreasure.value(forKey: "altitude") as? Double ?? 0,
            arAnchorData: cdTreasure.value(forKey: "arAnchorData") as? Data,
            type: TreasureType(rawValue: cdTreasure.value(forKey: "type") as? String ?? "standard") ?? .standard,
            mediaURL: cdTreasure.value(forKey: "mediaURL") as? String,
            visibility: Visibility(rawValue: cdTreasure.value(forKey: "visibility") as? String ?? "public") ?? .publicVisibility,
            difficulty: Difficulty(rawValue: cdTreasure.value(forKey: "difficulty") as? String ?? "medium") ?? .medium,
            hint: cdTreasure.value(forKey: "hint") as? String,
            points: cdTreasure.value(forKey: "points") as? Int ?? 10,
            maxDiscoveries: cdTreasure.value(forKey: "maxDiscoveries") as? Int,
            isActive: cdTreasure.value(forKey: "isActive") as? Bool ?? true,
            createdAt: cdTreasure.value(forKey: "createdAt") as? Date ?? Date(),
            expiresAt: cdTreasure.value(forKey: "expiresAt") as? Date,
            discoveries: [],
            arObject: arObject
        )
    }
    
    private func discoveryFromCoreData(_ cdDiscovery: NSManagedObject) -> Discovery? {
        guard let id = cdDiscovery.value(forKey: "id") as? UUID,
              let treasureId = cdDiscovery.value(forKey: "treasureId") as? UUID,
              let userId = cdDiscovery.value(forKey: "userId") as? UUID else {
            return nil
        }
        
        var reactionType: ReactionType? = nil
        if let reactionString = cdDiscovery.value(forKey: "reactionType") as? String {
            reactionType = ReactionType(rawValue: reactionString)
        }
        
        return Discovery(
            id: id,
            treasureId: treasureId,
            userId: userId,
            discoveredAt: cdDiscovery.value(forKey: "discoveredAt") as? Date ?? Date(),
            photoURL: cdDiscovery.value(forKey: "photoURL") as? String,
            comment: cdDiscovery.value(forKey: "comment") as? String,
            reactionType: reactionType,
            pointsEarned: cdDiscovery.value(forKey: "pointsEarned") as? Int ?? 0,
            timeToFind: cdDiscovery.value(forKey: "timeToFind") as? Int,
            distanceFromTreasure: cdDiscovery.value(forKey: "distanceFromTreasure") as? Float
        )
    }
}

enum DataError: Error {
    case notFound
    case invalidData
    case syncFailed
}