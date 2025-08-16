//
//  ErrorView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct ErrorView: View {
    let error: AppError
    let retry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundColor(error.color)
                .accessibilityHidden(true)
            
            VStack(spacing: Theme.Spacing.small) {
                Text(error.title)
                    .font(Typography.Fonts.title2(.bold))
                    .foregroundColor(Color.App.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Text(error.message)
                    .font(Typography.Fonts.body(.regular))
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.large)
            }
            .accessibilityElement(children: .combine)
            
            if let retry = retry {
                Button(action: {
                    Theme.Haptics.impact(.medium)
                    retry()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                            .font(Typography.Fonts.headline(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.large)
                    .padding(.vertical, Theme.Spacing.medium)
                    .background(Color.App.error)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                .accessibilityLabel("Try Again")
                .accessibilityHint("Double tap to retry")
            }
        }
        .padding(Theme.Spacing.xLarge)
    }
}

enum AppError {
    case network
    case location
    case permission
    case general(String)
    
    var title: String {
        switch self {
        case .network: return "Connection Error"
        case .location: return "Location Error"
        case .permission: return "Permission Required"
        case .general: return "Something Went Wrong"
        }
    }
    
    var message: String {
        switch self {
        case .network: 
            return "Unable to connect to the internet. Please check your connection and try again."
        case .location:
            return "We couldn't determine your location. Please enable location services and try again."
        case .permission:
            return "This feature requires additional permissions. Please update your settings."
        case .general(let message):
            return message
        }
    }
    
    var icon: String {
        switch self {
        case .network: return "wifi.slash"
        case .location: return "location.slash"
        case .permission: return "lock.shield"
        case .general: return "exclamationmark.triangle"
        }
    }
    
    var color: Color {
        switch self {
        case .network: return Color.App.warning
        case .location: return Color.App.error
        case .permission: return Color.App.warning
        case .general: return Color.App.error
        }
    }
}