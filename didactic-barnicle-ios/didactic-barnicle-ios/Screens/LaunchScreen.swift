//
//  LaunchScreen.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.App.magicalPurple
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.large) {
                Image(systemName: "map.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.Gradient.treasure)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 100))
                            .foregroundColor(.white.opacity(0.3))
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 20)
                                    .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    )
                
                Text("AR Treasure Hunt")
                    .font(Typography.Fonts.largeTitle(.bold))
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                Text("Discover Magic Around You")
                    .font(Typography.Fonts.subheadline(.regular))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(Theme.Animation.smooth) {
                    scale = 1.0
                    opacity = 1.0
                }
                isAnimating = true
            }
        }
    }
}