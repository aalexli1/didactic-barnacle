//
//  MapHomeView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI
import MapKit

struct MapHomeView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showARCamera = false
    @State private var nearbyTreasures: [TreasureAnnotation] = []
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: nearbyTreasures) { treasure in
                MapAnnotation(coordinate: treasure.coordinate) {
                    TreasureMapPin(treasure: treasure)
                }
            }
            .ignoresSafeArea()
            
            VStack {
                MapTopBar()
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.top, Theme.Spacing.medium)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: Theme.Spacing.medium) {
                        MapActionButton(
                            icon: "location.fill",
                            action: centerOnUserLocation
                        )
                        
                        MapActionButton(
                            icon: "camera.fill",
                            action: { showARCamera = true }
                        )
                    }
                    .padding(.trailing, Theme.Spacing.medium)
                    .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            loadNearbyTreasures()
        }
        .sheet(isPresented: $showARCamera) {
            ARCameraView(isPresented: $showARCamera)
        }
    }
    
    func centerOnUserLocation() {
        Theme.Haptics.impact(.light)
    }
    
    func loadNearbyTreasures() {
        nearbyTreasures = [
            TreasureAnnotation(
                id: "1",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                type: .common
            ),
            TreasureAnnotation(
                id: "2",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                type: .rare
            ),
            TreasureAnnotation(
                id: "3",
                coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
                type: .legendary
            )
        ]
    }
}

struct TreasureAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: TreasureType
    
    enum TreasureType {
        case common, rare, legendary
        
        var color: Color {
            switch self {
            case .common: return Color.App.mapGreen
            case .rare: return Color.App.discoveryBlue
            case .legendary: return Color.App.treasureGold
            }
        }
    }
}

struct TreasureMapPin: View {
    let treasure: TreasureAnnotation
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(treasure.type.color.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(isAnimating ? 1.5 : 1.0)
                .opacity(isAnimating ? 0 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(treasure.type.color)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct MapTopBar: View {
    var body: some View {
        HStack {
            Text("3 treasures nearby")
                .font(Typography.Fonts.headline(.semibold))
                .foregroundColor(Color.App.textPrimary)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.small)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
            
            Spacer()
            
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(Color.App.magicalPurple)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
        }
    }
}

struct MapActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.App.magicalPurple)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .themeShadow(Theme.Shadow.medium)
                )
        }
    }
}