//
//  ProfileView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var userStats = UserStats(
        treasuresCreated: 12,
        treasuresFound: 45,
        followers: 128,
        following: 96,
        level: 8,
        xp: 3450,
        xpToNextLevel: 5000
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    ProfileHeader(stats: userStats)
                    
                    StatsGrid(stats: userStats)
                        .padding(.horizontal, Theme.Spacing.medium)
                    
                    AchievementsSection()
                        .padding(.horizontal, Theme.Spacing.medium)
                    
                    RecentTreasuresSection()
                        .padding(.horizontal, Theme.Spacing.medium)
                }
                .padding(.vertical, Theme.Spacing.medium)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color.App.magicalPurple)
                    }
                }
            }
        }
    }
}

struct UserStats {
    let treasuresCreated: Int
    let treasuresFound: Int
    let followers: Int
    let following: Int
    let level: Int
    let xp: Int
    let xpToNextLevel: Int
}

struct ProfileHeader: View {
    let stats: UserStats
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(Color.Gradient.magical)
                    .frame(width: 100, height: 100)
                
                Text("JD")
                    .font(Typography.Fonts.title1(.bold))
                    .foregroundColor(.white)
            }
            
            Text("John Doe")
                .font(Typography.Fonts.title2(.bold))
                .foregroundColor(Color.App.textPrimary)
            
            Text("@johndoe")
                .font(Typography.Fonts.body(.regular))
                .foregroundColor(Color.App.textSecondary)
            
            LevelProgressView(level: stats.level, xp: stats.xp, xpToNextLevel: stats.xpToNextLevel)
                .padding(.horizontal, Theme.Spacing.xLarge)
            
            HStack(spacing: Theme.Spacing.xLarge) {
                VStack {
                    Text("\(stats.followers)")
                        .font(Typography.Fonts.headline(.bold))
                        .foregroundColor(Color.App.textPrimary)
                    Text("Followers")
                        .font(Typography.Fonts.caption1(.regular))
                        .foregroundColor(Color.App.textSecondary)
                }
                
                VStack {
                    Text("\(stats.following)")
                        .font(Typography.Fonts.headline(.bold))
                        .foregroundColor(Color.App.textPrimary)
                    Text("Following")
                        .font(Typography.Fonts.caption1(.regular))
                        .foregroundColor(Color.App.textSecondary)
                }
            }
        }
    }
}

struct LevelProgressView: View {
    let level: Int
    let xp: Int
    let xpToNextLevel: Int
    
    var progress: Double {
        Double(xp) / Double(xpToNextLevel)
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xSmall) {
            HStack {
                Text("Level \(level)")
                    .font(Typography.Fonts.headline(.semibold))
                    .foregroundColor(Color.App.treasureGold)
                
                Spacer()
                
                Text("\(xp) / \(xpToNextLevel) XP")
                    .font(Typography.Fonts.caption1(.regular))
                    .foregroundColor(Color.App.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Color.Gradient.treasure)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct StatsGrid: View {
    let stats: UserStats
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.medium) {
            StatCard(
                icon: "cube.box.fill",
                value: "\(stats.treasuresCreated)",
                label: "Created",
                color: Color.App.treasureGold
            )
            
            StatCard(
                icon: "sparkles",
                value: "\(stats.treasuresFound)",
                label: "Discovered",
                color: Color.App.discoveryBlue
            )
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(Typography.Fonts.title2(.bold))
                .foregroundColor(Color.App.textPrimary)
            
            Text(label)
                .font(Typography.Fonts.caption1(.regular))
                .foregroundColor(Color.App.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(color.opacity(0.1))
        )
    }
}

struct AchievementsSection: View {
    let achievements = [
        Achievement(icon: "star.fill", title: "First Discovery", unlocked: true),
        Achievement(icon: "flame.fill", title: "7 Day Streak", unlocked: true),
        Achievement(icon: "crown.fill", title: "Treasure Master", unlocked: false),
        Achievement(icon: "globe", title: "World Explorer", unlocked: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Achievements")
                .font(Typography.Fonts.headline(.semibold))
                .foregroundColor(Color.App.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.small) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let unlocked: Bool
}

struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xSmall) {
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? Color.Gradient.treasure : Color(UIColor.systemGray5))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.unlocked ? .white : Color.gray)
            }
            
            Text(achievement.title)
                .font(Typography.Fonts.caption2(.medium))
                .foregroundColor(Color.App.textSecondary)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
        .opacity(achievement.unlocked ? 1.0 : 0.5)
    }
}

struct RecentTreasuresSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Recent Treasures")
                .font(Typography.Fonts.headline(.semibold))
                .foregroundColor(Color.App.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.small) {
                ForEach(0..<6) { _ in
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Color.Gradient.magical.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
        }
    }
}