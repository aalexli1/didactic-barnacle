import Foundation
import CoreLocation
import Combine

class TreasureService: ObservableObject {
    @Published var treasures: [Treasure] = []
    @Published var nearbyTreasures: [Treasure] = []
    @Published var collectedTreasures: Set<String> = []
    
    private let maxNearbyDistance: CLLocationDistance = 500 // 500 meters
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTreasures()
        loadCollectedTreasures()
    }
    
    private func loadTreasures() {
        // Load mock data for now, replace with API call later
        treasures = Treasure.mockTreasures()
    }
    
    private func loadCollectedTreasures() {
        if let data = UserDefaults.standard.data(forKey: "collectedTreasures"),
           let collected = try? JSONDecoder().decode(Set<String>.self, from: data) {
            collectedTreasures = collected
        }
    }
    
    private func saveCollectedTreasures() {
        if let data = try? JSONEncoder().encode(collectedTreasures) {
            UserDefaults.standard.set(data, forKey: "collectedTreasures")
        }
    }
    
    func updateNearbyTreasures(currentLocation: CLLocation) {
        nearbyTreasures = treasures.filter { treasure in
            let treasureLocation = CLLocation(
                latitude: treasure.latitude,
                longitude: treasure.longitude
            )
            let distance = currentLocation.distance(from: treasureLocation)
            return distance <= maxNearbyDistance && !collectedTreasures.contains(treasure.id)
        }.sorted { treasure1, treasure2 in
            let location1 = CLLocation(latitude: treasure1.latitude, longitude: treasure1.longitude)
            let location2 = CLLocation(latitude: treasure2.latitude, longitude: treasure2.longitude)
            let distance1 = currentLocation.distance(from: location1)
            let distance2 = currentLocation.distance(from: location2)
            return distance1 < distance2
        }
    }
    
    func collectTreasure(_ treasure: Treasure) {
        collectedTreasures.insert(treasure.id)
        saveCollectedTreasures()
        
        // Update nearby treasures to remove collected one
        nearbyTreasures.removeAll { $0.id == treasure.id }
        
        // Award points/rewards
        UserService.shared.addPoints(treasure.points)
    }
    
    func getTreasure(by id: String) -> Treasure? {
        treasures.first { $0.id == id }
    }
    
    func isCollected(_ treasureId: String) -> Bool {
        collectedTreasures.contains(treasureId)
    }
}