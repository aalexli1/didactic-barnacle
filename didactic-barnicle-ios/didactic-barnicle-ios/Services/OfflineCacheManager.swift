import Foundation
import CoreLocation
import MapKit

class OfflineCacheManager: ObservableObject {
    static let shared = OfflineCacheManager()
    
    @Published var cachedTreasures: [Treasure] = []
    @Published var cachedDiscoveries: [Discovery] = []
    @Published var pendingSyncs: [PendingSync] = []
    @Published var isOfflineMode = false
    
    private let cacheDirectory: URL
    private let treasureCacheFile = "treasures_cache.json"
    private let discoveryCacheFile = "discoveries_cache.json"
    private let pendingSyncFile = "pending_syncs.json"
    private let mapTileCacheDirectory = "map_tiles"
    
    init() {
        // Setup cache directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("offline_cache")
        
        // Create directories if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(
            at: cacheDirectory.appendingPathComponent(mapTileCacheDirectory),
            withIntermediateDirectories: true
        )
        
        loadCachedData()
    }
    
    // MARK: - Treasure Caching
    
    func cacheTreasures(_ treasures: [Treasure]) {
        cachedTreasures = treasures
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(treasures) {
            let url = cacheDirectory.appendingPathComponent(treasureCacheFile)
            try? data.write(to: url)
        }
    }
    
    func loadCachedTreasures() -> [Treasure] {
        let url = cacheDirectory.appendingPathComponent(treasureCacheFile)
        
        guard let data = try? Data(contentsOf: url) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return (try? decoder.decode([Treasure].self, from: data)) ?? []
    }
    
    // MARK: - Discovery Caching
    
    func cacheDiscovery(_ discovery: Discovery) {
        cachedDiscoveries.append(discovery)
        saveDiscoveries()
        
        // Add to pending sync if offline
        if isOfflineMode {
            addPendingSync(.discovery(discovery))
        }
    }
    
    private func saveDiscoveries() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(cachedDiscoveries) {
            let url = cacheDirectory.appendingPathComponent(discoveryCacheFile)
            try? data.write(to: url)
        }
    }
    
    // MARK: - Pending Sync Management
    
    func addPendingSync(_ sync: PendingSync) {
        pendingSyncs.append(sync)
        savePendingSyncs()
    }
    
    private func savePendingSyncs() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(pendingSyncs) {
            let url = cacheDirectory.appendingPathComponent(pendingSyncFile)
            try? data.write(to: url)
        }
    }
    
    func syncPendingData(completion: @escaping (Bool) -> Void) {
        guard !isOfflineMode && !pendingSyncs.isEmpty else {
            completion(false)
            return
        }
        
        var successCount = 0
        let totalSyncs = pendingSyncs.count
        
        for sync in pendingSyncs {
            switch sync {
            case .discovery(let discovery):
                // Sync discovery to server
                APIClient.shared.syncDiscovery(discovery) { success in
                    if success {
                        successCount += 1
                    }
                    
                    if successCount == totalSyncs {
                        self.pendingSyncs.removeAll()
                        self.savePendingSyncs()
                        completion(true)
                    }
                }
                
            case .treasureCreation(let treasure):
                // Sync new treasure to server
                APIClient.shared.createTreasure(treasure) { success in
                    if success {
                        successCount += 1
                    }
                    
                    if successCount == totalSyncs {
                        self.pendingSyncs.removeAll()
                        self.savePendingSyncs()
                        completion(true)
                    }
                }
                
            case .profileUpdate(let profile):
                // Sync profile updates
                APIClient.shared.updateProfile(profile) { success in
                    if success {
                        successCount += 1
                    }
                    
                    if successCount == totalSyncs {
                        self.pendingSyncs.removeAll()
                        self.savePendingSyncs()
                        completion(true)
                    }
                }
            }
        }
    }
    
    // MARK: - Map Tile Caching
    
    func cacheMapTiles(for region: MKCoordinateRegion) {
        // Calculate tile coordinates for the region
        let tiles = calculateTiles(for: region)
        
        for tile in tiles {
            downloadAndCacheTile(tile)
        }
    }
    
    private func calculateTiles(for region: MKCoordinateRegion) -> [MapTile] {
        // Simplified tile calculation
        var tiles: [MapTile] = []
        
        let zoomLevels = [14, 15, 16] // Cache multiple zoom levels
        
        for zoom in zoomLevels {
            let minLat = region.center.latitude - region.span.latitudeDelta / 2
            let maxLat = region.center.latitude + region.span.latitudeDelta / 2
            let minLon = region.center.longitude - region.span.longitudeDelta / 2
            let maxLon = region.center.longitude + region.span.longitudeDelta / 2
            
            let minTileX = lon2tileX(minLon, zoom: zoom)
            let maxTileX = lon2tileX(maxLon, zoom: zoom)
            let minTileY = lat2tileY(maxLat, zoom: zoom)
            let maxTileY = lat2tileY(minLat, zoom: zoom)
            
            for x in minTileX...maxTileX {
                for y in minTileY...maxTileY {
                    tiles.append(MapTile(x: x, y: y, zoom: zoom))
                }
            }
        }
        
        return tiles
    }
    
    private func lon2tileX(_ lon: Double, zoom: Int) -> Int {
        return Int(floor((lon + 180.0) / 360.0 * pow(2.0, Double(zoom))))
    }
    
    private func lat2tileY(_ lat: Double, zoom: Int) -> Int {
        let latRad = lat * .pi / 180.0
        return Int(floor((1.0 - asinh(tan(latRad)) / .pi) / 2.0 * pow(2.0, Double(zoom))))
    }
    
    private func downloadAndCacheTile(_ tile: MapTile) {
        let tileURL = "https://tile.openstreetmap.org/\(tile.zoom)/\(tile.x)/\(tile.y).png"
        
        guard let url = URL(string: tileURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            
            let filename = "\(tile.zoom)_\(tile.x)_\(tile.y).png"
            let fileURL = self.cacheDirectory
                .appendingPathComponent(self.mapTileCacheDirectory)
                .appendingPathComponent(filename)
            
            try? data.write(to: fileURL)
        }.resume()
    }
    
    func getCachedTile(_ tile: MapTile) -> Data? {
        let filename = "\(tile.zoom)_\(tile.x)_\(tile.y).png"
        let fileURL = cacheDirectory
            .appendingPathComponent(mapTileCacheDirectory)
            .appendingPathComponent(filename)
        
        return try? Data(contentsOf: fileURL)
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        
        // Recreate directories
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(
            at: cacheDirectory.appendingPathComponent(mapTileCacheDirectory),
            withIntermediateDirectories: true
        )
        
        cachedTreasures.removeAll()
        cachedDiscoveries.removeAll()
        pendingSyncs.removeAll()
    }
    
    func getCacheSize() -> String {
        let size = calculateDirectorySize(cacheDirectory)
        return formatBytes(size)
    }
    
    private func calculateDirectorySize(_ url: URL) -> Int64 {
        var size: Int64 = 0
        
        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: []
        ) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        
        return size
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Data Loading
    
    private func loadCachedData() {
        cachedTreasures = loadCachedTreasures()
        
        // Load discoveries
        let url = cacheDirectory.appendingPathComponent(discoveryCacheFile)
        if let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            cachedDiscoveries = (try? decoder.decode([Discovery].self, from: data)) ?? []
        }
        
        // Load pending syncs
        let syncURL = cacheDirectory.appendingPathComponent(pendingSyncFile)
        if let data = try? Data(contentsOf: syncURL) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            pendingSyncs = (try? decoder.decode([PendingSync].self, from: data)) ?? []
        }
    }
}

// MARK: - Supporting Types

struct MapTile {
    let x: Int
    let y: Int
    let zoom: Int
}

enum PendingSync: Codable {
    case discovery(Discovery)
    case treasureCreation(Treasure)
    case profileUpdate(UserProfile)
}