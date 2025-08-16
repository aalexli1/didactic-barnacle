//
//  CreateTreasureView.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct CreateTreasureView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var selectedTreasure = TreasureType.chest
    @State private var message = ""
    @State private var visibility = TreasureVisibility.everyone
    @State private var expiresIn = TreasureExpiration.never
    
    var body: some View {
        NavigationView {
            VStack {
                ProgressBar(currentStep: currentStep, totalSteps: 4)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.top, Theme.Spacing.small)
                
                TabView(selection: $currentStep) {
                    TreasureSelectionStep(selectedTreasure: $selectedTreasure)
                        .tag(0)
                    
                    MessageComposerStep(message: $message)
                        .tag(1)
                    
                    VisibilitySettingsStep(
                        visibility: $visibility,
                        expiresIn: $expiresIn
                    )
                        .tag(2)
                    
                    PreviewStep(
                        treasure: selectedTreasure,
                        message: message,
                        visibility: visibility,
                        expiresIn: expiresIn
                    )
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                HStack(spacing: Theme.Spacing.medium) {
                    if currentStep > 0 {
                        Button(action: {
                            Theme.Haptics.selection()
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Back")
                                .font(Typography.Fonts.headline(.semibold))
                                .foregroundColor(Color.App.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.medium)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }
                    
                    Button(action: {
                        Theme.Haptics.impact(.medium)
                        if currentStep < 3 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            createTreasure()
                        }
                    }) {
                        Text(currentStep == 3 ? "Place Treasure" : "Next")
                            .font(Typography.Fonts.headline(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.medium)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .fill(Color.Gradient.magical)
                            )
                    }
                    .disabled(!isStepValid)
                }
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.medium)
            }
            .navigationTitle("Create Treasure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    var isStepValid: Bool {
        switch currentStep {
        case 1: return !message.isEmpty
        default: return true
        }
    }
    
    func createTreasure() {
        Theme.Haptics.notification(.success)
        isPresented = false
    }
}

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(Color.Gradient.magical)
                    .frame(
                        width: geometry.size.width * (Double(currentStep + 1) / Double(totalSteps)),
                        height: 4
                    )
                    .animation(Theme.Animation.smooth, value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

enum TreasureType: String, CaseIterable {
    case chest = "Treasure Chest"
    case gem = "Crystal Gem"
    case scroll = "Ancient Scroll"
    case potion = "Magic Potion"
    case coin = "Golden Coin"
    case key = "Mystic Key"
    
    var icon: String {
        switch self {
        case .chest: return "shippingbox.fill"
        case .gem: return "diamond.fill"
        case .scroll: return "scroll.fill"
        case .potion: return "drop.fill"
        case .coin: return "bitcoinsign.circle.fill"
        case .key: return "key.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .chest: return Color.App.treasureGold
        case .gem: return Color.App.magicalPurple
        case .scroll: return Color.brown
        case .potion: return Color.App.discoveryBlue
        case .coin: return Color.orange
        case .key: return Color.App.mapGreen
        }
    }
}

struct TreasureSelectionStep: View {
    @Binding var selectedTreasure: TreasureType
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Text("Choose Your Treasure")
                .font(Typography.Fonts.title2(.bold))
                .foregroundColor(Color.App.textPrimary)
                .padding(.top, Theme.Spacing.xLarge)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.medium) {
                ForEach(TreasureType.allCases, id: \.self) { treasure in
                    TreasureOption(
                        treasure: treasure,
                        isSelected: selectedTreasure == treasure,
                        action: {
                            Theme.Haptics.selection()
                            withAnimation(Theme.Animation.smooth) {
                                selectedTreasure = treasure
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
            
            Spacer()
        }
    }
}

struct TreasureOption: View {
    let treasure: TreasureType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.small) {
                ZStack {
                    Circle()
                        .fill(treasure.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: treasure.icon)
                        .font(.system(size: 36))
                        .foregroundColor(treasure.color)
                }
                
                Text(treasure.rawValue)
                    .font(Typography.Fonts.caption1(.semibold))
                    .foregroundColor(isSelected ? treasure.color : Color.App.textSecondary)
            }
            .padding(Theme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? treasure.color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
    }
}

struct MessageComposerStep: View {
    @Binding var message: String
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Text("Write Your Message")
                .font(Typography.Fonts.title2(.bold))
                .foregroundColor(Color.App.textPrimary)
                .padding(.top, Theme.Spacing.xLarge)
            
            Text("Leave a message for whoever discovers your treasure")
                .font(Typography.Fonts.body(.regular))
                .foregroundColor(Color.App.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.large)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.gray.opacity(0.05))
                
                TextEditor(text: $message)
                    .padding(Theme.Spacing.small)
                    .focused($isTextEditorFocused)
                    .onAppear {
                        isTextEditorFocused = true
                    }
                
                if message.isEmpty {
                    Text("Type your message here...")
                        .font(Typography.Fonts.body(.regular))
                        .foregroundColor(Color.App.textSecondary)
                        .padding(Theme.Spacing.medium)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 200)
            .padding(.horizontal, Theme.Spacing.medium)
            
            HStack {
                Image(systemName: "character.cursor.ibeam")
                    .foregroundColor(Color.App.textSecondary)
                
                Text("\(message.count) / 280")
                    .font(Typography.Fonts.caption1(.regular))
                    .foregroundColor(message.count > 280 ? .red : Color.App.textSecondary)
            }
            
            Spacer()
        }
    }
}

