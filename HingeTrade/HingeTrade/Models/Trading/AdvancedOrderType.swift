//
//  AdvancedOrderType.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import Foundation

// MARK: - Advanced Order Types

enum AdvancedOrderType: String, CaseIterable, Codable {
    case stopLoss = "stop_loss"
    case takeProfit = "take_profit" 
    case trailingStop = "trailing_stop"
    case bracketOrder = "bracket_order"
    case oneTriggersOther = "one_triggers_other"
    case oneCancelsOther = "one_cancels_other"
    case stopLimit = "stop_limit"
    case marketOnClose = "market_on_close"
    case limitOnClose = "limit_on_close"
    
    var displayName: String {
        switch self {
        case .stopLoss: return "Stop Loss"
        case .takeProfit: return "Take Profit"
        case .trailingStop: return "Trailing Stop"
        case .bracketOrder: return "Bracket Order"
        case .oneTriggersOther: return "One-Triggers-Other"
        case .oneCancelsOther: return "One-Cancels-Other"
        case .stopLimit: return "Stop Limit"
        case .marketOnClose: return "Market on Close"
        case .limitOnClose: return "Limit on Close"
        }
    }
    
    var description: String {
        switch self {
        case .stopLoss:
            return "Automatically sell when price drops to limit losses"
        case .takeProfit:
            return "Automatically sell when price reaches profit target"
        case .trailingStop:
            return "Stop loss that follows price movements to lock in profits"
        case .bracketOrder:
            return "Combined order with both take profit and stop loss"
        case .oneTriggersOther:
            return "When one order fills, it triggers another order"
        case .oneCancelsOther:
            return "When one order fills, it cancels the other order"
        case .stopLimit:
            return "Stop order that becomes a limit order when triggered"
        case .marketOnClose:
            return "Market order executed at market close"
        case .limitOnClose:
            return "Limit order executed at market close"
        }
    }
    
    var systemImage: String {
        switch self {
        case .stopLoss: return "shield.slash"
        case .takeProfit: return "target"
        case .trailingStop: return "arrow.up.and.down.and.arrow.left.and.right"
        case .bracketOrder: return "square.stack.3d.up"
        case .oneTriggersOther: return "arrow.triangle.branch"
        case .oneCancelsOther: return "xmark.circle.fill"
        case .stopLimit: return "minus.plus.and.fluid.batteryblock"
        case .marketOnClose: return "clock.badge.checkmark"
        case .limitOnClose: return "clock.badge"
        }
    }
    
    var riskLevel: RiskLevel {
        switch self {
        case .stopLoss, .takeProfit:
            return .low
        case .trailingStop, .stopLimit:
            return .medium
        case .bracketOrder, .oneTriggersOther, .oneCancelsOther:
            return .medium
        case .marketOnClose, .limitOnClose:
            return .low
        }
    }
}

// MARK: - Advanced Order Configuration

struct AdvancedOrderConfig: Codable, Identifiable {
    let id: String
    let orderType: AdvancedOrderType
    let symbol: String
    let quantity: Int
    let side: OrderSide
    
    // Stop Loss / Take Profit
    var stopPrice: Decimal?
    var takeProfitPrice: Decimal?
    
    // Trailing Stop
    var trailAmount: Decimal?
    var trailPercent: Double?
    
    // Bracket Order
    var parentOrderId: String?
    var stopLossPrice: Decimal?
    var takeProfitLimitPrice: Decimal?
    
    // OTO/OCO
    var triggerOrderId: String?
    var linkedOrderIds: [String] = []
    
    // Stop Limit
    var limitPrice: Decimal?
    
    // Time conditions
    var timeInForce: TimeInForce
    var goodTillDate: Date?
    
