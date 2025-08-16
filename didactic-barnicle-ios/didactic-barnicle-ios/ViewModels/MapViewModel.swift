import Foundation
import MapKit
import Combine
import CoreLocation

class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var userHeading: CLHeading?
    @Published var treasureAnnotations: [TreasureAnnotation] = []
    @Published var filteredTreasures: [Treasure] = []
    @Published var selectedTreasure: Treasure?
    @Published var showingTreasureDetail = false
    @Published var targetTreasure: Treasure?
    @Published var visitedTreasures: [String] = []
    @Published var showRadarView = false
    @Published var showCompassMode = false
    
    // Filter settings
    @Published var selectedTypes = Set(TreasureType.allCases)
    @Published var selectedDifficulties = Set(Difficulty.allCases)
    @Published var showOnlyUncollected = true
    @Published var maxDistance: Double = 1000
    
    private let locationManager: LocationManager
    private let treasureService: TreasureService
    private var cancellables = Set<AnyCancellable>()
    
    init(locationManager: LocationManager, treasureService: TreasureService) {
        self.locationManager = locationManager
        self.treasureService = treasureService
        
        setupSubscriptions()
        loadTreasures()
    }
    
    private func setupSubscriptions() {
        // Update region when user location changes
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateUserLocation(location)
                self?.treasureService.updateNearbyTreasures(currentLocation: location)
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Update heading
        locationManager.$heading
            .sink { [weak self] heading in
                self?.userHeading = heading
            }
            .store(in: &cancellables)
        
        // Update annotations when nearby treasures change
        treasureService.$nearbyTreasures
            .sink { [weak self] treasures in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Apply filters when settings change
        Publishers.CombineLatest4(
            $selectedTypes,
            $selectedDifficulties,
            $showOnlyUncollected,
            $maxDistance
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }
    
    private func updateUserLocation(_ location: CLLocation) {
        userLocation = location.coordinate
        
        // Center map on user location initially
        if region.center.latitude == 37.7749 && region.center.longitude == -122.4194 {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func loadTreasures() {
        // Treasures are loaded by the service
        if let location = locationManager.currentLocation {
            treasureService.updateNearbyTreasures(currentLocation: location)
        }
    }
    
    private func updateTreasureAnnotations(_ treasures: [Treasure]) {
        treasureAnnotations = treasures.map { treasure in
            TreasureAnnotation(treasure: treasure)
        }
    }
    
    func selectTreasure(_ annotation: TreasureAnnotation) {
        selectedTreasure = annotation.treasure
        showingTreasureDetail = true
    }
    
    func centerOnUserLocation() {
        guard let userLocation = userLocation else { return }
        
        withAnimation {
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    func zoomIn() {
        withAnimation {
            region.span.latitudeDelta *= 0.5
            region.span.longitudeDelta *= 0.5
        }
    }
    
    func zoomOut() {
        withAnimation {
            region.span.latitudeDelta *= 2.0
            region.span.longitudeDelta *= 2.0
        }
    }
    
    func applyFilters() {
        guard let userLocation = locationManager.currentLocation else {
            filteredTreasures = []
            return
        }
        
        filteredTreasures = treasureService.nearbyTreasures.filter { treasure in
            // Type filter
            guard selectedTypes.contains(treasure.type) else { return false }
            
            // Difficulty filter
            guard selectedDifficulties.contains(treasure.difficulty) else { return false }
            
            // Collection status filter
            if showOnlyUncollected && treasureService.isCollected(treasure.id.uuidString) {
                return false
            }
            
            // Distance filter
            let treasureLocation = CLLocation(
                latitude: treasure.location.latitude,
                longitude: treasure.location.longitude
            )
            let distance = userLocation.distance(from: treasureLocation)
            guard distance <= maxDistance else { return false }
            
            return true
        }
        
        updateTreasureAnnotations(filteredTreasures)
    }
    
    func navigateToTreasure(_ treasure: Treasure) {
        targetTreasure = treasure
        withAnimation {
            region = MKCoordinateRegion(
                center: treasure.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
    }
    
    func markTreasureVisited(_ treasureId: String) {
        if !visitedTreasures.contains(treasureId) {
            visitedTreasures.append(treasureId)
            saveBreadcrumbTrail()
        }
    }
    
    func getDistanceToTreasure(_ treasure: Treasure) -> CLLocationDistance? {
        guard let userLocation = locationManager.currentLocation else { return nil }
        let treasureLocation = CLLocation(
            latitude: treasure.location.latitude,
            longitude: treasure.location.longitude
        )
        return userLocation.distance(from: treasureLocation)
    }
    
    func toggleRadarView() {
        showRadarView.toggle()
    }
    
    func toggleCompassMode() {
        showCompassMode.toggle()
    }
    
    private func saveBreadcrumbTrail() {
        UserDefaults.standard.set(visitedTreasures, forKey: "visitedTreasures")
    }
    
    private func loadBreadcrumbTrail() {
        if let visited = UserDefaults.standard.stringArray(forKey: "visitedTreasures") {
            visitedTreasures = visited
        }
    }
}

// MARK: - TreasureAnnotation
class TreasureAnnotation: NSObject, MKAnnotation, Identifiable {
    let id = UUID()
    let treasure: Treasure
    
    var coordinate: CLLocationCoordinate2D {
        treasure.coordinate
    }
    
    var title: String? {
        treasure.name
    }
    
    var subtitle: String? {
        "\(treasure.points) points • \(treasure.difficulty.rawValue)"
    }
    
    init(treasure: Treasure) {
        self.treasure = treasure
        super.init()
    }
}