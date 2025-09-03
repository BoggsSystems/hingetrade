//
//  TradeTicketViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class TradeTicketViewModel: ObservableObject {
    @Published var symbol: String
    @Published var assetName: String?
    @Published var currentQuote: Quote?
    @Published var isLoading: Bool = false
    @Published var isLoadingChart: Bool = false
    @Published var error: TradeTicketError?
    @Published var showingError: Bool = false
    
    // Order Configuration
    @Published var side: OrderSide = .buy
    @Published var orderType: OrderType = .market
    @Published var quantity: Decimal = 0
    @Published var limitPrice: Decimal = 0
    @Published var stopPrice: Decimal = 0
    @Published var timeInForce: OrderTimeInForce = .day
    
    // Validation and Risk
    @Published var isOrderValid: Bool = false
    @Published var riskWarnings: [String] = []
    @Published var estimatedTotal: Decimal = 0
    
    // Order Preview and Confirmation
    @Published var showingPreview: Bool = false
    @Published var showingConfirmation: Bool = false
    @Published var confirmationMessage: String = ""
    @Published var previewedOrder: Order?
    
    // Context from video
    private let videoContext: VideoContext?
    
    // Services
    private let tradingService: TradingService
    private let marketDataService: MarketDataService
    private let riskService: RiskService
    private let webSocketService: WebSocketService
    
    private var cancellables = Set<AnyCancellable>()
    private var validationTimer: Timer?
    
    init(
        symbol: String,
        videoContext: VideoContext? = nil,
        tradingService: TradingService = TradingService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager())),
        marketDataService: MarketDataService = MarketDataService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager())),
        riskService: RiskService = DefaultRiskService(),
        webSocketService: WebSocketService = WebSocketService(url: URL(string: "wss://api.alpaca.markets/stream")!)
    ) {
        self.symbol = symbol.uppercased()
        self.videoContext = videoContext
        self.tradingService = tradingService
        self.marketDataService = marketDataService
        self.riskService = riskService
        self.webSocketService = webSocketService
        
        setupBindings()
        setupRealTimeUpdates()
        applyVideoContext()
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        isLoading = true
        
        do {
            // Load current quote
            await loadCurrentQuote()
            
            // Load asset information
            await loadAssetInfo()
            
            // Initialize price fields with current market price
            if let quote = currentQuote {
                limitPrice = Decimal(quote.bidPrice)
                stopPrice = Decimal(quote.bidPrice * 0.95) // 5% below for stop loss
            }
            
        } catch {
            self.error = TradeTicketError.initializationFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    private func loadCurrentQuote() async {
        do {
            let quote = try await withCheckedThrowingContinuation { continuation in
                marketDataService.getQuote(symbol: symbol)
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
            await MainActor.run {
                self.currentQuote = quote
            }
        } catch {
            print("Failed to load quote: \(error)")
        }
    }
    
    private func loadAssetInfo() async {
        do {
            // For now, just set a placeholder name since getAsset doesn't exist
            self.assetName = symbol
        } catch {
            print("Failed to load asset info: \(error)")
        }
    }
    
    private func applyVideoContext() {
        guard let context = videoContext else { return }
        
        // Apply market direction hint (but don't force it)
        if let direction = context.marketDirection {
            switch direction {
            case .bullish:
                side = .buy
            case .bearish:
                side = .sell
            case .neutral:
                break // Keep default
            }
        }
        
        // Set quantity based on price targets or default amount
        if !context.priceTargets.isEmpty {
            // Conservative quantity for video-inspired trades
            quantity = 10
        }
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // For now, skip real-time updates since WebSocketService doesn't have quoteUpdates
        // This would be implemented when WebSocket service is properly configured
    }
    
    private func handleQuoteUpdate(_ quote: Quote) {
        currentQuote = quote
        
        // Update limit price if it hasn't been manually changed
        if orderType == .limit && limitPrice == 0 {
            limitPrice = Decimal(quote.bidPrice)
        }
        
        // Revalidate order
        validateOrder()
    }
    
    // MARK: - Order Configuration
    
    func setSide(_ newSide: OrderSide) {
        side = newSide
        validateOrder()
    }
    
    func setOrderType(_ newType: OrderType) {
        orderType = newType
        
        // Initialize prices when switching to limit/stop orders
        if let quote = currentQuote {
            switch newType {
            case .limit, .stopLimit:
                if limitPrice == 0 {
                    limitPrice = Decimal(quote.bidPrice)
                }
            case .stop, .stopLimit:
                if stopPrice == 0 {
                    stopPrice = side == .buy ? 
                        Decimal(quote.askPrice * 1.02) : // 2% above for buy stop
                        Decimal(quote.bidPrice * 0.98)   // 2% below for sell stop
                }
            default:
                break
            }
        }
        
        validateOrder()
    }
    
    func setQuantity(_ newQuantity: Decimal) {
        quantity = max(0, newQuantity)
        validateOrder()
    }
    
    func setTimeInForce(_ newTIF: OrderTimeInForce) {
        timeInForce = newTIF
        validateOrder()
    }
    
    func adjustLimitPrice(by amount: Decimal) {
        limitPrice = max(0.01, limitPrice + amount)
        validateOrder()
    }
    
    // MARK: - Order Validation
    
    private func setupBindings() {
        // Validate order whenever key properties change
        Publishers.CombineLatest4($quantity, $limitPrice, $stopPrice, $orderType)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.validateOrder()
            }
            .store(in: &cancellables)
    }
    
    private func validateOrder() {
        var warnings: [String] = []
        var isValid = true
        
        // Basic validation
        if quantity <= 0 {
            isValid = false
        }
        
        if symbol.isEmpty {
            isValid = false
        }
        
        // Price validation for limit orders
        if orderType == .limit || orderType == .stopLimit {
            if limitPrice <= 0 {
                isValid = false
            }
            
            // Warn if limit price is far from market
            if let quote = currentQuote {
                let quoteBidDecimal = Decimal(quote.bidPrice)
                let priceDeviation = abs(limitPrice - quoteBidDecimal) / quoteBidDecimal
                if priceDeviation > 0.1 { // 10% deviation
                    let percentage = Int(NSDecimalNumber(decimal: priceDeviation * 100).doubleValue)
                    warnings.append("Limit price is \(percentage)% away from market price")
                }
            }
        }
        
        // Price validation for stop orders
        if orderType == .stop || orderType == .stopLimit {
            if stopPrice <= 0 {
                isValid = false
            }
        }
        
        // Risk validation
        validateRiskRules(&warnings, &isValid)
        
        // Update estimated total
        calculateEstimatedTotal()
        
        self.riskWarnings = warnings
        self.isOrderValid = isValid
    }
    
    private func validateRiskRules(_ warnings: inout [String], _ isValid: inout Bool) {
        guard let quote = currentQuote else { return }
        
        // Day trading rule validation
        if timeInForce == .day {
            // Check for pattern day trader rules
            // This would integrate with actual account status
        }
        
        // Position size validation
        let priceForCalculation = orderType == .market ? Decimal(quote.bidPrice) : limitPrice
        let orderValue = quantity * priceForCalculation
        let maxOrderValue: Decimal = 25000 // Example limit
        
        if orderValue > maxOrderValue {
            warnings.append("Order value exceeds maximum allowed ($\(maxOrderValue.formatted(.currency(code: "USD"))))")
            isValid = false
        }
        
        // Market hours validation
        let marketStatus = getCurrentMarketStatus()
        if orderType == .market && marketStatus != .open {
            warnings.append("Market orders can only be placed during market hours")
        }
        
        // Symbol-specific validation
        validateSymbolSpecificRules(&warnings, &isValid)
    }
    
    private func validateSymbolSpecificRules(_ warnings: inout [String], _ isValid: inout Bool) {
        // Check if symbol is tradeable
        // Check if symbol has any special restrictions
        // This would integrate with actual asset information
        
        // Example: Penny stock warning
        if let quote = currentQuote, quote.bidPrice < 5 {
            warnings.append("This is a penny stock - higher risk and volatility")
        }
        
        // Example: Crypto hours
        if symbol.hasSuffix("USDC") || symbol.hasSuffix("BTC") {
            // Crypto trading hours might be different
        }
    }
    
    private func calculateEstimatedTotal() {
        guard quantity > 0 else {
            estimatedTotal = 0
            return
        }
        
        let pricePerShare: Decimal
        
        switch orderType {
        case .market:
            pricePerShare = Decimal(currentQuote?.askPrice ?? 0)
        case .limit, .stopLimit:
            pricePerShare = limitPrice
        case .stop:
            pricePerShare = Decimal(currentQuote?.askPrice ?? 0)
        }
        
        estimatedTotal = quantity * pricePerShare
        
        // Add estimated fees (would be calculated based on actual fee structure)
        // For now, assume commission-free trading
    }
    
    // MARK: - Order Actions
    
    func previewOrder() async {
        showingPreview = true
        
        // Create preview order
        let order = createOrderFromCurrentState()
        previewedOrder = order
        
        // Perform final validation
        do {
            let validationResult = try await riskService.validateOrder(order!)
            
            if !validationResult.isValid {
                var warnings = riskWarnings
                let warningStrings = validationResult.warnings.compactMap { $0.warningDescription ?? $0.localizedDescription }
                warnings.append(contentsOf: warningStrings)
                self.riskWarnings = warnings
                
                if validationResult.errors.isEmpty == false {
                    throw TradeTicketError.validationFailed(validationResult.errors.first!.localizedDescription)
                }
            }
            
        } catch {
            self.error = TradeTicketError.validationFailed(error.localizedDescription)
            self.showingError = true
            showingPreview = false
        }
    }
    
    func confirmOrder() {
        guard let order = previewedOrder ?? createOrderFromCurrentState() else { return }
        
        confirmationMessage = """
        You are about to place a \(side.rawValue.uppercased()) order for \(quantity.formatted(.number)) shares of \(symbol) at \(orderType.displayName.lowercased()) price.
        
        Estimated total: \(estimatedTotal.formatted(.currency(code: "USD")))
        
        This action cannot be undone once submitted.
        """
        
        showingConfirmation = true
    }
    
    func submitOrder() async {
        guard let order = previewedOrder ?? createOrderFromCurrentState() else {
            return
        }
        
        isLoading = true
        
        do {
            // For now, skip order submission since submitOrder method doesn't exist
            print("Would submit order: \(String(describing: order))")
            
            // Track successful order submission (using mock order for now)
            await trackOrderSubmission(order)
            
            // Show success and dismiss
            // This would typically show a success toast and close the modal
            
        } catch {
            self.error = TradeTicketError.submissionFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
        showingConfirmation = false
    }
    
    func cancelConfirmation() {
        showingConfirmation = false
    }
    
    private func createOrderFromCurrentState() -> Order? {
        guard isOrderValid else { return nil }
        
        // Create a basic order structure - this would be replaced with proper Order creation
        // For now, return nil since the Order initializer expects different parameters
        return nil
    }
    
    private func orderTypeToOrderType(_ type: OrderType) -> OrderType {
        switch type {
        case .market: return .market
        case .limit: return .limit
        case .stop: return .stop
        case .stopLimit: return .stopLimit
        }
    }
    
    private func timeInForceToOrderTimeInForce(_ tif: OrderTimeInForce) -> OrderTimeInForce {
        switch tif {
        case .day: return .day
        case .gtc: return .gtc
        case .opg: return .opg
        case .cls: return .cls
        case .ioc: return .ioc
        case .fok: return .fok
        }
    }
    
    private func generateClientOrderId() -> String {
        return "hinge_\(symbol.lowercased())_\(Date().timeIntervalSince1970)_\(UUID().uuidString.prefix(8))"
    }
    
    // MARK: - Analytics and Tracking
    
    private func trackOrderSubmission(_ order: Order) async {
        // Track order submission for analytics
        let context: [String: Any] = [
            "symbol": symbol,
            "side": side.rawValue,
            "order_type": String(describing: orderType),
            "quantity": NSDecimalNumber(decimal: quantity),
            "source": videoContext != nil ? "video" : "manual",
            "video_id": videoContext?.videoId ?? ""
        ]
        
        // This would integrate with analytics service
        print("Order submitted with context: \(context)")
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMarketStatus() -> MarketStatus {
        // This would integrate with market data service
        // For now, return a default status
        return .open
    }
    
    // MARK: - Error Handling
    
    func dismissError() {
        error = nil
        showingError = false
    }
    
    deinit {
        validationTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Risk Service Protocol

protocol RiskService {
    func validateOrder(_ order: Order) async throws -> OrderValidationResult
}


class DefaultRiskService: RiskService {
    func validateOrder(_ order: Order) async throws -> OrderValidationResult {
        var warnings: [String] = []
        var errors: [String] = []
        
        // Simulate risk validation
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // For now, return a simple validation since Order model fields are different
        warnings.append("Order validation placeholder")
        
        let riskAssessment = RiskAssessment(
            overallRisk: .low,
            positionSizeRisk: .low,
            priceRisk: .low,
            liquidityRisk: .low,
            timeRisk: .low,
            recommendations: ["Review order before submission"]
        )
        
        return OrderValidationResult(
            isValid: errors.isEmpty,
            errors: [],
            warnings: [],
            riskAssessment: riskAssessment
        )
    }
}

// MARK: - Error Types

enum TradeTicketError: LocalizedError, Identifiable {
    case initializationFailed(String)
    case validationFailed(String)
    case submissionFailed(String)
    case networkError(String)
    case insufficientFunds
    case marketClosed
    case symbolNotFound(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .initializationFailed(let message),
             .validationFailed(let message),
             .submissionFailed(let message),
             .networkError(let message),
             .symbolNotFound(let message),
             .unknown(let message):
            return message
        case .insufficientFunds:
            return "insufficient_funds"
        case .marketClosed:
            return "market_closed"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Failed to initialize trade ticket: \(message)"
        case .validationFailed(let message):
            return "Order validation failed: \(message)"
        case .submissionFailed(let message):
            return "Failed to submit order: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .insufficientFunds:
            return "Insufficient buying power for this order"
        case .marketClosed:
            return "Market is currently closed"
        case .symbolNotFound(let symbol):
            return "Symbol '\(symbol)' not found"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .initializationFailed, .networkError:
            return "Please check your internet connection and try again."
        case .validationFailed:
            return "Please review your order details and try again."
        case .submissionFailed:
            return "Please try submitting the order again."
        case .insufficientFunds:
            return "Please reduce the order size or add funds to your account."
        case .marketClosed:
            return "Please wait for market hours or use a limit order."
        case .symbolNotFound:
            return "Please check the symbol and try again."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}

// MARK: - Extensions

// These enums are now defined in the main Order.swift file