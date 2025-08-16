//
//  ActivityView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct ActivityView: View {
    @State private var activities: [Activity] = Activity.sampleData
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(activities) { activity in
                        ActivityRow(activity: activity)
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct Activity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let username: String
    let action: String
    let timeAgo: String
    let isNew: Bool
    
    enum ActivityType {
        case discovery, like, comment, follow
        
        var icon: String {
            switch self {
            case .discovery: return "sparkles"
            case .like: return "heart.fill"
            case .comment: return "bubble.left.fill"
            case .follow: return "person.badge.plus.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .discovery: return Color.App.treasureGold
            case .like: return .red
            case .comment: return Color.App.discoveryBlue
            case .follow: return Color.App.magicalPurple
            }
        }
    }
    
    static let sampleData: [Activity] = [
        Activity(type: .discovery, username: "Explorer123", action: "discovered your treasure", timeAgo: "5m ago", isNew: true),
        Activity(type: .like, username: "TreasureFan", action: "liked your discovery", timeAgo: "1h ago", isNew: true),
        Activity(type: .comment, username: "AdventureGuru", action: "commented on your treasure", timeAgo: "3h ago", isNew: false),
        Activity(type: .follow, username: "NewFriend", action: "started following you", timeAgo: "1d ago", isNew: false)
    ]
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: activity.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(activity.type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.username)
                        .font(Typography.Fonts.headline(.semibold))
                        .foregroundColor(Color.App.textPrimary)
                    
                    Text(activity.action)
                        .font(Typography.Fonts.body(.regular))
                        .foregroundColor(Color.App.textSecondary)
                }
                
                Text(activity.timeAgo)
                    .font(Typography.Fonts.caption1(.regular))
                    .foregroundColor(Color.App.textSecondary)
            }
            
            Spacer()
            
            if activity.isNew {
                Circle()
                    .fill(Color.App.magicalPurple)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.small)
        .background(activity.isNew ? Color.App.magicalPurple.opacity(0.03) : Color.clear)
    }
}