enum TreasureVisibility: String, CaseIterable {
    case everyone = "Everyone"
    case friends = "Friends Only"
    case specific = "Specific People"
    
    var icon: String {
        switch self {
        case .everyone: return "globe"
        case .friends: return "person.2.fill"
        case .specific: return "person.fill"
        }
    }
}

enum TreasureExpiration: String, CaseIterable {
    case never = "Never"
    case oneDay = "24 Hours"
    case oneWeek = "1 Week"
    case oneMonth = "1 Month"
}

struct VisibilitySettingsStep: View {
    @Binding var visibility: TreasureVisibility
    @Binding var expiresIn: TreasureExpiration
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Text("Visibility Settings")
                .font(Typography.Fonts.title2(.bold))
                .foregroundColor(Color.App.textPrimary)
                .padding(.top, Theme.Spacing.xLarge)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Who can find this treasure?")
                    .font(Typography.Fonts.headline(.semibold))
                    .foregroundColor(Color.App.textPrimary)
                
                ForEach(TreasureVisibility.allCases, id: \.self) { option in
                    VisibilityOption(
                        option: option,
                        isSelected: visibility == option,
                        action: {
                            Theme.Haptics.selection()
                            visibility = option
                        }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Expires In")
                    .font(Typography.Fonts.headline(.semibold))
                    .foregroundColor(Color.App.textPrimary)
                
                Picker("Expires In", selection: $expiresIn) {
                    ForEach(TreasureExpiration.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal, Theme.Spacing.medium)
            
            Spacer()
        }
    }
}

struct VisibilityOption: View {
    let option: TreasureVisibility
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: option.icon)
                    .foregroundColor(isSelected ? Color.App.magicalPurple : Color.App.textSecondary)
                
                Text(option.rawValue)
                    .font(Typography.Fonts.body(.regular))
                    .foregroundColor(Color.App.textPrimary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.App.magicalPurple : Color.gray)
            }
            .padding(Theme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isSelected ? Color.App.magicalPurple.opacity(0.1) : Color.gray.opacity(0.05))
            )
        }
    }
}

struct PreviewStep: View {
    let treasure: TreasureType
    let message: String
    let visibility: TreasureVisibility
    let expiresIn: TreasureExpiration
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Text("Preview Your Treasure")
                .font(Typography.Fonts.title2(.bold))
                .foregroundColor(Color.App.textPrimary)
                .padding(.top, Theme.Spacing.xLarge)
            
            VStack(spacing: Theme.Spacing.large) {
                ZStack {
                    Circle()
                        .fill(treasure.color.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: treasure.icon)
                        .font(.system(size: 60))
                        .foregroundColor(treasure.color)
                }
                
                Text(treasure.rawValue)
                    .font(Typography.Fonts.headline(.semibold))
                    .foregroundColor(Color.App.textPrimary)
                
                Text(message)
                    .font(Typography.Fonts.body(.regular))
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.large)
                
                VStack(spacing: Theme.Spacing.small) {
                    HStack {
                        Image(systemName: visibility.icon)
                            .foregroundColor(Color.App.textSecondary)
                        Text(visibility.rawValue)
                            .font(Typography.Fonts.caption1(.regular))
                            .foregroundColor(Color.App.textSecondary)
                    }
                    
                    if expiresIn != .never {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Color.App.textSecondary)
                            Text("Expires in \(expiresIn.rawValue)")
                                .font(Typography.Fonts.caption1(.regular))
                                .foregroundColor(Color.App.textSecondary)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(Color.gray.opacity(0.05))
            )
            .padding(.horizontal, Theme.Spacing.medium)
            
            Spacer()
        }
    }
}