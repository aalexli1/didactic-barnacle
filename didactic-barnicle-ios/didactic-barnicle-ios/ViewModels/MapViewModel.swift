import Foundation
import MapKit
import Combine

class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var treasureAnnotations: [TreasureAnnotation] = []
    @Published var selectedTreasure: Treasure?
    @Published var showingTreasureDetail = false
    
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
            }
            .store(in: &cancellables)
        
        // Update annotations when nearby treasures change
        treasureService.$nearbyTreasures
            .sink { [weak self] treasures in
                self?.updateTreasureAnnotations(treasures)
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