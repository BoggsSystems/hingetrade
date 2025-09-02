//
//  WatchlistView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var watchlistViewModel = WatchlistViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: WatchlistSection?
    @State private var selectedWatchlist: Watchlist?
    @State private var showingAddSymbolView = false
    @State private var showingCreateWatchlistView = false
    @State private var searchText = ""
    @State private var isSearchMode = false
    
    enum WatchlistSection: Hashable {
        case back
        case search
        case createWatchlist
        case addSymbol
        case watchlistItem(String)
        case symbolItem(String)
        case filterOption(WatchlistFilter)
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                watchlistHeaderView
                
                // Search and Filters
                if isSearchMode {
                    searchBarView
                } else {
                    filtersView
                }
                
                // Content
                watchlistContentView
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await watchlistViewModel.loadWatchlists()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(isPresented: $showingAddSymbolView) {
            AddSymbolToWatchlistView(watchlist: selectedWatchlist)
                .environmentObject(watchlistViewModel)
        }
        .sheet(isPresented: $showingCreateWatchlistView) {
            CreateWatchlistView()
                .environmentObject(watchlistViewModel)
        }
    }
    
    // MARK: - Header
    
    private var watchlistHeaderView: some View {
        VStack(spacing: 20) {
            // Top Bar
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                Text("Watchlists")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Search Toggle
                    FocusableButton(
                        isSearchMode ? "Cancel" : "Search",
                        systemImage: isSearchMode ? "xmark" : "magnifyingglass"
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSearchMode.toggle()
                            searchText = ""
                        }
                    }
                    .focused($focusedSection, equals: .search)
                    
                    // Create Watchlist
                    FocusableButton("New List", systemImage: "plus.circle.fill") {
                        showingCreateWatchlistView = true
                    }
                    .focused($focusedSection, equals: .createWatchlist)
                }
            }
            .padding(.horizontal, 60)
            .padding(.top, 40)
            
            // Stats Row
            if !watchlistViewModel.watchlists.isEmpty {
                watchlistStatsView
            }
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var watchlistStatsView: some View {
        HStack(spacing: 40) {
            StatCard(
                title: "Total Lists",
                value: watchlistViewModel.watchlists.count.formatted(.number),
                color: .blue
            )
            
            StatCard(
                title: "Total Symbols",
                value: watchlistViewModel.totalSymbolCount.formatted(.number),
                color: .green
            )
            
            StatCard(
                title: "Gainers",
                value: watchlistViewModel.gainersCount.formatted(.number),
                color: .green
            )
            
            StatCard(
                title: "Losers",
                value: watchlistViewModel.losersCount.formatted(.number),
                color: .red
            )
            
            Spacer()
        }
        .padding(.horizontal, 60)
        .padding(.bottom, 20)
    }
    
    // MARK: - Search Bar
    
    private var searchBarView: some View {
        HStack(spacing: 16) {
            TextField("Search symbols or watchlists...", text: $searchText)
                .textFieldStyle(SearchFieldStyle())
                .onChange(of: searchText) { newValue in
                    watchlistViewModel.searchSymbols(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                    watchlistViewModel.clearSearch()
                }
                .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Filters
    
    private var filtersView: some View {
        HStack(spacing: 16) {
            ForEach(WatchlistFilter.allCases, id: \.self) { filter in
                FilterButton(
                    filter: filter,
                    isSelected: watchlistViewModel.selectedFilter == filter,
                    isFocused: focusedSection == .filterOption(filter)
                ) {
                    watchlistViewModel.setFilter(filter)
                }
                .focused($focusedSection, equals: .filterOption(filter))
            }
            
            Spacer()
            
            // Sort Options
            Menu("Sort") {
                ForEach(WatchlistSortOption.allCases, id: \.self) { sortOption in
                    Button(sortOption.displayName) {
                        watchlistViewModel.setSortOption(sortOption)
                    }
                }
            }
            .foregroundColor(.white)
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Content
    
    private var watchlistContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                if isSearchMode && !searchText.isEmpty {
                    searchResultsView
                } else if watchlistViewModel.isLoading {
                    LoadingStateView(message: "Loading watchlists...")
                        .frame(height: 200)
                } else if watchlistViewModel.filteredWatchlists.isEmpty {
                    emptyWatchlistsView
                } else {
                    watchlistsGridView
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if watchlistViewModel.isSearching {
                LoadingStateView(message: "Searching...")
                    .frame(height: 100)
            } else {
                // Search results for symbols
                if !watchlistViewModel.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Symbols")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(watchlistViewModel.searchResults, id: \.symbol) { result in
                                SearchResultCard(
                                    searchResult: result,
                                    isFocused: focusedSection == .symbolItem(result.symbol)
                                ) {
                                    // Show add to watchlist options
                                    selectedWatchlist = nil
                                    showingAddSymbolView = true
                                }
                                .focused($focusedSection, equals: .symbolItem(result.symbol))
                            }
                        }
                    }
                }
                
                // Search results for watchlists
                if !watchlistViewModel.matchingWatchlists.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Watchlists")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                            ForEach(watchlistViewModel.matchingWatchlists, id: \.id) { watchlist in
                                WatchlistCard(
                                    watchlist: watchlist,
                                    isFocused: focusedSection == .watchlistItem(watchlist.id)
                                ) {
                                    selectedWatchlist = watchlist
                                }
                                .focused($focusedSection, equals: .watchlistItem(watchlist.id))
                            }
                        }
                    }
                }
                
                // No results
                if watchlistViewModel.searchResults.isEmpty && watchlistViewModel.matchingWatchlists.isEmpty && !searchText.isEmpty {
                    EmptyStateView(
                        title: "No Results Found",
                        message: "Try searching for a different symbol or watchlist name",
                        systemImage: "magnifyingglass"
                    )
                }
            }
        }
    }
    
    // MARK: - Watchlists Grid
    
    private var watchlistsGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
            ForEach(watchlistViewModel.filteredWatchlists, id: \.id) { watchlist in
                WatchlistCard(
                    watchlist: watchlist,
                    isFocused: focusedSection == .watchlistItem(watchlist.id),
                    showQuickActions: true
                ) {
                    selectedWatchlist = watchlist
                }
                .focused($focusedSection, equals: .watchlistItem(watchlist.id))
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyWatchlistsView: some View {
        EmptyStateView(
            title: "No Watchlists Yet",
            message: "Create your first watchlist to start tracking your favorite symbols",
            systemImage: "star.circle",
            actionTitle: "Create Watchlist",
            action: {
                showingCreateWatchlistView = true
            }
        )
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct FilterButton: View {
    let filter: WatchlistFilter
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.systemImage)
                    .font(.body)
                
                Text(filter.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(buttonForegroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var buttonForegroundColor: Color {
        if isFocused {
            return .black
        } else if isSelected {
            return .green
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return Color.green.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return .green
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

struct SearchFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.title2)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .stroke(Color.green, lineWidth: 1)
            )
    }
}

struct WatchlistCard: View {
    let watchlist: Watchlist
    let isFocused: Bool
    let showQuickActions: Bool
    let onTap: () -> Void
    
    init(watchlist: Watchlist, isFocused: Bool, showQuickActions: Bool = false, onTap: @escaping () -> Void) {
        self.watchlist = watchlist
        self.isFocused = isFocused
        self.showQuickActions = showQuickActions
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(watchlist.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text("\(watchlist.symbols.count) symbols")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Performance indicator
                    if let performance = watchlist.dailyPerformance {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(performance.formatted(.percent.precision(.fractionLength(2))))
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(performance >= 0 ? .green : .red)
                            
                            Image(systemName: performance >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                                .foregroundColor(performance >= 0 ? .green : .red)
                        }
                    }
                }
                
                // Symbol preview
                if !watchlist.symbols.isEmpty {
                    symbolPreviewView
                }
                
                // Quick stats
                HStack {
                    Label("\(watchlist.gainers)", systemImage: "arrow.up")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Label("\(watchlist.losers)", systemImage: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text("Updated \(watchlist.lastUpdated?.formatted(.relative(presentation: .named)) ?? "Never")")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green, lineWidth: isFocused ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var symbolPreviewView: some View {
        HStack {
            ForEach(Array(watchlist.symbols.prefix(5)), id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.3))
                    )
            }
            
            if watchlist.symbols.count > 5 {
                Text("+\(watchlist.symbols.count - 5)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

struct SearchResultCard: View {
    let searchResult: SymbolSearchResult
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(searchResult.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(searchResult.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let price = searchResult.price {
                        Text(price.formatted(.currency(code: "USD")))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    if let change = searchResult.changePercent {
                        Text(change.formatted(.percent.precision(.fractionLength(2))))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
                
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green, lineWidth: isFocused ? 1 : 0)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    WatchlistView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}