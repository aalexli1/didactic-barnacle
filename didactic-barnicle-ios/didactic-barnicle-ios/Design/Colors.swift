//
//  Colors.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

extension Color {
    struct App {
        static let primary = Color("PrimaryColor", bundle: nil)
        static let secondary = Color("SecondaryColor", bundle: nil)
        static let accent = Color("AccentColor", bundle: nil)
        static let background = Color("BackgroundColor", bundle: nil)
        static let surface = Color("SurfaceColor", bundle: nil)
        static let textPrimary = Color("TextPrimary", bundle: nil)
        static let textSecondary = Color("TextSecondary", bundle: nil)
        static let success = Color("SuccessColor", bundle: nil)
        static let warning = Color("WarningColor", bundle: nil)
        static let error = Color("ErrorColor", bundle: nil)
        
        static let treasureGold = Color(red: 255/255, green: 215/255, blue: 0/255)
        static let magicalPurple = Color(red: 147/255, green: 51/255, blue: 234/255)
        static let discoveryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
        static let mapGreen = Color(red: 34/255, green: 197/255, blue: 94/255)
    }
    
    struct Gradient {
        static let magical = LinearGradient(
            colors: [App.magicalPurple, App.discoveryBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let treasure = LinearGradient(
            colors: [App.treasureGold, Color.orange],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let discovery = LinearGradient(
            colors: [App.discoveryBlue, Color.cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}