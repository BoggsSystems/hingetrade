//
//  CreateWatchlistView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct CreateWatchlistView: View {
    @EnvironmentObject private var watchlistViewModel: WatchlistViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: CreateWatchlistField?
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor: WatchlistColor = .blue
    @State private var isPublic = false
    @State private var selectedSymbols: [String] = []
    @State private var symbolSearchText = ""
    @State private var isCreating = false
    
    enum CreateWatchlistField: Hashable {
        case name
        case description
        case symbolSearch
        case create
        case cancel
        case colorOption(WatchlistColor)
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 30) {
                // Header
                createWatchlistHeader
                
                // Form Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Basic Info Section
                        basicInfoSection
                        
                        // Color Selection
                        colorSelectionSection
                        
                        // Initial Symbols (Optional)
                        initialSymbolsSection
                        
                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 30)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            // Auto-focus name field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .name
            }
        }
    }
    
    // MARK: - Header
    
    private var createWatchlistHeader: some View {
        HStack {
            FocusableButton("Cancel", systemImage: "xmark") {
                dismiss()
            }
            .focused($focusedField, equals: .cancel)
            
            Spacer()
            
            Text("Create Watchlist")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear.frame(width: 120)
        }
        .padding(.horizontal, 60)
        .padding(.top, 40)
    }
    
    // MARK: - Basic Info
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Watchlist Name")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextField("e.g., Tech Stocks, Growth Plays", text: $name)
                        .textFieldStyle(WatchlistInputFieldStyle(isFocused: focusedField == .name))
                        .focused($focusedField, equals: .name)
                }
                
                // Description Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextField("What's this watchlist for?", text: $description)
                        .textFieldStyle(WatchlistInputFieldStyle(isFocused: focusedField == .description))
                        .focused($focusedField, equals: .description)
                }
                
                // Privacy Toggle
                HStack {
                    Toggle(isOn: $isPublic) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Make Public")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text("Other users can view and follow this watchlist")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .tint(.green)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Color Selection
    
    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Color Theme")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(WatchlistColor.allCases, id: \.self) { color in
                    ColorOption(
                        color: color,
                        isSelected: selectedColor == color,
                        isFocused: focusedField == .colorOption(color)
                    ) {
                        selectedColor = color
                    }
                    .focused($focusedField, equals: .colorOption(color))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Initial Symbols
    
    private var initialSymbolsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Starting Symbols (Optional)")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Symbol Search
                HStack(spacing: 12) {
                    TextField("Enter symbol (e.g., AAPL)", text: $symbolSearchText)
                        .textFieldStyle(WatchlistInputFieldStyle(isFocused: focusedField == .symbolSearch))
                        .focused($focusedField, equals: .symbolSearch)
                        .onSubmit {
                            addSymbolFromSearch()
                        }
                    
                    Button("Add") {
                        addSymbolFromSearch()
                    }
                    .disabled(symbolSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(.green)
                }
                
                // Selected Symbols
                if !selectedSymbols.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Symbols (\(selectedSymbols.count))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(selectedSymbols, id: \.self) { symbol in
                                SymbolChip(symbol: symbol) {
                                    selectedSymbols.removeAll { $0 == symbol }
                                }
                            }
                        }
                    }
                } else {
                    Text("You can add symbols now or later from the watchlist")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            FocusableButton(
                isCreating ? "Creating..." : "Create Watchlist",
                systemImage: "plus.circle.fill"
            ) {
                Task {
                    await createWatchlist()
                }
            }
            .focused($focusedField, equals: .create)
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
            
            Text("You can modify this watchlist anytime after creation")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Actions
    
    private func addSymbolFromSearch() {
        let trimmedSymbol = symbolSearchText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !trimmedSymbol.isEmpty,
              !selectedSymbols.contains(trimmedSymbol),
              selectedSymbols.count < 20 else { return }
        
        selectedSymbols.append(trimmedSymbol)
        symbolSearchText = ""
    }
    
    private func createWatchlist() async {
        isCreating = true
        
        let newWatchlist = Watchlist(
            id: UUID().uuidString,
            accountId: "account-001", // Would be from app state
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            items: selectedSymbols,
            createdAt: Date(),
            updatedAt: Date(),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            isDefault: false,
            sortOrder: nil,
            color: selectedColor.hexString,
            isPublic: isPublic,
            isFavorite: false,
            dailyPerformance: nil,
            gainers: 0,
            losers: 0,
            lastUpdated: nil
        )
        
        await watchlistViewModel.createWatchlist(newWatchlist)
        
        isCreating = false
        dismiss()
    }
}

// MARK: - Supporting Views

struct WatchlistInputFieldStyle: TextFieldStyle {
    let isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .stroke(isFocused ? Color.green : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct ColorOption: View {
    let color: WatchlistColor
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: color.hexString))
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green, lineWidth: isFocused ? 2 : 0)
                    )
                
                Text(color.displayName)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct SymbolChip: View {
    let symbol: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(symbol)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.3))
        )
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    CreateWatchlistView()
        .environmentObject(WatchlistViewModel())
        .preferredColorScheme(.dark)
}