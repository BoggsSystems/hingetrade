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
        tradingService: TradingService = TradingService(),
        marketDataService: MarketDataService = MarketDataService(),
        webSocketService: WebSocketService = WebSocketService()
    ) {
        self.position = position
        self.tradingService = tradingService
        self.marketDataService = marketDataService
        self.webSocketService = webSocketService
        self.currentPrice = position.avgEntryPrice // Initialize with entry price
        setupRealTimeUpdates()
    }
    
    // MARK: - Data Loading
    
    func loadDetailedData() async {
        isLoading = true
        
        async let assetInfo = loadAssetInformation()
        async let orderHistory = loadOrderHistory()
        async let currentQuote = loadCurrentQuote()
        
        await assetInfo
        await orderHistory
        await currentQuote
        
        isLoading = false
    }
    
    private func loadAssetInformation() async {
        do {
            let asset = try await tradingService.getAsset(symbol: position.symbol)
            self.assetName = asset.name
            // Sector would come from asset data if available
            self.sector = "Technology" // Placeholder
            self.description = asset.description
        } catch {
            print("Failed to load asset information: \(error)")
        }
    }
    
    private func loadOrderHistory() async {
        do {
            let orders = try await tradingService.getOrders(symbol: position.symbol, limit: 10)
            self.recentOrders = orders.filter { $0.status == .filled }
                .sorted { $0.executedAt ?? Date.distantPast > $1.executedAt ?? Date.distantPast }
        } catch {
            print("Failed to load order history: \(error)")
        }
    }
    
    private func loadCurrentQuote() async {
        do {
            let quote = try await marketDataService.getQuote(symbol: position.symbol)
            await updateWithQuote(quote)
        } catch {
            print("Failed to load current quote: \(error)")
        }
    }
    
    @MainActor
    private func updateWithQuote(_ quote: Quote) {
        let previousPrice = currentPrice
        currentPrice = quote.bidPrice
        
        if previousPrice > 0 {
            priceChange = currentPrice - previousPrice
            priceChangePercent = Double(priceChange / previousPrice)
        }
        
        // Recalculate position values
        let quantity = position.quantity
        let avgEntryPrice = position.avgEntryPrice
        
        position.marketValue = currentPrice * abs(quantity)
        
        if position.side == .long {
            position.unrealizedPL = (currentPrice - avgEntryPrice) * quantity
        } else {
            position.unrealizedPL = (avgEntryPrice - currentPrice) * abs(quantity)
        }
        
        position.unrealizedPLPercent = avgEntryPrice > 0 ? 
            Double(position.unrealizedPL / (avgEntryPrice * abs(quantity))) : 0.0
        
        // Calculate today's P&L (simplified - would need previous close price)
        todaysPL = position.unrealizedPL * 0.1 // Placeholder calculation
    }
    
    // MARK: - Real-Time Updates
    
    private func setupRealTimeUpdates() {
        // Subscribe to quote updates for this specific symbol
        webSocketService.quoteUpdates
            .filter { $0.symbol == self.position.symbol }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quote in
                Task { @MainActor in
                    await self?.updateWithQuote(quote)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to position updates
        webSocketService.positionUpdates
            .filter { $0.symbol == self.position.symbol }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] positionUpdate in
                self?.position = positionUpdate
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var costBasis: Decimal {
        return position.avgEntryPrice * abs(position.quantity)
    }
    
    var breakEvenPrice: Decimal {
        // Simple break-even calculation (excluding fees)
        return position.avgEntryPrice
    }
    
    var portfolioWeight: Double {
        // Would need total portfolio value from parent view model
        return 0.0 // Placeholder
    }
    
    // MARK: - Position Actions
    
    func increasePosition() async {
        // Calculate a reasonable increase amount (10% of current position)
        let increaseAmount = abs(position.quantity) * 0.1
        let roundedAmount = (increaseAmount * 100).rounded() / 100 // Round to 2 decimal places
        
        await adjustPosition(by: roundedAmount)
    }
    
    func decreasePosition() async {
        // Calculate a reasonable decrease amount (25% of current position)
        let decreaseAmount = abs(position.quantity) * -0.25
        let roundedAmount = (decreaseAmount * 100).rounded() / 100 // Round to 2 decimal places
        
        await adjustPosition(by: roundedAmount)
    }
    
    func closePosition() async {
        let orderSide: Order.Side = position.side == .long ? .sell : .buy
        let quantity = abs(position.quantity)
        
        do {
            let order = Order(
                symbol: position.symbol,
                quantity: quantity,
                side: orderSide,
                type: .market,
                timeInForce: .day
            )
            
            _ = try await tradingService.submitOrder(order)
            
            // The position will be updated via WebSocket
            
        } catch {
            print("Failed to close position: \(error)")
        }
    }
    
    private func adjustPosition(by amount: Decimal) async {
        guard amount != 0 else { return }
        
        do {
            let orderSide: Order.Side = amount > 0 ?
                (position.side == .long ? .buy : .sell) :
                (position.side == .long ? .sell : .buy)
            
            let orderQuantity = abs(amount)
            
            let order = Order(
                symbol: position.symbol,
                quantity: orderQuantity,
                side: orderSide,
                type: .market,
                timeInForce: .day
            )
            
            _ = try await tradingService.submitOrder(order)
            
            // The position will be updated via WebSocket
            
        } catch {
            print("Failed to adjust position: \(error)")
        }
    }
    
    func setStopLoss(at price: Decimal) async {
        let orderSide: Order.Side = position.side == .long ? .sell : .buy
        let quantity = abs(position.quantity)
        
        do {
            let order = Order(
                symbol: position.symbol,
                quantity: quantity,
                side: orderSide,
                type: .stop,
                timeInForce: .gtc,
                stopPrice: price
            )
            
            _ = try await tradingService.submitOrder(order)
            
        } catch {
            print("Failed to set stop loss: \(error)")
        }
    }
    
    func setTakeProfit(at price: Decimal) async {
        let orderSide: Order.Side = position.side == .long ? .sell : .buy
        let quantity = abs(position.quantity)
        
        do {
            let order = Order(
                symbol: position.symbol,
                quantity: quantity,
                side: orderSide,
                type: .limit,
                timeInForce: .gtc,
                limitPrice: price
            )
            
            _ = try await tradingService.submitOrder(order)
            
        } catch {
            print("Failed to set take profit: \(error)")
        }
    }
    
    // MARK: - Analytics
    
    func getPositionAnalytics() -> PositionAnalytics {
        let holdingPeriod = position.openedAt?.timeIntervalSinceNow ?? 0
        let annualizedReturn = holdingPeriod > 0 ? 
            Double(position.unrealizedPLPercent) * (365.25 * 24 * 3600 / abs(holdingPeriod)) : 0.0
        
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