    // Risk management
    var maxLoss: Decimal?
    var maxGain: Decimal?
    var positionSizePercent: Double?
    
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        orderType: AdvancedOrderType,
        symbol: String,
        quantity: Int,
        side: OrderSide,
        timeInForce: TimeInForce = .day
    ) {
        self.id = id
        self.orderType = orderType
        self.symbol = symbol
        self.quantity = quantity
        self.side = side
        self.timeInForce = timeInForce
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Risk Management

enum RiskLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case extreme = "extreme"
    
    var color: String {
        switch self {
        case .low: return "00FF00"
        case .medium: return "FFFF00"
        case .high: return "FF8000"
        case .extreme: return "FF0000"
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .extreme: return "Extreme Risk"
        }
    }
}

struct RiskParameters: Codable {
    let maxPositionSize: Decimal
    let maxDailyLoss: Decimal
    let maxPortfolioRisk: Double // Percentage
    let requireStopLoss: Bool
    let maxLeverage: Double
    let allowOptionsTrading: Bool
    let allowMarginTrading: Bool
    
    static let conservative = RiskParameters(
        maxPositionSize: 10000,
        maxDailyLoss: 1000,
        maxPortfolioRisk: 0.02, // 2%
        requireStopLoss: true,
        maxLeverage: 1.0,
        allowOptionsTrading: false,
        allowMarginTrading: false
    )
    
    static let moderate = RiskParameters(
        maxPositionSize: 25000,
        maxDailyLoss: 2500,
        maxPortfolioRisk: 0.05, // 5%
        requireStopLoss: true,
        maxLeverage: 2.0,
        allowOptionsTrading: true,
        allowMarginTrading: false
    )
    
    static let aggressive = RiskParameters(
        maxPositionSize: 50000,
        maxDailyLoss: 5000,
        maxPortfolioRisk: 0.10, // 10%
        requireStopLoss: false,
        maxLeverage: 4.0,
        allowOptionsTrading: true,
        allowMarginTrading: true
    )
}

// MARK: - Position Sizing

struct PositionSizingCalculator {
    let accountBalance: Decimal
    let riskParameters: RiskParameters
    
    func calculatePositionSize(
        for symbol: String,
        entryPrice: Decimal,
        stopLoss: Decimal?,
        riskAmount: Decimal
    ) -> PositionSizeResult {
        guard let stopLoss = stopLoss else {
            // If no stop loss, use maximum position size based on risk parameters
            let maxShares = Int(truncating: (riskAmount / entryPrice) as NSDecimalNumber)
            let positionValue = entryPrice * Decimal(maxShares)
            
            return PositionSizeResult(
                recommendedShares: maxShares,
                positionValue: positionValue,
                riskAmount: riskAmount,
                riskPercentage: Double(truncating: (riskAmount / accountBalance) as NSDecimalNumber),
                stopLossDistance: nil,
                riskRewardRatio: nil,
                maxPositionSize: Int(truncating: (riskParameters.maxPositionSize / entryPrice) as NSDecimalNumber)
            )
        }
        
        let stopLossDistance = abs(entryPrice - stopLoss)
        let sharesBasedOnRisk = Int(truncating: (riskAmount / stopLossDistance) as NSDecimalNumber)
        let maxSharesBasedOnPosition = Int(truncating: (riskParameters.maxPositionSize / entryPrice) as NSDecimalNumber)
        
        let recommendedShares = min(sharesBasedOnRisk, maxSharesBasedOnPosition)
        let positionValue = entryPrice * Decimal(recommendedShares)
        let actualRiskAmount = stopLossDistance * Decimal(recommendedShares)
        
        return PositionSizeResult(
            recommendedShares: recommendedShares,
            positionValue: positionValue,
            riskAmount: actualRiskAmount,
            riskPercentage: Double(truncating: (actualRiskAmount / accountBalance) as NSDecimalNumber),
            stopLossDistance: stopLossDistance,
            riskRewardRatio: nil, // Would calculate based on take profit
            maxPositionSize: maxSharesBasedOnPosition
        )
    }
}

struct PositionSizeResult {
    let recommendedShares: Int
    let positionValue: Decimal
    let riskAmount: Decimal
    let riskPercentage: Double
    let stopLossDistance: Decimal?
    let riskRewardRatio: Double?
    let maxPositionSize: Int
    
