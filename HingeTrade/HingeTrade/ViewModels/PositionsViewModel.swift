//
//  PositionsViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class PositionsViewModel: ObservableObject {
    @Published var positions: [Position] = []
    @Published var filteredPositions: [Position] = []
    @Published var isLoading: Bool = false
    @Published var error: PositionsError?
    @Published var showingError: Bool = false
    @Published var lastUpdated: Date = Date()
    
    // Sorting and filtering
    @Published var sortOption: PositionsListView.SortOption = .symbol
    @Published var filterOption: PositionsListView.FilterOption = .all
    
    // Summary calculations
    @Published var totalMarketValue: Decimal = 0.0
    @Published var totalUnrealizedPL: Decimal = 0.0
    @Published var totalUnrealizedPLPercent: Double = 0.0
    @Published var profitablePositionsCount: Int = 0
    @Published var losingPositionsCount: Int = 0
    
    private let tradingService: TradingService
    private let webSocketService: WebSocketService
    private let marketDataService: MarketDataService
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    init(
        tradingService: TradingService = TradingService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager())),
        webSocketService: WebSocketService = WebSocketService(url: URL(string: "wss://api.alpaca.markets/stream")!),
        marketDataService: MarketDataService = MarketDataService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager()))
    ) {
        self.tradingService = tradingService
        self.webSocketService = webSocketService
        self.marketDataService = marketDataService
        setupRealTimeUpdates()
        setupErrorHandling()
    }
    
    // MARK: - Data Loading
    
    func loadPositions() async {
        isLoading = true
        error = nil
        
        do {
            let loadedPositions = try await withCheckedThrowingContinuation { continuation in
                tradingService.getPositions()
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { positions in
                            continuation.resume(returning: positions)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            // Filter out zero positions using correct property name
            self.positions = loadedPositions.filter { (Double($0.qty) ?? 0.0) != 0 }
            
            // Apply current filters and sorting
            applyFiltersAndSorting()
            calculateSummaries()
            
            lastUpdated = Date()
        } catch {
            self.error = PositionsError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    func refreshPositions() async {
        await loadPositions()
    }
    
    func refreshPosition(_ symbol: String) async {
        do {
            let updatedPosition = try await withCheckedThrowingContinuation { continuation in
                tradingService.getPosition(symbol: symbol)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { position in
                            continuation.resume(returning: position)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            if let index = positions.firstIndex(where: { $0.symbol == symbol }) {
                if let position = updatedPosition {
                    positions[index] = position
                }
                applyFiltersAndSorting()
                calculateSummaries()
            }
        } catch {
            print("Failed to refresh position \(symbol): \(error)")
        }
    }
    
    // MARK: - Filtering and Sorting
    
    func setSortOption(_ option: PositionsListView.SortOption) {
        sortOption = option
        applyFiltersAndSorting()
    }
    
    func setFilterOption(_ option: PositionsListView.FilterOption) {
        filterOption = option
        applyFiltersAndSorting()
    }
    
    private func applyFiltersAndSorting() {
        // Apply filters
        var filtered = positions
        
        switch filterOption {
        case .all:
            break // No filtering
        case .profitable:
            filtered = filtered.filter { Double($0.unrealizedPl ?? "0") ?? 0 > 0 }
        case .losing:
            filtered = filtered.filter { Double($0.unrealizedPl ?? "0") ?? 0 < 0 }
        case .longPositions:
            filtered = filtered.filter { $0.side == .long }
        case .shortPositions:
            filtered = filtered.filter { $0.side == .short }
        }
        
        // Apply sorting
        switch sortOption {
        case .symbol:
            filtered.sort { $0.symbol < $1.symbol }
        case .unrealizedPL:
            filtered.sort { (Double($0.unrealizedPl ?? "0") ?? 0) > (Double($1.unrealizedPl ?? "0") ?? 0) }
        case .marketValue:
            filtered.sort { (Double($0.marketValue) ?? 0) > (Double($1.marketValue) ?? 0) }
        case .quantity:
            filtered.sort { abs(Double($0.qty) ?? 0) > abs(Double($1.qty) ?? 0) }
        }
        
        filteredPositions = filtered
    }
    
    // MARK: - Summary Calculations
    
    private func calculateSummaries() {
        totalMarketValue = positions.reduce(Decimal(0)) { result, position in
            result + currentMarketValue(for: position)
        }
        
        totalUnrealizedPL = positions.reduce(Decimal(0)) { result, position in
            result + currentUnrealizedPL(for: position)
        }
        
        let totalCostBasis = positions.reduce(Decimal(0)) { result, position in
            let avgPrice = Decimal(string: position.avgEntryPrice) ?? 0
            let qty = Decimal(string: position.qty) ?? 0
            return result + (avgPrice * abs(qty))
        }
        
        totalUnrealizedPLPercent = totalCostBasis > 0 ? Double(truncating: (totalUnrealizedPL / totalCostBasis) as NSDecimalNumber) : 0.0
        
        profitablePositionsCount = positions.filter { 
            currentUnrealizedPL(for: $0) > 0 
        }.count
        
        losingPositionsCount = positions.filter { 
            currentUnrealizedPL(for: $0) < 0 
        }.count
    }
    
    // MARK: - Real-Time Updates
    
    private func setupRealTimeUpdates() {
        // Subscribe to position updates via WebSocket
        webSocketService.messagePublisher
            .filter { $0.type == .positionUpdate }
            .compactMap { message -> Position? in
                guard let data = message.data else { return nil }
                return try? JSONDecoder().decode(Position.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] positionUpdate in
                self?.handlePositionUpdate(positionUpdate)
            }
            .store(in: &cancellables)
        
        // Subscribe to quote updates for position symbols
        webSocketService.messagePublisher
            .filter { $0.type == .quote }
            .compactMap { message -> Quote? in
                guard let data = message.data else { return nil }
                return try? JSONDecoder().decode(Quote.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quote in
                self?.handleQuoteUpdate(quote)
            }
            .store(in: &cancellables)
        
        // Set up periodic refresh timer (every 60 seconds)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshPositions()
            }
        }
    }
    
    private func handlePositionUpdate(_ update: Position) {
        if let index = positions.firstIndex(where: { $0.symbol == update.symbol }) {
            positions[index] = update
            applyFiltersAndSorting()
            calculateSummaries()
            lastUpdated = Date()
        }
    }
    
    // Store current prices separately since Position properties are read-only
    @Published private var currentPrices: [String: Decimal] = [:]
    
    private func handleQuoteUpdate(_ quote: Quote) {
        // Store current price for this symbol
        currentPrices[quote.symbol] = Decimal(quote.bidPrice)
        
        // Recalculate summaries with updated prices
        calculateSummaries()
        lastUpdated = Date()
    }
    
    // MARK: - Helper Methods for Calculated Values
    
    func currentMarketValue(for position: Position) -> Decimal {
        let currentPrice = currentPrices[position.symbol] ?? (Decimal(string: position.currentPrice ?? "0") ?? 0)
        let qty = Decimal(string: position.qty) ?? 0
        return currentPrice * abs(qty)
    }
    
    func currentUnrealizedPL(for position: Position) -> Decimal {
        let currentPrice = currentPrices[position.symbol] ?? (Decimal(string: position.currentPrice ?? "0") ?? 0)
        let avgEntryPrice = Decimal(string: position.avgEntryPrice) ?? 0
        let qty = Decimal(string: position.qty) ?? 0
        
        if position.side == .long {
            return (currentPrice - avgEntryPrice) * qty
        } else {
            return (avgEntryPrice - currentPrice) * abs(qty)
        }
    }
    
    func currentUnrealizedPLPercent(for position: Position) -> Double {
        let avgEntryPrice = Decimal(string: position.avgEntryPrice) ?? 0
        let qty = Decimal(string: position.qty) ?? 0
        let unrealizedPL = currentUnrealizedPL(for: position)
        
        guard avgEntryPrice > 0 && qty != 0 else { return 0.0 }
        let costBasis = avgEntryPrice * abs(qty)
        return Double(truncating: (unrealizedPL / costBasis) as NSDecimalNumber)
    }
    
    // MARK: - Position Actions
    
    func closePosition(_ position: Position) async {
        do {
            let orderSide: OrderSide = position.side == .long ? .sell : .buy
            let quantity = abs(Decimal(string: position.qty) ?? 0)
            
            let orderRequest = PlaceOrderRequest(
                symbol: position.symbol,
                side: orderSide,
                type: .market,
                timeInForce: .day,
                qty: String(describing: quantity),
                notional: nil,
                limitPrice: nil,
                stopPrice: nil,
                extendedHours: false,
                clientOrderId: nil
            )
            
            _ = try await withCheckedThrowingContinuation { continuation in
                tradingService.placeOrder(orderRequest)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { order in
                            continuation.resume(returning: order)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            // Refresh positions after order submission
            await refreshPosition(position.symbol)
            
        } catch {
            self.error = PositionsError.actionFailed("Failed to close position: \(error.localizedDescription)")
            self.showingError = true
        }
    }
    
    func adjustPosition(_ position: Position, newQuantity: Decimal) async {
        let currentQuantity = Decimal(string: position.qty) ?? 0
        let difference = newQuantity - currentQuantity
        
        guard difference != 0 else { return }
        
        do {
            let orderSide: OrderSide = difference > 0 ? 
                (position.side == .long ? .buy : .sell) : 
                (position.side == .long ? .sell : .buy)
            
            let orderQuantity = abs(difference)
            
            let orderRequest = PlaceOrderRequest(
                symbol: position.symbol,
                side: orderSide,
                type: .market,
                timeInForce: .day,
                qty: String(describing: orderQuantity),
                notional: nil,
                limitPrice: nil,
                stopPrice: nil,
                extendedHours: false,
                clientOrderId: nil
            )
            
            _ = try await withCheckedThrowingContinuation { continuation in
                tradingService.placeOrder(orderRequest)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { order in
                            continuation.resume(returning: order)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            // Refresh positions after order submission
            await refreshPosition(position.symbol)
            
        } catch {
            self.error = PositionsError.actionFailed("Failed to adjust position: \(error.localizedDescription)")
            self.showingError = true
        }
    }
    
    // MARK: - Computed Properties
    
    var biggestWinner: Position? {
        positions.filter { currentUnrealizedPL(for: $0) > 0 }
                .max(by: { currentUnrealizedPL(for: $0) < currentUnrealizedPL(for: $1) })
    }
    
    var biggestLoser: Position? {
        positions.filter { currentUnrealizedPL(for: $0) < 0 }
                .min(by: { currentUnrealizedPL(for: $0) < currentUnrealizedPL(for: $1) })
    }
    
    var portfolioDiversification: [String: Decimal] {
        let totalValue = totalMarketValue
        guard totalValue > 0 else { return [:] }
        
        var weights: [String: Decimal] = [:]
        for position in positions {
            let weight = currentMarketValue(for: position) / totalValue
            weights[position.symbol] = weight
        }
        
        return weights
    }
    
    // MARK: - Error Handling
    
    private func setupErrorHandling() {
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
    
    // MARK: - Cleanup
    
    deinit {
        refreshTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - PositionsError

enum PositionsError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case actionFailed(String)
    case networkError(String)
    case noPositions
    case unauthorized
    case unknown(String)
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .actionFailed(let message),
             .networkError(let message),
             .unknown(let message):
            return message
        case .noPositions:
            return "no_positions"
        case .unauthorized:
            return "unauthorized"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load positions: \(message)"
        case .actionFailed(let message):
            return "Position action failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .noPositions:
            return "No positions found"
        case .unauthorized:
            return "Unauthorized to access positions"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadingFailed, .actionFailed:
            return "Please try again in a moment."
        case .networkError:
            return "Please check your internet connection and try again."
        case .noPositions:
            return "Start trading to see positions here."
        case .unauthorized:
            return "Please sign in again or contact support."
        case .unknown:
            return "Please contact support if this issue persists."
        }
    }
}