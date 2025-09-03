//
//  PositionDetailViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class PositionDetailViewModel: ObservableObject {
    @Published var position: Position
    @Published var currentPrice: Decimal = 0.0
    @Published var priceChange: Decimal = 0.0
    @Published var priceChangePercent: Double = 0.0
    @Published var todaysPL: Decimal = 0.0
    @Published var isLoading: Bool = false
    @Published var showAlertSetup: Bool = false
    
    // Asset information
    @Published var assetName: String?
    @Published var sector: String?
    @Published var description: String?
    
    // Order history
    @Published var recentOrders: [Order] = []
    
    private let tradingService: TradingService
    private let marketDataService: MarketDataService
    private let webSocketService: WebSocketService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        position: Position,
        tradingService: TradingService = TradingService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager())),
        marketDataService: MarketDataService = MarketDataService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager())),
        webSocketService: WebSocketService = WebSocketService(url: URL(string: "wss://api.alpaca.markets/stream")!)
    ) {
        self.position = position
        self.tradingService = tradingService
        self.marketDataService = marketDataService
        self.webSocketService = webSocketService
        self.currentPrice = Decimal(string: position.avgEntryPrice) ?? 0 // Initialize with entry price
        setupRealTimeUpdates()
    }
    
    // MARK: - Data Loading
    
    func loadDetailedData() async {
        isLoading = true
        
        await loadAssetInformation()
        await loadOrderHistory()
        await loadCurrentQuote()
        
        isLoading = false
    }
    
    private func loadAssetInformation() async {
        // TODO: Implement getAsset method in TradingService
        // For now, use symbol as name
        self.assetName = position.symbol
        self.sector = "Unknown"
        self.description = "Asset information not available"
    }
    
    private func loadOrderHistory() async {
        do {
            let orders = try await withCheckedThrowingContinuation { continuation in
                tradingService.getOrders(status: nil)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { orders in
                            continuation.resume(returning: orders)
                        }
                    )
                    .store(in: &cancellables)
            }
            // Filter for this symbol and filled orders
            self.recentOrders = orders.filter { $0.symbol == position.symbol && $0.status == .filled }
                .sorted { ($0.filledAt ?? Date.distantPast) > ($1.filledAt ?? Date.distantPast) }
        } catch {
            print("Failed to load order history: \(error)")
        }
    }
    
    private func loadCurrentQuote() async {
        do {
            let quote = try await withCheckedThrowingContinuation { continuation in
                marketDataService.getQuote(symbol: position.symbol)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { quote in
                            continuation.resume(returning: quote)
                        }
                    )
                    .store(in: &cancellables)
            }
            await updateWithQuote(quote)
        } catch {
            print("Failed to load current quote: \(error)")
        }
    }
    
    @MainActor
    private func updateWithQuote(_ quote: Quote) {
        let previousPrice = currentPrice
        currentPrice = Decimal(quote.bidPrice)
        
        if previousPrice > 0 {
            priceChange = currentPrice - previousPrice
            priceChangePercent = Double(truncating: (priceChange / previousPrice) as NSDecimalNumber)
        }
        
        // Recalculate position values
        let quantity = Decimal(string: position.qty) ?? 0
        let avgEntryPrice = Decimal(string: position.avgEntryPrice) ?? 0
        
        // Calculate new values but don't mutate position (it's immutable)
        let newMarketValue = currentPrice * abs(quantity)
        
        let newUnrealizedPL: Decimal
        if position.side == .long {
            newUnrealizedPL = (currentPrice - avgEntryPrice) * quantity
        } else {
            newUnrealizedPL = (avgEntryPrice - currentPrice) * abs(quantity)
        }
        
        // Calculate today's P&L (simplified - would need previous close price)
        todaysPL = newUnrealizedPL * Decimal(0.1) // Placeholder calculation
    }
    
    // MARK: - Real-Time Updates
    
    private func setupRealTimeUpdates() {
        // TODO: Subscribe to quote updates for this specific symbol when WebSocket service supports it
        // webSocketService.quoteUpdates
        //     .filter { $0.symbol == self.position.symbol }
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] quote in
        //         Task { @MainActor in
        //             await self?.updateWithQuote(quote)
        //         }
        //     }
        //     .store(in: &cancellables)
        
        // TODO: Subscribe to position updates when WebSocket service supports it  
        // webSocketService.positionUpdates
        //     .filter { $0.symbol == self.position.symbol }
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] positionUpdate in
        //         self?.position = positionUpdate
        //     }
        //     .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var costBasis: Decimal {
        let quantity = Decimal(string: position.qty) ?? 0
        let avgEntryPrice = Decimal(string: position.avgEntryPrice) ?? 0
        return avgEntryPrice * abs(quantity)
    }
    
    var breakEvenPrice: Decimal {
        // Simple break-even calculation (excluding fees)
        return Decimal(string: position.avgEntryPrice) ?? 0
    }
    
    var portfolioWeight: Double {
        // Would need total portfolio value from parent view model
        return 0.0 // Placeholder
    }
    
    // MARK: - Position Actions
    
    func increasePosition() async {
        // Calculate a reasonable increase amount (10% of current position)
        let quantity = Decimal(string: position.qty) ?? 0
        let increaseAmount = abs(quantity) * Decimal(0.1)
        let roundedAmount = increaseAmount // Decimal already handles precision well
        
        await adjustPosition(by: roundedAmount)
    }
    
    func decreasePosition() async {
        // Calculate a reasonable decrease amount (25% of current position)
        let quantity = Decimal(string: position.qty) ?? 0
        let decreaseAmount = abs(quantity) * Decimal(-0.25)
        let roundedAmount = decreaseAmount // Decimal already handles precision well
        
        await adjustPosition(by: roundedAmount)
    }
    
    func closePosition() async {
        let orderSide: OrderSide = position.side == .long ? .sell : .buy
        let quantity = abs(Decimal(string: position.qty) ?? 0)
        
        // TODO: Implement proper order submission when TradingService supports it
        print("Would close position of \(quantity) shares of \(position.symbol)")
    }
    
    private func adjustPosition(by amount: Decimal) async {
        guard amount != 0 else { return }
        
        // TODO: Implement proper order submission when TradingService supports it
        let action = amount > 0 ? "increase" : "decrease"
        print("Would \(action) position by \(abs(amount)) shares of \(position.symbol)")
    }
    
    func setStopLoss(at price: Decimal) async {
        let quantity = abs(Decimal(string: position.qty) ?? 0)
        
        // TODO: Implement proper stop loss order submission when TradingService supports it
        print("Would set stop loss at \(price) for \(quantity) shares of \(position.symbol)")
    }
    
    func setTakeProfit(at price: Decimal) async {
        let quantity = abs(Decimal(string: position.qty) ?? 0)
        
        // TODO: Implement proper take profit order submission when TradingService supports it
        print("Would set take profit at \(price) for \(quantity) shares of \(position.symbol)")
    }
    
    // MARK: - Analytics
    
    func getPositionAnalytics() -> PositionAnalytics {
        // For now, use a default holding period since Position model doesn't have openedAt
        let holdingPeriod: TimeInterval = 30 * 24 * 3600 // Default to 30 days
        let unrealizedPercent = Double(position.unrealizedPlpc ?? "0") ?? 0.0
        let annualizedReturn = holdingPeriod > 0 ? 
            unrealizedPercent * (365.25 * 24 * 3600 / abs(holdingPeriod)) : 0.0
        
        return PositionAnalytics(
            holdingPeriodDays: Int(abs(holdingPeriod) / (24 * 3600)),
            annualizedReturn: annualizedReturn,
            maxDrawdown: 0.0, // Would need historical data
            sharpeRatio: 0.0, // Would need risk-free rate and volatility
            beta: 0.0 // Would need market correlation
        )
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - PositionAnalytics

struct PositionAnalytics {
    let holdingPeriodDays: Int
    let annualizedReturn: Double
    let maxDrawdown: Double
    let sharpeRatio: Double
    let beta: Double
}