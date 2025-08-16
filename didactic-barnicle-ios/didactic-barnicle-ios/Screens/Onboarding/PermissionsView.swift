//
//  PermissionsView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct PermissionsView: View {
    @Binding var permissionsGranted: Bool
    @State private var cameraPermission = false
    @State private var locationPermission = false
    @State private var notificationPermission = false
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            VStack(spacing: Theme.Spacing.medium) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.Gradient.magical)
                    .padding(.top, Theme.Spacing.xxLarge)
                
                Text("Permissions Needed")
                    .font(Typography.Fonts.title1(.bold))
                    .foregroundColor(Color.App.textPrimary)
                
                Text("To create the best AR experience, we need a few permissions")
                    .font(Typography.Fonts.body(.regular))
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.large)
            }
            
            VStack(spacing: Theme.Spacing.medium) {
                PermissionRow(
                    icon: "camera.fill",
                    title: "Camera",
                    description: "Required for AR experiences",
                    isGranted: $cameraPermission,
                    action: requestCameraPermission
                )
                
                PermissionRow(
                    icon: "location.fill",
                    title: "Location",
                    description: "Find treasures near you",
                    isGranted: $locationPermission,
                    action: requestLocationPermission
                )
                
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get notified of discoveries",
                    isGranted: $notificationPermission,
                    action: requestNotificationPermission
                )
            }
            .padding(.horizontal, Theme.Spacing.large)
            
            Spacer()
            
            Button(action: {
                Theme.Haptics.impact(.medium)
                permissionsGranted = true
            }) {
                Text(allPermissionsGranted ? "Continue" : "Skip for Now")
                    .font(Typography.Fonts.headline(.semibold))
                    .foregroundColor(allPermissionsGranted ? .white : Color.App.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.medium)
                    .background(
                        allPermissionsGranted
                            ? AnyView(Color.Gradient.magical)
                            : AnyView(Color.gray.opacity(0.2))
                    )
                    .cornerRadius(Theme.CornerRadius.medium)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.bottom, Theme.Spacing.xLarge)
        }
    }
    
    var allPermissionsGranted: Bool {
        cameraPermission && locationPermission && notificationPermission
    }
    
    func requestCameraPermission() {
        Theme.Haptics.selection()
        cameraPermission = true
    }
    
    func requestLocationPermission() {
        Theme.Haptics.selection()
        locationPermission = true
    }
    
    func requestNotificationPermission() {
        Theme.Haptics.selection()
        notificationPermission = true
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isGranted ? Color.App.success : Color.App.discoveryBlue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.Fonts.headline(.semibold))
                    .foregroundColor(Color.App.textPrimary)
                
                Text(description)
                    .font(Typography.Fonts.caption1(.regular))
                    .foregroundColor(Color.App.textSecondary)
            }
            
            Spacer()
            
            Button(action: action) {
                Text(isGranted ? "Granted" : "Allow")
                    .font(Typography.Fonts.caption1(.semibold))
                    .foregroundColor(isGranted ? Color.App.success : Color.App.discoveryBlue)
                    .padding(.horizontal, Theme.Spacing.small)
                    .padding(.vertical, Theme.Spacing.xSmall)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(isGranted ? Color.App.success.opacity(0.1) : Color.App.discoveryBlue.opacity(0.1))
                    )
            }
            .disabled(isGranted)
        }
        .padding(Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color.gray.opacity(0.05))
        )
    }
}