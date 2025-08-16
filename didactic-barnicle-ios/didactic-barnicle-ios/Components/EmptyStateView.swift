//
//  EmptyStateView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Color.Gradient.magical.opacity(0.5))
                .accessibilityHidden(true)
            
            VStack(spacing: Theme.Spacing.small) {
                Text(title)
                    .font(Typography.Fonts.title2(.bold))
                    .foregroundColor(Color.App.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Text(message)
                    .font(Typography.Fonts.body(.regular))
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.large)
            }
            .accessibilityElement(children: .combine)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    Theme.Haptics.impact(.medium)
                    action()
                }) {
                    Text(actionTitle)
                        .font(Typography.Fonts.headline(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.large)
                        .padding(.vertical, Theme.Spacing.medium)
                        .background(Color.Gradient.magical)
                        .cornerRadius(Theme.CornerRadius.medium)
                }
                .accessibilityLabel(actionTitle)
                .accessibilityHint("Double tap to \(actionTitle.lowercased())")
            }
        }
        .padding(Theme.Spacing.xLarge)
    }
}