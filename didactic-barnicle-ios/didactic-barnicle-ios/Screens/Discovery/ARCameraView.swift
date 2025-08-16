//
//  ARCameraView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct ARCameraView: View {
    @Binding var isPresented: Bool
    var targetTreasure: Treasure? = nil
    @State private var detectedTreasures: [DetectedTreasure] = []
    @State private var selectedTreasure: DetectedTreasure? = nil
    @State private var showDiscoveryAnimation = false
    
    var body: some View {
        ZStack {
            ARCameraPlaceholder()
            
            VStack {
                ARTopBar(isPresented: $isPresented)
                
                Spacer()
                
                if !detectedTreasures.isEmpty {
                    ARRadar(treasures: detectedTreasures)
                        .frame(width: 150, height: 150)
                        .padding(Theme.Spacing.medium)
                }
                
                ARBottomControls()
            }
            
            if let treasure = selectedTreasure {
                TreasureDiscoveryOverlay(
                    treasure: treasure,
                    showAnimation: $showDiscoveryAnimation,
                    onDismiss: {
                        selectedTreasure = nil
                        showDiscoveryAnimation = false
                    }
                )
            }
        }
        .onAppear {
            simulateTreasureDetection()
        }
    }
    
    func simulateTreasureDetection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            detectedTreasures = [
                DetectedTreasure(id: "1", distance: 10, direction: 45),
                DetectedTreasure(id: "2", distance: 25, direction: 180),
                DetectedTreasure(id: "3", distance: 5, direction: 270)
            ]
        }
    }
}

struct DetectedTreasure: Identifiable {
    let id: String
    let distance: Double
    let direction: Double
}

struct ARCameraPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.9))
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: Theme.Spacing.large) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("AR Camera View")
                        .font(Typography.Fonts.headline(.regular))
                        .foregroundColor(.white.opacity(0.3))
                }
            )
    }
}

struct ARTopBar: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }
            
            Spacer()
            
            HStack(spacing: Theme.Spacing.xSmall) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color.App.treasureGold)
                
                Text("3 treasures nearby")
                    .font(Typography.Fonts.caption1(.semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, Theme.Spacing.small)
            .padding(.vertical, Theme.Spacing.xSmall)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
            )
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "flashlight.on.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.top, Theme.Spacing.medium)
    }
}

struct ARRadar: View {
    let treasures: [DetectedTreasure]
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.App.mapGreen.opacity(0.3), lineWidth: 2)
            
            Circle()
                .stroke(Color.App.mapGreen.opacity(0.2), lineWidth: 1)
                .scaleEffect(0.66)
            
            Circle()
                .stroke(Color.App.mapGreen.opacity(0.1), lineWidth: 1)
                .scaleEffect(0.33)
            
            ForEach(treasures) { treasure in
                TreasureRadarDot(treasure: treasure)
            }
            
            RadarSweep(rotation: rotation)
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 4)
                    .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

struct TreasureRadarDot: View {
    let treasure: DetectedTreasure
    
    var position: CGPoint {
        let angle = treasure.direction * .pi / 180
        let normalizedDistance = min(treasure.distance / 50, 1.0)
        let radius = 65 * normalizedDistance
        
        return CGPoint(
            x: 75 + radius * cos(angle),
            y: 75 + radius * sin(angle)
        )
    }
    
    var body: some View {
        Circle()
            .fill(Color.App.treasureGold)
            .frame(width: 8, height: 8)
            .position(position)
            .overlay(
                Circle()
                    .stroke(Color.App.treasureGold, lineWidth: 2)
                    .frame(width: 16, height: 16)
                    .position(position)
                    .opacity(0.5)
            )
    }
}

struct RadarSweep: View {
    let rotation: Double
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                path.addLine(to: CGPoint(x: geometry.size.width / 2, y: 0))
            }
            .stroke(
                LinearGradient(
                    colors: [Color.App.mapGreen, Color.App.mapGreen.opacity(0)],
                    startPoint: .center,
                    endPoint: .top
                ),
                lineWidth: 2
            )
            .rotationEffect(.degrees(rotation))
        }
    }
}

struct ARBottomControls: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.xLarge) {
            Button(action: {}) {
                Image(systemName: "info.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            Button(action: {}) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                }
            }
            
            Button(action: {}) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, Theme.Spacing.xLarge)
    }
}

struct TreasureDiscoveryOverlay: View {
    let treasure: DetectedTreasure
    @Binding var showAnimation: Bool
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
            
            VStack(spacing: Theme.Spacing.large) {
                DiscoveryAnimationView()
                
                Text("Treasure Discovered!")
                    .font(Typography.Fonts.title1(.bold))
                    .foregroundStyle(Color.Gradient.treasure)
                
                Text("Golden Chest")
                    .font(Typography.Fonts.headline(.semibold))
                    .foregroundColor(.white)
                
                Text("\"May this treasure bring you joy and remind you that magic exists everywhere!\"")
                    .font(Typography.Fonts.body(.regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xLarge)
                
                HStack(spacing: Theme.Spacing.medium) {
                    Button(action: {
                        Theme.Haptics.impact(.light)
                    }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Love It")
                                .font(Typography.Fonts.headline(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.large)
                        .padding(.vertical, Theme.Spacing.medium)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.2))
                        )
                    }
                    
                    Button(action: {
                        Theme.Haptics.selection()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                                .font(Typography.Fonts.headline(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.large)
                        .padding(.vertical, Theme.Spacing.medium)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(Theme.Animation.bouncy) {
                scale = 1.0
                opacity = 1.0
            }
            Theme.Haptics.notification(.success)
        }
    }
}

struct DiscoveryAnimationView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.App.treasureGold.opacity(0.3), lineWidth: 2)
                    .frame(width: 150, height: 150)
                    .scaleEffect(scale)
                    .opacity(1.0 - (scale - 1.0))
                    .animation(
                        Animation.easeOut(duration: 2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: scale
                    )
            }
            
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.Gradient.treasure)
                .rotationEffect(.degrees(rotation))
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: rotation
                )
        }
        .onAppear {
            scale = 2.0
            rotation = 10
        }
    }
}