//
//  MainTabView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreateTreasure = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                MapHomeView()
                    .tag(0)
                
                DiscoveryFeedView()
                    .tag(1)
                
                Color.clear
                    .tag(2)
                
                ActivityView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            
            CustomTabBar(
                selectedTab: $selectedTab,
                showCreateTreasure: $showCreateTreasure
            )
        }
        .sheet(isPresented: $showCreateTreasure) {
            CreateTreasureView(isPresented: $showCreateTreasure)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showCreateTreasure: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "map.fill",
                title: "Map",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabBarButton(
                icon: "sparkles",
                title: "Discover",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            Spacer()
            
            TabBarButton(
                icon: "bell.fill",
                title: "Activity",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
            
            TabBarButton(
                icon: "person.fill",
                title: "Profile",
                isSelected: selectedTab == 4,
                action: { selectedTab = 4 }
            )
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .fill(.ultraThinMaterial)
                .themeShadow(Theme.Shadow.elevated)
        )
        .overlay(
            CreateTreasureButton(action: {
                Theme.Haptics.impact(.medium)
                showCreateTreasure = true
            })
                .offset(y: -30)
        )
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.small)
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Theme.Haptics.selection()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(
                        isSelected ? Color.App.magicalPurple : Color.gray
                    )
                
                Text(title)
                    .font(Typography.Fonts.caption2(.medium))
                    .foregroundColor(
                        isSelected ? Color.App.magicalPurple : Color.gray
                    )
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(Theme.Animation.quick, value: isSelected)
        }
    }
}

struct CreateTreasureButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.Gradient.treasure)
                    .frame(width: 56, height: 56)
                    .themeShadow(Theme.Shadow.elevated)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isPressed ? 45 : 0))
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity,
                           pressing: { pressing in
            withAnimation(Theme.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
}