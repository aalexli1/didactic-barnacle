import SwiftUI

struct TreasureFilterView: View {
    @Binding var selectedTypes: Set<TreasureType>
    @Binding var selectedDifficulties: Set<Difficulty>
    @Binding var showOnlyUncollected: Bool
    @Binding var maxDistance: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Type filters
                Section("Treasure Types") {
                    ForEach(TreasureType.allCases, id: \.self) { type in
                        HStack {
                            Label(type.rawValue.capitalized, systemImage: typeIcon(for: type))
                                .foregroundColor(typeColor(for: type))
                            
                            Spacer()
                            
                            if selectedTypes.contains(type) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelection(type, in: &selectedTypes)
                        }
                    }
                }
                
                // Difficulty filters
                Section("Difficulty") {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        HStack {
                            Label(difficulty.rawValue.capitalized, systemImage: "star.fill")
                                .foregroundColor(difficultyColor(for: difficulty))
                            
                            Spacer()
                            
                            Text("\(difficulty.basePoints) pts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if selectedDifficulties.contains(difficulty) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelection(difficulty, in: &selectedDifficulties)
                        }
                    }
                }
                
                // Distance filter
                Section("Maximum Distance") {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                            Text("\(Int(maxDistance))m")
                                .font(.headline)
                            Spacer()
                            Text(distanceDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $maxDistance, in: 100...5000, step: 100)
                            .accentColor(.blue)
                    }
                }
                
                // Collection status
                Section("Status") {
                    Toggle(isOn: $showOnlyUncollected) {
                        Label("Show only uncollected", systemImage: "eye.slash.fill")
                    }
                }
                
                // Quick presets
                Section("Quick Filters") {
                    Button(action: applyNearbyPreset) {
                        Label("Nearby (< 500m)", systemImage: "location.fill")
                    }
                    
                    Button(action: applyHighValuePreset) {
                        Label("High Value (50+ points)", systemImage: "star.circle.fill")
                    }
                    
                    Button(action: applyBeginnerPreset) {
                        Label("Beginner Friendly", systemImage: "graduationcap.fill")
                    }
                    
                    Button(action: resetFilters) {
                        Label("Reset All Filters", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filter Treasures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var distanceDescription: String {
        switch maxDistance {
        case 0..<500:
            return "Very close"
        case 500..<1000:
            return "Walking distance"
        case 1000..<2000:
            return "Short trip"
        case 2000..<3500:
            return "Moderate distance"
        default:
            return "Extended range"
        }
    }
    
    private func toggleSelection<T: Hashable>(_ item: T, in set: inout Set<T>) {
        if set.contains(item) {
            set.remove(item)
        } else {
            set.insert(item)
        }
    }
    
    private func typeIcon(for type: TreasureType) -> String {
        switch type {
        case .standard: return "star.fill"
        case .premium: return "crown.fill"
        case .special: return "sparkles"
        case .event: return "gift.fill"
        }
    }
    
    private func typeColor(for type: TreasureType) -> Color {
        switch type {
        case .standard: return .blue
        case .premium: return .purple
        case .special: return .orange
        case .event: return .pink
        }
    }
    
    private func difficultyColor(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .legendary: return .purple
        }
    }
    
    private func applyNearbyPreset() {
        maxDistance = 500
        selectedTypes = Set(TreasureType.allCases)
        selectedDifficulties = Set(Difficulty.allCases)
    }
    
    private func applyHighValuePreset() {
        selectedDifficulties = [.hard, .legendary]
        selectedTypes = [.premium, .special, .event]
        maxDistance = 2000
    }
    
    private func applyBeginnerPreset() {
        selectedDifficulties = [.easy, .medium]
        selectedTypes = [.standard]
        maxDistance = 1000
    }
    
    private func resetFilters() {
        selectedTypes = Set(TreasureType.allCases)
        selectedDifficulties = Set(Difficulty.allCases)
        showOnlyUncollected = true
        maxDistance = 1000
    }
}