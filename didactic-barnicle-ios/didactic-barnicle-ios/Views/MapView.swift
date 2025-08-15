import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var viewModel = MapViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingTreasureDetail = false
    @State private var selectedTreasure: Treasure?
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    annotationItems: viewModel.treasures) { treasure in
                    MapAnnotation(coordinate: treasure.coordinate) {
                        TreasureAnnotationView(treasure: treasure)
                            .onTapGesture {
                                selectedTreasure = treasure
                                showingTreasureDetail = true
                            }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: centerOnUserLocation) {
                            Image(systemName: "location.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Treasure Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadTreasures()
                if let location = locationManager.currentLocation {
                    region.center = location.coordinate
                }
            }
            .onChange(of: locationManager.currentLocation) { newLocation in
                if let location = newLocation {
                    withAnimation {
                        region.center = location.coordinate
                    }
                }
            }
            .sheet(isPresented: $showingTreasureDetail) {
                if let treasure = selectedTreasure {
                    TreasureDetailView(treasure: treasure)
                }
            }
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.currentLocation {
            withAnimation {
                region.center = location.coordinate
            }
        }
    }
}

struct TreasureAnnotationView: View {
    let treasure: Treasure
    
    var body: some View {
        VStack {
            Image(systemName: "star.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(treasure.isFound ? .gray : .yellow)
            Text(treasure.name)
                .font(.caption)
                .padding(4)
                .background(Color.white.opacity(0.8))
                .cornerRadius(4)
        }
    }
}

struct TreasureDetailView: View {
    let treasure: Treasure
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: treasure.isFound ? "checkmark.circle.fill" : "star.circle")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(treasure.isFound ? .green : .yellow)
                
                Text(treasure.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(treasure.hint)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                if treasure.isFound {
                    Text("Found on: \(treasure.foundDate?.formatted() ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Treasure Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MapView()
        .environmentObject(LocationManager())
}