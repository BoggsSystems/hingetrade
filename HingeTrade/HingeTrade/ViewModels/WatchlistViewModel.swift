//
//  WatchlistViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class WatchlistViewModel: ObservableObject {
    @Published var watchlists: [Watchlist] = []
    @Published var filteredWatchlists: [Watchlist] = []
    @Published var selectedFilter: WatchlistFilter = .all
    @Published var selectedSortOption: WatchlistSortOption = .alphabetical
    @Published var isLoading: Bool = false
    @Published var error: WatchlistError?
    @Published var showingError: Bool = false
    
    // Search functionality
    @Published var searchResults: [SymbolSearchResult] = []
    @Published var matchingWatchlists: [Watchlist] = []
    @Published var isSearching: Bool = false
    
    // Statistics
    @Published var totalSymbolCount: Int = 0
    @Published var gainersCount: Int = 0
    @Published var losersCount: Int = 0
    
    // Services
    private let watchlistService: WatchlistService
    private let marketDataService: MarketDataService
    private let searchService: SymbolSearchService
    private let webSocketService: WebSocketService
    
    private var cancellables = Set<AnyCancellable>()
    private var searchDebouncer: Timer?
    
    init(
        watchlistService: WatchlistService = WatchlistService(),
        marketDataService: MarketDataService = MarketDataService(),
        searchService: SymbolSearchService = SymbolSearchService(),
        webSocketService: WebSocketService = WebSocketService()
    ) {
        self.watchlistService = watchlistService
        self.marketDataService = marketDataService
        self.searchService = searchService
        self.webSocketService = webSocketService
        
        setupBindings()
        setupRealTimeUpdates()
    }
    
    // MARK: - Data Loading
    
    func loadWatchlists() async {
        isLoading = true
        error = nil
        
        do {
            let loadedWatchlists = try await watchlistService.getAllWatchlists()
            
            // Load real-time quotes for all symbols
            let allSymbols = Set(loadedWatchlists.flatMap { $0.symbols })
            let quotes = try await loadQuotes(for: Array(allSymbols))
            
            // Update watchlists with current market data
            self.watchlists = loadedWatchlists.map { watchlist in
                updateWatchlistWithQuotes(watchlist, quotes: quotes)
            }
            
            updateStatistics()
            applyFiltersAndSort()
            
        } catch {
            self.error = WatchlistError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    private func loadQuotes(for symbols: [String]) async throws -> [String: Quote] {
        var quotes: [String: Quote] = [:]
        
        // Load quotes in batches to avoid rate limiting
        let batchSize = 10
        for batch in symbols.chunked(into: batchSize) {
            let batchQuotes = try await marketDataService.getQuotes(symbols: batch)
            for quote in batchQuotes {
                quotes[quote.symbol] = quote
            }
        }
        
        return quotes
    }
    
    private func updateWatchlistWithQuotes(_ watchlist: Watchlist, quotes: [String: Quote]) -> Watchlist {
        var updatedWatchlist = watchlist
        
        // Calculate daily performance
        var totalValue: Decimal = 0
        var totalChange: Decimal = 0
        var gainers = 0
        var losers = 0
        
        for symbol in watchlist.symbols {
            if let quote = quotes[symbol] {
                totalValue += quote.bidPrice
                totalChange += quote.change
                
                if quote.change > 0 {
                    gainers += 1
                } else if quote.change < 0 {
                    losers += 1
                }
            }
        }
        
        updatedWatchlist.dailyPerformance = totalValue > 0 ? Double(totalChange / totalValue) : 0
        updatedWatchlist.gainers = gainers
        updatedWatchlist.losers = losers
        updatedWatchlist.lastUpdated = Date()
        
        return updatedWatchlist
    }
    
    // MARK: - Filtering and Sorting
    
    func setFilter(_ filter: WatchlistFilter) {
        selectedFilter = filter
        applyFiltersAndSort()
    }
    
    func setSortOption(_ sortOption: WatchlistSortOption) {
        selectedSortOption = sortOption
        applyFiltersAndSort()
    }
    
    private func applyFiltersAndSort() {
        var filtered = watchlists
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            filtered = filtered.filter { $0.isFavorite }
        case .gainers:
            filtered = filtered.filter { ($0.dailyPerformance ?? 0) > 0 }
        case .losers:
            filtered = filtered.filter { ($0.dailyPerformance ?? 0) < 0 }
        case .active:
            filtered = filtered.filter { $0.lastUpdated?.timeIntervalSinceNow ?? -3600 > -3600 }
        }
        
        // Apply sort
        switch selectedSortOption {
        case .alphabetical:
            filtered.sort { $0.name < $1.name }
        case .performance:
            filtered.sort { ($0.dailyPerformance ?? 0) > ($1.dailyPerformance ?? 0) }
        case .symbolCount:
            filtered.sort { $0.symbols.count > $1.symbols.count }
        case .lastUpdated:
            filtered.sort { ($0.lastUpdated ?? Date.distantPast) > ($1.lastUpdated ?? Date.distantPast) }
        case .dateCreated:
            filtered.sort { $0.createdAt > $1.createdAt }
        }
        
        filteredWatchlists = filtered
    }
    
    // MARK: - Search
    
    func searchSymbols(query: String) {
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        // Debounce search requests
        searchDebouncer?.invalidate()
        searchDebouncer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.performSearch(query: query)
            }
        }
        
        // Also search watchlists locally
        searchWatchlists(query: query)
    }
    
    private func performSearch(query: String) async {
        isSearching = true
        
        do {
            let results = try await searchService.searchSymbols(query: query, limit: 20)
            self.searchResults = results
        } catch {
            self.error = WatchlistError.searchFailed(error.localizedDescription)
        }
        
        isSearching = false
    }
    
    private func searchWatchlists(query: String) {
        let lowercaseQuery = query.lowercased()
        matchingWatchlists = watchlists.filter { watchlist in
            watchlist.name.lowercased().contains(lowercaseQuery) ||
            watchlist.symbols.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    func clearSearch() {
        searchResults = []
        matchingWatchlists = []
        searchDebouncer?.invalidate()
        isSearching = false
    }
    
    // MARK: - Watchlist Management
    
    func createWatchlist(_ watchlist: Watchlist) async {
        do {
            let createdWatchlist = try await watchlistService.createWatchlist(watchlist)
            self.watchlists.append(createdWatchlist)
            applyFiltersAndSort()
            updateStatistics()
        } catch {
            self.error = WatchlistError.creationFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func updateWatchlist(_ watchlist: Watchlist) async {
        do {
            let updatedWatchlist = try await watchlistService.updateWatchlist(watchlist)
            
            if let index = watchlists.firstIndex(where: { $0.id == watchlist.id }) {
                watchlists[index] = updatedWatchlist
                applyFiltersAndSort()
                updateStatistics()
            }
        } catch {
            self.error = WatchlistError.updateFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func deleteWatchlist(_ watchlist: Watchlist) async {
        do {
            try await watchlistService.deleteWatchlist(watchlist.id)
            watchlists.removeAll { $0.id == watchlist.id }
            applyFiltersAndSort()
            updateStatistics()
        } catch {
            self.error = WatchlistError.deletionFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func addSymbolToWatchlist(symbol: String, watchlistId: String) async {
        guard let watchlistIndex = watchlists.firstIndex(where: { $0.id == watchlistId }) else { return }
        
        do {
            var watchlist = watchlists[watchlistIndex]
            if !watchlist.symbols.contains(symbol) {
                watchlist.symbols.append(symbol)
                let updatedWatchlist = try await watchlistService.updateWatchlist(watchlist)
                watchlists[watchlistIndex] = updatedWatchlist
                applyFiltersAndSort()
                updateStatistics()
            }
        } catch {
            self.error = WatchlistError.symbolAdditionFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func removeSymbolFromWatchlist(symbol: String, watchlistId: String) async {
        guard let watchlistIndex = watchlists.firstIndex(where: { $0.id == watchlistId }) else { return }
        
        do {
            var watchlist = watchlists[watchlistIndex]
            watchlist.symbols.removeAll { $0 == symbol }
            let updatedWatchlist = try await watchlistService.updateWatchlist(watchlist)
            watchlists[watchlistIndex] = updatedWatchlist
            applyFiltersAndSort()
            updateStatistics()
        } catch {
            self.error = WatchlistError.symbolRemovalFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func toggleWatchlistFavorite(_ watchlist: Watchlist) async {
        guard let index = watchlists.firstIndex(where: { $0.id == watchlist.id }) else { return }
        
        do {
            var updatedWatchlist = watchlist
            updatedWatchlist.isFavorite.toggle()
            
            let savedWatchlist = try await watchlistService.updateWatchlist(updatedWatchlist)
            watchlists[index] = savedWatchlist
            applyFiltersAndSort()
        } catch {
            self.error = WatchlistError.updateFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // Subscribe to quote updates for all watchlist symbols
        webSocketService.quoteUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quote in
                self?.handleQuoteUpdate(quote)
            }
            .store(in: &cancellables)
    }
    
    private func handleQuoteUpdate(_ quote: Quote) {
        // Update any watchlists containing this symbol
        var hasUpdates = false
        
        for (index, watchlist) in watchlists.enumerated() {
            if watchlist.symbols.contains(quote.symbol) {
                let updatedWatchlist = updateWatchlistWithQuotes(watchlist, quotes: [quote.symbol: quote])
                watchlists[index] = updatedWatchlist
                hasUpdates = true
            }
        }
        
        if hasUpdates {
            updateStatistics()
            applyFiltersAndSort()
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        totalSymbolCount = Set(watchlists.flatMap { $0.symbols }).count
        gainersCount = watchlists.reduce(0) { $0 + $1.gainers }
        losersCount = watchlists.reduce(0) { $0 + $1.losers }
    }
    
    // MARK: - Error Handling
    
    private func setupBindings() {
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
            }
            .store(in: &cancellables)
    }
    
    func dismissError() {
        error = nil
        showingError = false
    }
    
    deinit {
        cancellables.removeAll()
        searchDebouncer?.invalidate()
    }
}

// MARK: - Supporting Types

enum WatchlistFilter: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case gainers = "Gainers"
    case losers = "Losers"
    case active = "Active"
    
    var displayName: String {
        return rawValue
    }
    
    var systemImage: String {
        switch self {
        case .all: return "list.bullet"
        case .favorites: return "heart.fill"
        case .gainers: return "arrow.up.circle.fill"
        case .losers: return "arrow.down.circle.fill"
        case .active: return "clock.fill"
        }
    }
}

enum WatchlistSortOption: String, CaseIterable {
    case alphabetical = "Alphabetical"
    case performance = "Performance"
    case symbolCount = "Symbol Count"
    case lastUpdated = "Last Updated"
    case dateCreated = "Date Created"
    
    var displayName: String {
        return rawValue
    }
}

struct SymbolSearchResult {
    let symbol: String
    let name: String
    let exchange: String
    let price: Decimal?
    let changePercent: Double?
    let volume: Int?
    let marketCap: Decimal?
    let sector: String?
}

// MARK: - Error Types

enum WatchlistError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case symbolAdditionFailed(String)
    case symbolRemovalFailed(String)
    case searchFailed(String)
    case networkError(String)
    case unauthorized
    case quotaExceeded
    case unknown(String)
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .creationFailed(let message),
             .updateFailed(let message),
             .deletionFailed(let message),
             .symbolAdditionFailed(let message),
             .symbolRemovalFailed(let message),
             .searchFailed(let message),
             .networkError(let message),
             .unknown(let message):
            return message
        case .unauthorized:
            return "unauthorized"
        case .quotaExceeded:
            return "quota_exceeded"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load watchlists: \(message)"
        case .creationFailed(let message):
            return "Failed to create watchlist: \(message)"
        case .updateFailed(let message):
            return "Failed to update watchlist: \(message)"
        case .deletionFailed(let message):
            return "Failed to delete watchlist: \(message)"
        case .symbolAdditionFailed(let message):
            return "Failed to add symbol: \(message)"
        case .symbolRemovalFailed(let message):
            return "Failed to remove symbol: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .quotaExceeded:
            return "API quota exceeded. Please try again later."
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Service Protocols

protocol WatchlistService {
    func getAllWatchlists() async throws -> [Watchlist]
    func getWatchlist(id: String) async throws -> Watchlist
    func createWatchlist(_ watchlist: Watchlist) async throws -> Watchlist
    func updateWatchlist(_ watchlist: Watchlist) async throws -> Watchlist
    func deleteWatchlist(_ id: String) async throws
}

protocol SymbolSearchService {
    func searchSymbols(query: String, limit: Int) async throws -> [SymbolSearchResult]
}

// MARK: - Default Implementations

class WatchlistService: WatchlistService {
    func getAllWatchlists() async throws -> [Watchlist] {
        try await Task.sleep(nanoseconds: 800_000_000)
        return Watchlist.sampleWatchlists
    }
    
    func getWatchlist(id: String) async throws -> Watchlist {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        if let watchlist = Watchlist.sampleWatchlists.first(where: { $0.id == id }) {
            return watchlist
        }
        
        throw WatchlistError.loadingFailed("Watchlist not found")
    }
    
    func createWatchlist(_ watchlist: Watchlist) async throws -> Watchlist {
        try await Task.sleep(nanoseconds: 500_000_000)
        return watchlist
    }
    
    func updateWatchlist(_ watchlist: Watchlist) async throws -> Watchlist {
        try await Task.sleep(nanoseconds: 400_000_000)
        return watchlist
    }
    
    func deleteWatchlist(_ id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}

class SymbolSearchService: SymbolSearchService {
    func searchSymbols(query: String, limit: Int) async throws -> [SymbolSearchResult] {
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Sample search results
        let sampleResults = [
            SymbolSearchResult(
                symbol: "AAPL",
                name: "Apple Inc.",
                exchange: "NASDAQ",
                price: 175.50,
                changePercent: 0.012,
                volume: 45_000_000,
                marketCap: 2_800_000_000_000,
                sector: "Technology"
            ),
            SymbolSearchResult(
                symbol: "TSLA",
                name: "Tesla, Inc.",
                exchange: "NASDAQ",
                price: 248.75,
                changePercent: -0.023,
                volume: 32_000_000,
                marketCap: 800_000_000_000,
                sector: "Consumer Cyclical"
            ),
            SymbolSearchResult(
                symbol: "NVDA",
                name: "NVIDIA Corporation",
                exchange: "NASDAQ",
                price: 485.20,
                changePercent: 0.045,
                volume: 28_000_000,
                marketCap: 1_200_000_000_000,
                sector: "Technology"
            )
        ]
        
        return sampleResults.filter { 
            $0.symbol.lowercased().contains(query.lowercased()) || 
            $0.name.lowercased().contains(query.lowercased()) 
        }
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}