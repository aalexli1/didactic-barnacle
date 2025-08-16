//
//  DiscoveryFeedView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct DiscoveryFeedView: View {
    @State private var discoveries: [DiscoveryFeedItem] = DiscoveryFeedItem.sampleData
    @State private var selectedFilter: DiscoveryFilter = .all
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.medium) {
                    FilterBar(selectedFilter: $selectedFilter)
                        .padding(.horizontal, Theme.Spacing.medium)
                    
                    if discoveries.isEmpty {
                        EmptyStateView(
                            icon: "sparkles",
                            title: "No Discoveries Yet",
                            message: "Start exploring to find treasures!"
                        )
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: Theme.Spacing.medium) {
                            ForEach(discoveries) { discovery in
                                DiscoveryCard(discovery: discovery)
                                    .padding(.horizontal, Theme.Spacing.medium)
                            }
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.medium)
            }
            .navigationTitle("Discoveries")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct DiscoveryFeedItem: Identifiable {
    let id = UUID()
    let username: String
    let userAvatar: String
    let treasureType: String
    let message: String
    let location: String
    let timeAgo: String
    let likes: Int
    let comments: Int
    var isLiked: Bool = false
    
    static let sampleData: [DiscoveryFeedItem] = [
        DiscoveryFeedItem(
            username: "AdventureSeeker",
            userAvatar: "person.circle.fill",
            treasureType: "Golden Chest",
            message: "Found this amazing treasure with a heartwarming message!",
            location: "Golden Gate Park",
            timeAgo: "2 hours ago",
            likes: 42,
            comments: 8
        ),
        DiscoveryFeedItem(
            username: "TreasureHunter42",
            userAvatar: "person.circle.fill",
            treasureType: "Crystal Gem",
            message: "What an incredible discovery! The AR effects were stunning.",
            location: "Downtown Plaza",
            timeAgo: "5 hours ago",
            likes: 128,
            comments: 23
        ),
        DiscoveryFeedItem(
            username: "MagicExplorer",
            userAvatar: "person.circle.fill",
            treasureType: "Ancient Scroll",
            message: "This message made my day! Thank you to whoever left this.",
            location: "City Library",
            timeAgo: "1 day ago",
            likes: 256,
            comments: 45
        )
    ]
}

enum DiscoveryFilter: String, CaseIterable {
    case all = "All"
    case nearby = "Nearby"
    case friends = "Friends"
    case trending = "Trending"
}

struct FilterBar: View {
    @Binding var selectedFilter: DiscoveryFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.small) {
                ForEach(DiscoveryFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: {
                            Theme.Haptics.selection()
                            withAnimation(Theme.Animation.quick) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.Fonts.caption1(.semibold))
                .foregroundColor(isSelected ? .white : Color.App.textPrimary)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.small)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.App.magicalPurple : Color.gray.opacity(0.1))
                )
        }
    }
}

struct DiscoveryCard: View {
    let discovery: DiscoveryFeedItem
    @State private var isLiked: Bool = false
    @State private var likeScale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                Image(systemName: discovery.userAvatar)
                    .font(.system(size: 40))
                    .foregroundColor(Color.App.magicalPurple)
                
                VStack(alignment: .leading) {
                    Text(discovery.username)
                        .font(Typography.Fonts.headline(.semibold))
                        .foregroundColor(Color.App.textPrimary)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.App.textSecondary)
                        
                        Text(discovery.location)
                            .font(Typography.Fonts.caption1(.regular))
                            .foregroundColor(Color.App.textSecondary)
                        
                        Text("•")
                            .foregroundColor(Color.App.textSecondary)
                        
                        Text(discovery.timeAgo)
                            .font(Typography.Fonts.caption1(.regular))
                            .foregroundColor(Color.App.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.Gradient.treasure)
            }
            
            Text(discovery.message)
                .font(Typography.Fonts.body(.regular))
                .foregroundColor(Color.App.textPrimary)
                .padding(.vertical, Theme.Spacing.xSmall)
            
            HStack(spacing: Theme.Spacing.large) {
                Button(action: {
                    Theme.Haptics.impact(.light)
                    withAnimation(Theme.Animation.bouncy) {
                        isLiked.toggle()
                        likeScale = 1.3
                    }
                    withAnimation(Theme.Animation.quick.delay(0.1)) {
                        likeScale = 1.0
                    }
                }) {
                    HStack(spacing: Theme.Spacing.xSmall) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : Color.App.textSecondary)
                            .scaleEffect(likeScale)
                        
                        Text("\(discovery.likes + (isLiked ? 1 : 0))")
                            .font(Typography.Fonts.caption1(.medium))
                            .foregroundColor(Color.App.textSecondary)
                    }
                }
                
                HStack(spacing: Theme.Spacing.xSmall) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(Color.App.textSecondary)
                    
                    Text("\(discovery.comments)")
                        .font(Typography.Fonts.caption1(.medium))
                        .foregroundColor(Color.App.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    Theme.Haptics.selection()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color.App.textSecondary)
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color.gray.opacity(0.05))
        )
    }
}