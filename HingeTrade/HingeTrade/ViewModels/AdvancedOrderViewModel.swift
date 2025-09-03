//
//  AdvancedOrderViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class AdvancedOrderViewModel: ObservableObject {
    @Published var currentConfig: AdvancedOrderConfig?
    @Published var orderPreview: OrderPreview?
    @Published var riskAssessment: RiskAssessment?
    @Published var currentRiskLevel: RiskLevel?
    
    // Order parameters
    @Published var stopPrice = ""
    @Published var takeProfitPrice = ""
    @Published var stopLossPrice = ""
    @Published var limitPrice = ""
    @Published var trailAmount = ""
    @Published var trailPercent = ""
    
    // State
    @Published var isSubmitting = false
    @Published var hasError = false
    @Published var error: AdvancedOrderError?
    @Published var canSubmitOrder = false
    @Published var validationMessage = ""
    
    // Calculations
    @Published var estimatedPositionValue: Decimal?
    @Published var estimatedRiskAmount: Decimal?
    @Published var riskRewardRatio: Double?
    
    // Services and data
    private var symbol: String = ""
    private var currentPrice: Decimal = 0
    private var quantity: Int = 0
    private var side: OrderSide = .buy
    private var orderType: AdvancedOrderType = .stopLoss
    
    private let advancedOrderService: AdvancedOrderService
    private let riskManagementService: RiskManagementService
    private let positionSizingCalculator: PositionSizingCalculator
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        advancedOrderService: DefaultAdvancedOrderService = DefaultAdvancedOrderService(),
        riskManagementService: RiskManagementService = DefaultRiskManagementService()
    ) {
        self.advancedOrderService = advancedOrderService
        self.riskManagementService = riskManagementService
        
        // Initialize with default risk parameters
        self.positionSizingCalculator = PositionSizingCalculator(
            accountBalance: 100000, // $100k default
            riskParameters: .moderate
        )
        
        setupBindings()
    }
    
    // MARK: - Initialization
    
    func initialize(symbol: String, currentPrice: Decimal) {
        self.symbol = symbol
        self.currentPrice = currentPrice
        
        // Create initial config
        currentConfig = AdvancedOrderConfig(
            orderType: orderType,
            symbol: symbol,
            quantity: quantity,
            side: side
        )
        
        updateCalculations()
    }
    
    // MARK: - Order Configuration
    
    func setOrderType(_ type: AdvancedOrderType) {
        orderType = type
        updateCurrentConfig()
        updateCalculations()
    }
    
    func updateQuantity(_ newQuantity: Int) {
        quantity = newQuantity
        updateCurrentConfig()
        updateCalculations()
    }
    
    func updateSide(_ newSide: OrderSide) {
        side = newSide
        updateCurrentConfig()
        updateCalculations()
    }
    
    private func updateCurrentConfig() {
        var config = AdvancedOrderConfig(
            orderType: orderType,
            symbol: symbol,
            quantity: quantity,
            side: side
        )
        
        // Update specific parameters based on order type
        switch orderType {
        case .stopLoss, .takeProfit:
            config.stopPrice = Decimal(string: stopPrice)
            
        case .trailingStop:
            config.trailAmount = Decimal(string: trailAmount)
            config.trailPercent = Double(trailPercent)
            
        case .bracketOrder:
            config.takeProfitPrice = Decimal(string: takeProfitPrice)
            config.stopLossPrice = Decimal(string: stopLossPrice)
            
        case .stopLimit:
            config.stopPrice = Decimal(string: stopPrice)
            config.limitPrice = Decimal(string: limitPrice)
            
        default:
            break
        }
        
        currentConfig = config
    }
    
    // MARK: - Calculations
    
    private func updateCalculations() {
        guard quantity > 0 else {
            resetCalculations()
            return
        }
        
        // Calculate position value
        estimatedPositionValue = currentPrice * Decimal(quantity)
        
        // Calculate risk amount based on order type
        switch orderType {
        case .stopLoss:
            if let stopPriceDecimal = Decimal(string: stopPrice) {
                let priceDistance = abs(currentPrice - stopPriceDecimal)
                estimatedRiskAmount = priceDistance * Decimal(quantity)
            }
            
        case .bracketOrder:
            if let stopLossDecimal = Decimal(string: stopLossPrice),
               let takeProfitDecimal = Decimal(string: takeProfitPrice) {
                let riskDistance = abs(currentPrice - stopLossDecimal)
                let rewardDistance = abs(takeProfitDecimal - currentPrice)
                
                estimatedRiskAmount = riskDistance * Decimal(quantity)
                riskRewardRatio = Double(truncating: (rewardDistance / riskDistance) as NSDecimalNumber)
            }
            
        default:
            estimatedRiskAmount = nil
            riskRewardRatio = nil
        }
        
        updateRiskAssessment()
        updateOrderPreview()
        validateOrder()
    }
    
    private func resetCalculations() {
        estimatedPositionValue = nil
        estimatedRiskAmount = nil
        riskRewardRatio = nil
        riskAssessment = nil
        orderPreview = nil
        canSubmitOrder = false
    }
    
    private func updateRiskAssessment() {
        guard let config = currentConfig,
              let positionValue = estimatedPositionValue else {
            riskAssessment = nil
            currentRiskLevel = nil
            return
        }
        
        let assessment = riskManagementService.assessOrderRisk(
            config: config,
            currentPrice: currentPrice,
            positionValue: positionValue,
            accountBalance: positionSizingCalculator.accountBalance
        )
        
        riskAssessment = assessment
        currentRiskLevel = assessment.overallRisk
    }
    
    private func updateOrderPreview() {
        guard let config = currentConfig,
              let positionValue = estimatedPositionValue else {
            orderPreview = nil
            return
        }
        
        orderPreview = OrderPreview(
            orderType: config.orderType,
            symbol: config.symbol,
            quantity: config.quantity,
            side: config.side,
            estimatedValue: positionValue,
            stopPrice: config.stopPrice,
            limitPrice: config.limitPrice,
            takeProfitPrice: config.takeProfitPrice,
            stopLossPrice: config.stopLossPrice,
            trailAmount: config.trailAmount,
            trailPercent: config.trailPercent,
            estimatedFees: calculateEstimatedFees(positionValue: positionValue),
            riskAmount: estimatedRiskAmount,
            riskRewardRatio: riskRewardRatio
        )
    }
    
    private func calculateEstimatedFees(positionValue: Decimal) -> Decimal {
        // Simple fee calculation - would be more sophisticated in real implementation
        return positionValue * Decimal(0.005) // 0.5% estimated fees
    }
    
    private func validateOrder() {
        guard let config = currentConfig else {
            canSubmitOrder = false
            validationMessage = "Invalid order configuration"
            return
        }
        
        let validation = riskManagementService.validateOrder(
            config: config,
            currentPrice: currentPrice,
            accountBalance: positionSizingCalculator.accountBalance
        )
        
        canSubmitOrder = validation.isValid
        
        if !validation.isValid {
            validationMessage = validation.errors.first?.errorDescription ?? "Order validation failed"
        } else if !validation.warnings.isEmpty {
            validationMessage = validation.warnings.first?.warningDescription ?? ""
        } else {
            validationMessage = ""
        }
    }
    
    // MARK: - Order Submission
    
    func submitOrder() async {
        guard let config = currentConfig, canSubmitOrder else { return }
        
        isSubmitting = true
        hasError = false
        error = nil
        
        do {
            _ = try await advancedOrderService.submitAdvancedOrder(config)
            // Order submitted successfully
            
        } catch {
            hasError = true
            self.error = AdvancedOrderError.submissionFailed(error.localizedDescription)
        }
        
        isSubmitting = false
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // Update calculations when parameters change
        Publishers.CombineLatest4($stopPrice, $takeProfitPrice, $stopLossPrice, $limitPrice)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateCurrentConfig()
                self?.updateCalculations()
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest($trailAmount, $trailPercent)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateCurrentConfig()
                self?.updateCalculations()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Supporting Models

struct OrderPreview {
    let orderType: AdvancedOrderType
    let symbol: String
    let quantity: Int
    let side: OrderSide
    let estimatedValue: Decimal
    let stopPrice: Decimal?
    let limitPrice: Decimal?
    let takeProfitPrice: Decimal?
    let stopLossPrice: Decimal?
    let trailAmount: Decimal?
    let trailPercent: Double?
    let estimatedFees: Decimal
    let riskAmount: Decimal?
    let riskRewardRatio: Double?
    
    var formattedSummary: String {
        let action = side == .buy ? "BUY" : "SELL"
        return "\(action) \(quantity) shares of \(symbol) via \(orderType.displayName)"
    }
}

// MARK: - Services

protocol AdvancedOrderService {
    func submitAdvancedOrder(_ config: AdvancedOrderConfig) async throws -> String
    func getAdvancedOrders() async throws -> [AdvancedOrderConfig]
    func cancelAdvancedOrder(_ orderId: String) async throws
}

class DefaultAdvancedOrderService: AdvancedOrderService {
    func submitAdvancedOrder(_ config: AdvancedOrderConfig) async throws -> String {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Simulate potential failure
        if Bool.random() && Bool.random() { // 25% failure rate
            throw AdvancedOrderError.submissionFailed("Market conditions prevent order execution")
        }
        
        return UUID().uuidString
    }
    
    func getAdvancedOrders() async throws -> [AdvancedOrderConfig] {
        try await Task.sleep(nanoseconds: 800_000_000)
        return [] // Would return actual orders
    }
    
    func cancelAdvancedOrder(_ orderId: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}

protocol RiskManagementService {
    func assessOrderRisk(
        config: AdvancedOrderConfig,
        currentPrice: Decimal,
        positionValue: Decimal,
        accountBalance: Decimal
    ) -> RiskAssessment
    
    func validateOrder(
        config: AdvancedOrderConfig,
        currentPrice: Decimal,
        accountBalance: Decimal
    ) -> OrderValidationResult
}

class DefaultRiskManagementService: RiskManagementService {
    func assessOrderRisk(
        config: AdvancedOrderConfig,
        currentPrice: Decimal,
        positionValue: Decimal,
        accountBalance: Decimal
    ) -> RiskAssessment {
        
        let positionRiskPercent = Double(truncating: (positionValue / accountBalance) as NSDecimalNumber)
        
        // Assess different risk factors
        let positionSizeRisk: RiskLevel = {
            switch positionRiskPercent {
            case 0...0.05: return .low
            case 0.05...0.15: return .medium
            case 0.15...0.30: return .high
            default: return .extreme
            }
        }()
        
        let priceRisk: RiskLevel = {
            // Would analyze volatility, spreads, etc.
            return .medium
        }()
        
        let liquidityRisk: RiskLevel = {
            // Would analyze volume, market cap, etc.
            return .low
        }()
        
        let timeRisk: RiskLevel = {
            // Would analyze market hours, expiration, etc.
            return .low
        }()
        
        // Overall risk is the highest individual risk
        let overallRisk = [positionSizeRisk, priceRisk, liquidityRisk, timeRisk].max { a, b in
            a.rawValue < b.rawValue
        } ?? .low
        
        var recommendations: [String] = []
        
        if positionRiskPercent > 0.10 {
            recommendations.append("Consider reducing position size")
        }
        
        if config.orderType == .stopLoss || config.orderType == .bracketOrder {
            if config.stopPrice == nil && config.stopLossPrice == nil {
                recommendations.append("Add stop loss to limit downside risk")
            }
        }
        
        if recommendations.isEmpty {
            recommendations.append("Risk parameters within acceptable limits")
        }
        
        return RiskAssessment(
            overallRisk: overallRisk,
            positionSizeRisk: positionSizeRisk,
            priceRisk: priceRisk,
            liquidityRisk: liquidityRisk,
            timeRisk: timeRisk,
            recommendations: recommendations
        )
    }
    
    func validateOrder(
        config: AdvancedOrderConfig,
        currentPrice: Decimal,
        accountBalance: Decimal
    ) -> OrderValidationResult {
        
        var errors: [OrderValidationError] = []
        var warnings: [OrderValidationWarning] = []
        
        let positionValue = currentPrice * Decimal(config.quantity)
        
        // Check funds
        if positionValue > accountBalance {
            errors.append(.insufficientFunds(required: positionValue, available: accountBalance))
        }
        
        // Check position size limits
        let maxPosition = accountBalance * Decimal(0.25) // 25% max
        if positionValue > maxPosition {
            errors.append(.exceedsPositionLimit(requested: positionValue, limit: maxPosition))
        }
        
        // Check risk limits
        let riskPercent = Double(truncating: (positionValue / accountBalance) as NSDecimalNumber)
        if riskPercent > 0.20 {
            errors.append(.exceedsRiskLimit(riskPercent: riskPercent, limit: 0.20))
        } else if riskPercent > 0.10 {
            warnings.append(.highRisk(riskPercent: riskPercent))
        }
        
        // Order type specific validations
        switch config.orderType {
        case .stopLoss, .takeProfit:
            if config.stopPrice == nil {
                errors.append(.missingStopLoss)
            }
            
        case .bracketOrder:
            if config.stopLossPrice == nil || config.takeProfitPrice == nil {
                errors.append(.invalidOrderCombination)
            }
            
        case .stopLimit:
            if config.stopPrice == nil || config.limitPrice == nil {
                errors.append(.invalidOrderCombination)
            }
            
        default:
            break
        }
        
        let riskAssessment = assessOrderRisk(
            config: config,
            currentPrice: currentPrice,
            positionValue: positionValue,
            accountBalance: accountBalance
        )
        
        return OrderValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            riskAssessment: riskAssessment
        )
    }
}

// MARK: - Error Types

enum AdvancedOrderError: LocalizedError, Identifiable {
    case submissionFailed(String)
    case invalidConfiguration(String)
    case riskLimitExceeded(String)
    case marketClosed
    case insufficientFunds
    
    var id: String {
        switch self {
        case .submissionFailed(let message),
             .invalidConfiguration(let message),
             .riskLimitExceeded(let message):
            return message
        case .marketClosed:
            return "market_closed"
        case .insufficientFunds:
            return "insufficient_funds"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .submissionFailed(let message):
            return "Order submission failed: \(message)"
        case .invalidConfiguration(let message):
            return "Invalid order configuration: \(message)"
        case .riskLimitExceeded(let message):
            return "Risk limit exceeded: \(message)"
        case .marketClosed:
            return "Market is currently closed"
        case .insufficientFunds:
            return "Insufficient funds for this order"
        }
    }
}