    var isWithinRiskLimits: Bool {
        return riskPercentage <= 0.10 // 10% max risk
    }
    
    var riskLevel: RiskLevel {
        switch riskPercentage {
        case 0...0.02: return .low
        case 0.02...0.05: return .medium
        case 0.05...0.10: return .high
        default: return .extreme
        }
    }
}

// MARK: - Order Validation

struct OrderValidationResult {
    let isValid: Bool
    let errors: [OrderValidationError]
    let warnings: [OrderValidationWarning]
    let riskAssessment: RiskAssessment
}

enum OrderValidationError: LocalizedError {
    case insufficientFunds(required: Decimal, available: Decimal)
    case exceedsPositionLimit(requested: Decimal, limit: Decimal)
    case exceedsRiskLimit(riskPercent: Double, limit: Double)
    case invalidPriceRange(price: Decimal, min: Decimal, max: Decimal)
    case marketClosed
    case symbolNotTradeable
    case missingStopLoss
    case invalidOrderCombination
    
    var errorDescription: String? {
        switch self {
        case .insufficientFunds(let required, let available):
            return "Insufficient funds: Required \(required.formatted(.currency(code: "USD"))), Available \(available.formatted(.currency(code: "USD")))"
        case .exceedsPositionLimit(let requested, let limit):
            return "Position size exceeds limit: \(requested.formatted(.currency(code: "USD"))) > \(limit.formatted(.currency(code: "USD")))"
        case .exceedsRiskLimit(let riskPercent, let limit):
            return "Risk exceeds limit: \((riskPercent * 100).formatted(.number.precision(.fractionLength(1))))% > \((limit * 100).formatted(.number.precision(.fractionLength(1))))%"
        case .invalidPriceRange(let price, let min, let max):
            return "Price \(price.formatted(.currency(code: "USD"))) outside valid range \(min.formatted(.currency(code: "USD"))) - \(max.formatted(.currency(code: "USD")))"
        case .marketClosed:
            return "Market is currently closed"
        case .symbolNotTradeable:
            return "Symbol is not currently tradeable"
        case .missingStopLoss:
            return "Stop loss is required for this order type"
        case .invalidOrderCombination:
            return "Invalid combination of order parameters"
        }
    }
}

enum OrderValidationWarning: LocalizedError {
    case highRisk(riskPercent: Double)
    case largePosition(positionSize: Decimal)
    case wideSpread(spread: Decimal)
    case afterHours
    case lowVolume
    case volatileStock
    
    var warningDescription: String? {
        switch self {
        case .highRisk(let riskPercent):
            return "High risk order: \((riskPercent * 100).formatted(.number.precision(.fractionLength(1))))% of portfolio at risk"
        case .largePosition(let positionSize):
            return "Large position size: \(positionSize.formatted(.currency(code: "USD")))"
        case .wideSpread(let spread):
            return "Wide bid-ask spread: \(spread.formatted(.currency(code: "USD")))"
        case .afterHours:
            return "Trading outside regular market hours"
        case .lowVolume:
            return "Low trading volume - may affect execution"
        case .volatileStock:
            return "Highly volatile stock - consider smaller position size"
        }
    }
}

struct RiskAssessment {
    let overallRisk: RiskLevel
    let positionSizeRisk: RiskLevel
    let priceRisk: RiskLevel
    let liquidityRisk: RiskLevel
    let timeRisk: RiskLevel
    let recommendations: [String]
    
    var riskScore: Double {
        let risks = [overallRisk, positionSizeRisk, priceRisk, liquidityRisk, timeRisk]
        let scores = risks.map { risk in
            switch risk {
            case .low: return 1.0
            case .medium: return 2.0
            case .high: return 3.0
            case .extreme: return 4.0
            }
        }
        return scores.reduce(0, +) / Double(scores.count)
    }
}