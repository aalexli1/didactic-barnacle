//
//  OnboardingView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPageView(
                imageName: "map.fill",
                title: "Explore Your World",
                description: "Discover magical treasures hidden by others in the real world around you",
                gradient: Color.Gradient.discovery,
                pageIndex: 0
            )
            .tag(0)
            
            OnboardingPageView(
                imageName: "cube.box.fill",
                title: "Create Treasures",
                description: "Leave AR treasures with personal messages for others to find",
                gradient: Color.Gradient.treasure,
                pageIndex: 1
            )
            .tag(1)
            
            OnboardingPageView(
                imageName: "sparkles",
                title: "Share the Magic",
                description: "Connect with friends and strangers through hidden discoveries",
                gradient: Color.Gradient.magical,
                pageIndex: 2,
                showGetStarted: true,
                onGetStarted: {
                    withAnimation {
                        isOnboardingComplete = true
                    }
                }
            )
            .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    let gradient: LinearGradient
    let pageIndex: Int
    var showGetStarted: Bool = false
    var onGetStarted: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xLarge) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: imageName)
                    .font(.system(size: 100))
                    .foregroundStyle(gradient)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: Theme.Spacing.medium) {
                Text(title)
                    .font(Typography.Fonts.title1(.bold))
                    .foregroundColor(Color.App.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(Typography.Fonts.body(.regular))
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xLarge)
            }
            
            Spacer()
            
            if showGetStarted {
                Button(action: {
                    Theme.Haptics.impact(.medium)
                    onGetStarted?()
                }) {
                    Text("Get Started")
                        .font(Typography.Fonts.headline(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.medium)
                        .background(gradient)
                        .cornerRadius(Theme.CornerRadius.medium)
                        .padding(.horizontal, Theme.Spacing.xLarge)
                }
                .padding(.bottom, Theme.Spacing.xLarge)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}