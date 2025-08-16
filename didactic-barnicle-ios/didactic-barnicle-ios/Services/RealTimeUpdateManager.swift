import Foundation
import Combine
import UserNotifications
import MapKit

class RealTimeUpdateManager: ObservableObject {
    static let shared = RealTimeUpdateManager()
    
    @Published var newTreasures: [Treasure] = []
    @Published var friendActivities: [FriendActivity] = []
    @Published var expiringTreasures: [Treasure] = []
    @Published var popularAreas: [PopularArea] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private var webSocketTask: URLSessionWebSocketTask?
    
    init() {
        setupWebSocket()
        startPolling()
        setupNotifications()
    }
    
    // MARK: - WebSocket for Real-time Updates
    
    private func setupWebSocket() {
        guard let url = URL(string: "wss://api.treasurehunt.com/live") else { return }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleWebSocketMessage(text)
                case .data(let data):
                    self?.handleWebSocketData(data)
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket error: \(error)")
                // Reconnect after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.setupWebSocket()
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        if let update = try? JSONDecoder().decode(LiveUpdate.self, from: data) {
            DispatchQueue.main.async {
                switch update.type {
                case .newTreasure:
                    if let treasure = update.treasure {
                        self.handleNewTreasure(treasure)
                    }
                case .friendActivity:
                    if let activity = update.friendActivity {
                        self.handleFriendActivity(activity)
                    }
                case .treasureExpiring:
                    if let treasure = update.treasure {
                        self.handleExpiringTreasure(treasure)
                    }
                case .popularArea:
                    if let area = update.popularArea {
                        self.handlePopularArea(area)
                    }
                }
            }
        }
    }
    
    private func handleWebSocketData(_ data: Data) {
        // Handle binary data if needed
    }
    
    // MARK: - Polling for Updates
    
    private func startPolling() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.fetchLatestUpdates()
        }
    }
    
    private func fetchLatestUpdates() {
        // Fetch new treasures
        APIClient.shared.fetchNewTreasures { [weak self] treasures in
            DispatchQueue.main.async {
                self?.newTreasures = treasures
            }
        }
        
        // Fetch friend activities
        APIClient.shared.fetchFriendActivities { [weak self] activities in
            DispatchQueue.main.async {
                self?.friendActivities = activities
            }
        }
        
        // Check for expiring treasures
        checkExpiringTreasures()
    }
    
    // MARK: - Update Handlers
    
    private func handleNewTreasure(_ treasure: Treasure) {
        newTreasures.append(treasure)
        
        // Send notification
        sendNotification(
            title: "New Treasure Nearby! 🎁",
            body: "\(treasure.title) has appeared near you!",
            identifier: "new_treasure_\(treasure.id)"
        )
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func handleFriendActivity(_ activity: FriendActivity) {
        friendActivities.insert(activity, at: 0)
        
        // Keep only recent activities
        if friendActivities.count > 20 {
            friendActivities = Array(friendActivities.prefix(20))
        }
        
        // Send notification for close friends
        if activity.isCloseFriend {
            sendNotification(
                title: "\(activity.friendName) found a treasure!",
                body: activity.treasureName,
                identifier: "friend_activity_\(activity.id)"
            )
        }
    }
    
    private func handleExpiringTreasure(_ treasure: Treasure) {
        if !expiringTreasures.contains(where: { $0.id == treasure.id }) {
            expiringTreasures.append(treasure)
            
            // Send urgent notification
            sendNotification(
                title: "Treasure Expiring Soon! ⏰",
                body: "\(treasure.title) will disappear in 30 minutes!",
                identifier: "expiring_treasure_\(treasure.id)"
            )
            
            // Strong haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
    
    private func handlePopularArea(_ area: PopularArea) {
        if let index = popularAreas.firstIndex(where: { $0.id == area.id }) {
            popularAreas[index] = area
        } else {
            popularAreas.append(area)
        }
        
        // Sort by activity level
        popularAreas.sort { $0.activityLevel > $1.activityLevel }
    }
    
    // MARK: - Expiring Treasures Check
    
    private func checkExpiringTreasures() {
        let now = Date()
        let thirtyMinutesFromNow = now.addingTimeInterval(30 * 60)
        
        // Check cached treasures
        let expiring = TreasureService().treasures.filter { treasure in
            guard let expiresAt = treasure.expiresAt else { return false }
            return expiresAt > now && expiresAt <= thirtyMinutesFromNow
        }
        
        for treasure in expiring {
            handleExpiringTreasure(treasure)
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Heat Map Data
    
    func getHeatMapData(for region: MKCoordinateRegion) -> [HeatMapPoint] {
        var heatMapPoints: [HeatMapPoint] = []
        
        // Generate heat map from friend activities
        for activity in friendActivities {
            let point = HeatMapPoint(
                coordinate: activity.coordinate,
                intensity: 0.5,
                timestamp: activity.timestamp
            )
            heatMapPoints.append(point)
        }
        
        // Add popular areas
        for area in popularAreas {
            let point = HeatMapPoint(
                coordinate: area.center,
                intensity: Double(area.activityLevel) / 100.0,
                timestamp: Date()
            )
            heatMapPoints.append(point)
        }
        
        return heatMapPoints
    }
    
    // MARK: - Cleanup
    
    deinit {
        updateTimer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

// MARK: - Supporting Types

struct LiveUpdate: Codable {
    let type: UpdateType
    let treasure: Treasure?
    let friendActivity: FriendActivity?
    let popularArea: PopularArea?
    
    enum UpdateType: String, Codable {
        case newTreasure
        case friendActivity
        case treasureExpiring
        case popularArea
    }
}

struct FriendActivity: Identifiable, Codable {
    let id: String
    let friendId: String
    let friendName: String
    let treasureId: String
    let treasureName: String
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let isCloseFriend: Bool
    let points: Int
}

struct PopularArea: Identifiable, Codable {
    let id: String
    let center: CLLocationCoordinate2D
    let radius: Double
    let activityLevel: Int // 0-100
    let treasureCount: Int
    let recentDiscoveries: Int
}

struct HeatMapPoint {
    let coordinate: CLLocationCoordinate2D
    let intensity: Double
    let timestamp: Date
}

// Extension for MKCoordinateRegion
extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center.latitude == rhs.center.latitude &&
               lhs.center.longitude == rhs.center.longitude &&
               lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
               lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}