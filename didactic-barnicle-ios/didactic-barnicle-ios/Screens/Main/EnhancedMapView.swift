import SwiftUI
import MapKit

struct EnhancedMapView: View {
    @StateObject private var viewModel: MapViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var showFilters = false
    @State private var showRadar = false
    @State private var showARCamera = false
    @State private var mapType: MKMapType = .standard
    @State private var trackingMode: MKUserTrackingMode = .follow
    @State private var showProximityIndicator = false
    
    init() {
        let locationManager = LocationManager()
        let treasureService = TreasureService()
        _viewModel = StateObject(wrappedValue: MapViewModel(
            locationManager: locationManager,
            treasureService: treasureService
        ))
    }
    
    var body: some View {
        ZStack {
            // Main Map
            Map(
                coordinateRegion: $viewModel.region,
                showsUserLocation: true,
                userTrackingMode: $trackingMode,
                annotationItems: viewModel.filteredTreasures
            ) { treasure in
                MapAnnotation(coordinate: treasure.coordinate) {
                    TreasureMapAnnotation(
                        treasure: treasure,
                        distance: viewModel.getDistanceToTreasure(treasure)
                    )
                    .scaleEffect(viewModel.selectedTreasure?.id == treasure.id ? 1.2 : 1.0)
                    .onTapGesture {
                        viewModel.selectedTreasure = treasure
                        viewModel.showingTreasureDetail = true
                    }
                }
            }
            .mapType(mapType)
            .ignoresSafeArea()
            
            // Breadcrumb trail overlay
            if !viewModel.visitedTreasures.isEmpty {
                BreadcrumbTrailOverlay(
                    visitedTreasureIds: viewModel.visitedTreasures,
                    treasures: viewModel.filteredTreasures
                )
            }
            
            // UI Overlays
            VStack {
                // Top bar
                MapTopBar(
                    treasureCount: viewModel.filteredTreasures.count,
                    showFilters: $showFilters,
                    mapType: $mapType
                )
                .padding(.horizontal)
                .padding(.top, 50)
                
                // Radar view (optional)
                if showRadar {
                    HStack {
                        RadarView(
                            treasures: viewModel.filteredTreasures,
                            userLocation: locationManager.currentLocation,
                            heading: locationManager.heading
                        )
                        .frame(width: 150, height: 150)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .padding()
                        
                        Spacer()
                    }
                }
                
                // Proximity indicator
                if let targetTreasure = viewModel.targetTreasure,
                   let distance = viewModel.getDistanceToTreasure(targetTreasure),
                   showProximityIndicator {
                    ProximityIndicator(
                        distance: distance,
                        treasureName: targetTreasure.title
                    )
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // Bottom controls
                HStack {
                    // Compass mode toggle
                    MapControlButton(
                        icon: "safari.fill",
                        isActive: viewModel.showCompassMode
                    ) {
                        viewModel.toggleCompassMode()
                    }
                    
                    Spacer()
                    
                    // Control buttons
                    VStack(spacing: 12) {
                        // Center on user
                        MapControlButton(icon: "location.fill") {
                            trackingMode = .follow
                            viewModel.centerOnUserLocation()
                        }
                        
                        // Toggle radar
                        MapControlButton(
                            icon: "radar",
                            isActive: showRadar
                        ) {
                            withAnimation {
                                showRadar.toggle()
                            }
                        }
                        
                        // AR Camera
                        MapControlButton(icon: "camera.fill") {
                            showARCamera = true
                        }
                        
                        // Zoom controls
                        VStack(spacing: 0) {
                            Button(action: viewModel.zoomIn) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(width: 44, height: 36)
                            }
                            
                            Divider()
                            
                            Button(action: viewModel.zoomOut) {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(width: 44, height: 36)
                            }
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
        }
        .sheet(isPresented: $showFilters) {
            TreasureFilterView(
                selectedTypes: $viewModel.selectedTypes,
                selectedDifficulties: $viewModel.selectedDifficulties,
                showOnlyUncollected: $viewModel.showOnlyUncollected,
                maxDistance: $viewModel.maxDistance
            )
        }
        .sheet(isPresented: $viewModel.showingTreasureDetail) {
            if let treasure = viewModel.selectedTreasure {
                TreasurePreviewCard(
                    treasure: treasure,
                    distance: viewModel.getDistanceToTreasure(treasure)
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    viewModel.markTreasureVisited(treasure.id.uuidString)
                }
            }
        }
        .fullScreenCover(isPresented: $showARCamera) {
            ARCameraView(targetTreasure: viewModel.selectedTreasure)
        }
        .onChange(of: viewModel.targetTreasure) { treasure in
            withAnimation {
                showProximityIndicator = treasure != nil
            }
        }
    }
}

struct MapTopBar: View {
    let treasureCount: Int
    @Binding var showFilters: Bool
    @Binding var mapType: MKMapType
    
    var body: some View {
        HStack {
            // Treasure count
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.yellow)
                Text("\(treasureCount) treasures")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            
            Spacer()
            
            // Map type selector
            Menu {
                Button(action: { mapType = .standard }) {
                    Label("Standard", systemImage: "map")
                }
                Button(action: { mapType = .satellite }) {
                    Label("Satellite", systemImage: "globe")
                }
                Button(action: { mapType = .hybrid }) {
                    Label("Hybrid", systemImage: "map.fill")
                }
            } label: {
                Image(systemName: "map.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Filter button
            Button(action: { showFilters = true }) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }
}

struct MapControlButton: View {
    let icon: String
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isActive ? .white : .blue)
                .frame(width: 44, height: 44)
                .background(isActive ? Color.blue : Color(.systemBackground))
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct BreadcrumbTrailOverlay: View {
    let visitedTreasureIds: [String]
    let treasures: [Treasure]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let visitedTreasures = treasures.filter { treasure in
                    visitedTreasureIds.contains(treasure.id.uuidString)
                }
                
                for (index, treasureId) in visitedTreasureIds.enumerated() {
                    guard let treasure = visitedTreasures.first(where: { $0.id.uuidString == treasureId }) else { continue }
                    
                    let point = CGPoint(
                        x: treasure.location.longitude,
                        y: treasure.location.latitude
                    )
                    
                    if index == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: 3,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [10, 5]
                )
            )
        }
        .allowsHitTesting(false)
    }
}