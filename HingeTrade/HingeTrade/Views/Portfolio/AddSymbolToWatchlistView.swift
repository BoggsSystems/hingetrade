//
//  AddSymbolToWatchlistView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct AddSymbolToWatchlistView: View {
    let watchlist: Watchlist?
    let symbol: String?
    
    @EnvironmentObject private var watchlistViewModel: WatchlistViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: AddSymbolSection?
    
    @State private var selectedWatchlists: Set<String> = []
    @State private var isAdding = false
    
    enum AddSymbolSection: Hashable {
        case close
        case watchlist(String)
        case add
        case createNew
    }
    
    init(watchlist: Watchlist? = nil, symbol: String? = nil) {
        self.watchlist = watchlist
        self.symbol = symbol
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 30) {
                // Header
                addSymbolHeader
                
                // Symbol Info (if provided)
                if let symbol = symbol {
                    symbolInfoSection(symbol)
                }
                
                // Watchlist Selection
                watchlistSelectionSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            setupInitialSelection()
            
            // Auto-focus close button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .close
            }
        }
    }
    
    // MARK: - Header
    
    private var addSymbolHeader: some View {
        HStack {
            FocusableButton("Close", systemImage: "xmark") {
                dismiss()
            }
            .focused($focusedSection, equals: .close)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Add to Watchlist")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let symbol = symbol {
                    Text(symbol)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Placeholder for balance
            Color.clear.frame(width: 120)
        }
    }
    
    // MARK: - Symbol Info
    
    private func symbolInfoSection(_ symbol: String) -> some View {
        VStack(spacing: 16) {
            Text("Symbol Information")
                .font(.headline)
                .foregroundColor(.white)
            
            // This would typically show real market data
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(symbol)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Apple Inc.") // Would be fetched from API
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("$175.50") // Would be real price
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                        Text("+1.2%")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Watchlist Selection
    
    private var watchlistSelectionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Select Watchlists")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(selectedWatchlists.count) selected")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(watchlistViewModel.watchlists, id: \.id) { watchlistItem in
                        WatchlistSelectionRow(
                            watchlist: watchlistItem,
                            isSelected: selectedWatchlists.contains(watchlistItem.id),
                            isFocused: focusedSection == .watchlist(watchlistItem.id),
                            containsSymbol: symbol != nil ? watchlistItem.symbols.contains(symbol!) : false
                        ) {
                            toggleWatchlistSelection(watchlistItem.id)
                        }
                        .focused($focusedSection, equals: .watchlist(watchlistItem.id))
                    }
                    
                    // Create New Watchlist Option
                    CreateNewWatchlistRow(
                        isFocused: focusedSection == .createNew
                    ) {
                        // Present create watchlist view
                        // This would typically show another modal
                    }
                    .focused($focusedSection, equals: .createNew)
                }
            }
            .frame(maxHeight: 300)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            FocusableButton(
                isAdding ? "Adding..." : "Add to Watchlists",
                systemImage: "plus.circle.fill"
            ) {
                Task {
                    await addToSelectedWatchlists()
                }
            }
            .focused($focusedSection, equals: .add)
            .disabled(selectedWatchlists.isEmpty || isAdding)
            
            if selectedWatchlists.isEmpty {
                Text("Select at least one watchlist")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text("Will be added to \(selectedWatchlists.count) watchlist\(selectedWatchlists.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Actions
    
    private func setupInitialSelection() {
        if let watchlist = watchlist {
            selectedWatchlists.insert(watchlist.id)
        }
    }
    
    private func toggleWatchlistSelection(_ watchlistId: String) {
        if selectedWatchlists.contains(watchlistId) {
            selectedWatchlists.remove(watchlistId)
        } else {
            selectedWatchlists.insert(watchlistId)
        }
    }
    
    private func addToSelectedWatchlists() async {
        guard let symbol = symbol else { return }
        
        isAdding = true
        
        await withTaskGroup(of: Void.self) { group in
            for watchlistId in selectedWatchlists {
                group.addTask {
                    await watchlistViewModel.addSymbolToWatchlist(symbol: symbol, watchlistId: watchlistId)
                }
            }
        }
        
        isAdding = false
        dismiss()
    }
}

// MARK: - Supporting Views

struct WatchlistSelectionRow: View {
    let watchlist: Watchlist
    let isSelected: Bool
    let isFocused: Bool
    let containsSymbol: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: containsSymbol ? {} : onTap) {
            HStack(spacing: 16) {
                // Selection indicator
                if containsSymbol {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .green : .gray)
                }
                
                // Watchlist info
                VStack(alignment: .leading, spacing: 4) {
                    Text(watchlist.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("\(watchlist.symbols.count) symbols")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Status indicator
                if containsSymbol {
                    Text("Already Added")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green.opacity(0.2))
                        )
                } else if let performance = watchlist.dailyPerformance {
                    Text(performance.formatted(.percent.precision(.fractionLength(2))))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(performance >= 0 ? .green : .red)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(containsSymbol)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var borderColor: Color {
        if containsSymbol {
            return .green.opacity(0.5)
        } else if isFocused {
            return .green
        } else if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        if containsSymbol || isFocused || isSelected {
            return 1
        } else {
            return 0
        }
    }
}

struct CreateNewWatchlistRow: View {
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create New Watchlist")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Start a fresh watchlist for this symbol")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
                    .stroke(Color.green, lineWidth: isFocused ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    AddSymbolToWatchlistView(symbol: "AAPL")
        .environmentObject(WatchlistViewModel())
        .preferredColorScheme(.dark)
}