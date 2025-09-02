//
//  OptionsContract.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import Foundation

// MARK: - Options Contract

struct OptionsContract: Identifiable, Codable {
    let id: String
    let symbol: String // Underlying symbol
    let contractSymbol: String // Full options symbol
    let strike: Decimal
    let expiration: Date
    let optionType: OptionType
    
    // Market Data
    let bid: Decimal
    let ask: Decimal
    let lastPrice: Decimal
    let volume: Int
    let openInterest: Int
    let impliedVolatility: Double
    
    // Greeks
    let delta: Double
    let gamma: Double
    let theta: Double
    let vega: Double
    let rho: Double?
    
    // Additional Info
    let daysToExpiration: Int
    let isInTheMoney: Bool
    let intrinsicValue: Decimal
    let timeValue: Decimal
    
    var midPrice: Decimal {
        (bid + ask) / 2
    }
    
    var bidAskSpread: Decimal {
        ask - bid
    }
    
    var spreadPercentage: Double {
        guard midPrice > 0 else { return 0 }
        return Double(truncating: (bidAskSpread / midPrice) as NSNumber) * 100
    }
    
    var moneyness: Moneyness {
        if isInTheMoney {
            return optionType == .call ? .inTheMoneyCall : .inTheMoneyPut
        } else {
            return optionType == .call ? .outOfTheMoneyCall : .outOfTheMoneyPut
        }
    }
    
    var liquidityRating: LiquidityRating {
        switch volume {
        case 0...10: return .poor
        case 11...50: return .fair
        case 51...200: return .good
        default: return .excellent
        }
    }
    
    var expirationCategory: ExpirationCategory {
        switch daysToExpiration {
        case 0...7: return .weekly
        case 8...30: return .monthly
        case 31...90: return .quarterly
        default: return .leaps
        }
    }
}

enum OptionType: String, Codable, CaseIterable {
    case call = "call"
    case put = "put"
    
    var displayName: String {
        switch self {
        case .call: return "Call"
        case .put: return "Put"
        }
    }
    
    var systemImage: String {
        switch self {
        case .call: return "arrow.up.circle.fill"
        case .put: return "arrow.down.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .call: return "00FF00"
        case .put: return "FF0000"
        }
    }
}

enum Moneyness: String, CaseIterable {
    case inTheMoneyCall = "itm_call"
    case inTheMoneyPut = "itm_put"
    case outOfTheMoneyCall = "otm_call"
    case outOfTheMoneyPut = "otm_put"
    case atTheMoney = "atm"
    
    var displayName: String {
        switch self {
        case .inTheMoneyCall: return "ITM Call"
        case .inTheMoneyPut: return "ITM Put"
        case .outOfTheMoneyCall: return "OTM Call"
        case .outOfTheMoneyPut: return "OTM Put"
        case .atTheMoney: return "ATM"
        }
    }
    
    var color: String {
        switch self {
        case .inTheMoneyCall, .inTheMoneyPut: return "00FF00"
        case .outOfTheMoneyCall, .outOfTheMoneyPut: return "FF0000"
        case .atTheMoney: return "FFFF00"
        }
    }
}

enum LiquidityRating: String, CaseIterable {
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
    
    var displayName: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var color: String {
        switch self {
        case .poor: return "FF0000"
        case .fair: return "FF8000"
        case .good: return "FFFF00"
        case .excellent: return "00FF00"
        }
    }
}

enum ExpirationCategory: String, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case leaps = "leaps"
    
    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .leaps: return "LEAPS"
        }
    }
}

// MARK: - Options Strategy

enum OptionsStrategy: String, CaseIterable {
    case buyCall = "buy_call"
    case buyPut = "buy_put"
    case sellCall = "sell_call"
    case sellPut = "sell_put"
    case coveredCall = "covered_call"
    case protectivePut = "protective_put"
    case bullCallSpread = "bull_call_spread"
    case bearPutSpread = "bear_put_spread"
    case straddle = "straddle"
    case strangle = "strangle"
    case ironCondor = "iron_condor"
    case butterflySpread = "butterfly_spread"
    
    var displayName: String {
        switch self {
        case .buyCall: return "Buy Call"
        case .buyPut: return "Buy Put"
        case .sellCall: return "Sell Call"
        case .sellPut: return "Sell Put"
        case .coveredCall: return "Covered Call"
        case .protectivePut: return "Protective Put"
        case .bullCallSpread: return "Bull Call Spread"
        case .bearPutSpread: return "Bear Put Spread"
        case .straddle: return "Straddle"
        case .strangle: return "Strangle"
        case .ironCondor: return "Iron Condor"
        case .butterflySpread: return "Butterfly Spread"
        }
    }
    
    var description: String {
        switch self {
        case .buyCall:
            return "Bullish strategy with unlimited upside potential"
        case .buyPut:
            return "Bearish strategy with limited risk"
        case .sellCall:
            return "Neutral to bearish strategy collecting premium"
        case .sellPut:
            return "Neutral to bullish strategy collecting premium"
        case .coveredCall:
            return "Income strategy on owned stock"
        case .protectivePut:
            return "Insurance strategy for owned stock"
        case .bullCallSpread:
            return "Bullish strategy with limited risk and reward"
        case .bearPutSpread:
            return "Bearish strategy with limited risk and reward"
        case .straddle:
            return "Volatility strategy expecting large price movement"
        case .strangle:
            return "Volatility strategy with wider profit range"
        case .ironCondor:
            return "Neutral strategy profiting from low volatility"
        case .butterflySpread:
            return "Neutral strategy with precise profit target"
        }
    }
    
    var complexity: StrategyComplexity {
        switch self {
        case .buyCall, .buyPut, .sellCall, .sellPut:
            return .basic
        case .coveredCall, .protectivePut:
            return .intermediate
        case .bullCallSpread, .bearPutSpread, .straddle, .strangle:
            return .intermediate
        case .ironCondor, .butterflySpread:
            return .advanced
        }
    }
    
    var requiredLegs: Int {
        switch self {
        case .buyCall, .buyPut, .sellCall, .sellPut:
            return 1
        case .coveredCall, .protectivePut, .bullCallSpread, .bearPutSpread, .straddle, .strangle:
            return 2
        case .butterflySpread:
            return 3
        case .ironCondor:
            return 4
        }
    }
    
    var systemImage: String {
        switch self {
        case .buyCall: return "arrow.up.circle.fill"
        case .buyPut: return "arrow.down.circle.fill"
        case .sellCall: return "arrow.up.circle"
        case .sellPut: return "arrow.down.circle"
        case .coveredCall: return "shield.lefthalf.filled"
        case .protectivePut: return "shield.righthalf.filled"
        case .bullCallSpread: return "arrow.up.arrow.down.circle"
        case .bearPutSpread: return "arrow.down.arrow.up.circle"
        case .straddle: return "arrow.left.and.right.circle"
        case .strangle: return "arrow.up.and.down.circle"
        case .ironCondor: return "square.3.layers.3d"
        case .butterflySpread: return "triangle.and.line.vertical.and.triangle.fill"
        }
    }
}

enum StrategyComplexity: String, CaseIterable {
    case basic = "basic"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var color: String {
        switch self {
        case .basic: return "00FF00"
        case .intermediate: return "FFFF00"
        case .advanced: return "FF8000"
        case .expert: return "FF0000"
        }
    }
}

// MARK: - Options Chain Data

struct OptionsChain: Identifiable {
    let id: String
    let symbol: String
    let underlyingPrice: Decimal
    let expirations: [Date]
    let strikes: [Decimal]
    let callOptions: [OptionsContract]
    let putOptions: [OptionsContract]
    let impliedVolatilityRank: Double
    let impliedVolatilityPercentile: Double
    
    func getCallOption(strike: Decimal, expiration: Date) -> OptionsContract? {
        return callOptions.first { $0.strike == strike && Calendar.current.isDate($0.expiration, inSameDayAs: expiration) }
    }
    
    func getPutOption(strike: Decimal, expiration: Date) -> OptionsContract? {
        return putOptions.first { $0.strike == strike && Calendar.current.isDate($0.expiration, inSameDayAs: expiration) }
    }
    
    func getATMStrike() -> Decimal {
        return strikes.min(by: { abs($0 - underlyingPrice) < abs($1 - underlyingPrice) }) ?? underlyingPrice
    }
    
    func getStrikes(around strike: Decimal, count: Int = 5) -> [Decimal] {
        let sortedStrikes = strikes.sorted()
        guard let index = sortedStrikes.firstIndex(of: strike) else { return Array(sortedStrikes.prefix(count)) }
        
        let startIndex = max(0, index - count/2)
        let endIndex = min(sortedStrikes.count, startIndex + count)
        
        return Array(sortedStrikes[startIndex..<endIndex])
    }
}

// MARK: - Options Position

struct OptionsPosition: Identifiable, Codable {
    let id: String
    let contract: OptionsContract
    let quantity: Int // Positive for long, negative for short
    let openPrice: Decimal
    let openDate: Date
    let strategy: OptionsStrategy
    
    var marketValue: Decimal {
        contract.lastPrice * Decimal(abs(quantity)) * 100 // Options multiply by 100
    }
    
    var unrealizedPnL: Decimal {
        let currentValue = contract.lastPrice * Decimal(abs(quantity)) * 100
        let costBasis = openPrice * Decimal(abs(quantity)) * 100
        
        return quantity > 0 ? currentValue - costBasis : costBasis - currentValue
    }
    
    var unrealizedPnLPercent: Double {
        let costBasis = openPrice * Decimal(abs(quantity)) * 100
        guard costBasis > 0 else { return 0 }
        return Double(truncating: (unrealizedPnL / costBasis) as NSNumber)
    }
    
    var daysHeld: Int {
        Calendar.current.dateComponents([.day], from: openDate, to: Date()).day ?? 0
    }
    
    var isLong: Bool {
        return quantity > 0
    }
    
    var isShort: Bool {
        return quantity < 0
    }
    
    var riskLevel: RiskLevel {
        // Assess risk based on multiple factors
        var riskScore = 0
        
        // Time decay risk
        if contract.daysToExpiration < 30 {
            riskScore += 1
        }
        
        // Liquidity risk
        if contract.liquidityRating == .poor {
            riskScore += 2
        } else if contract.liquidityRating == .fair {
            riskScore += 1
        }
        
        // Moneyness risk for long positions
        if isLong && !contract.isInTheMoney && contract.daysToExpiration < 45 {
            riskScore += 1
        }
        
        // High implied volatility risk
        if contract.impliedVolatility > 0.60 {
            riskScore += 1
        }
        
        switch riskScore {
        case 0...1: return .low
        case 2...3: return .medium
        case 4...5: return .high
        default: return .extreme
        }
    }
}

// MARK: - Options Order

struct OptionsOrder: Identifiable, Codable {
    let id: String
    let strategy: OptionsStrategy
    let legs: [OptionsOrderLeg]
    let netDebit: Decimal? // Positive for debit
    let netCredit: Decimal? // Positive for credit
    let maxProfit: Decimal?
    let maxLoss: Decimal?
    let breakEvenPoints: [Decimal]
    let probabilityOfProfit: Double?
    let status: OrderStatus
    let submittedAt: Date
    let filledAt: Date?
    
    var orderType: OptionsOrderType {
        if legs.count == 1 {
            return legs[0].action == .buy ? .buyToOpen : .sellToOpen
        } else {
            return .multiLeg
        }
    }
    
    var totalCost: Decimal {
        return netDebit ?? -(netCredit ?? 0)
    }
}

struct OptionsOrderLeg: Identifiable, Codable {
    let id: String
    let contract: OptionsContract
    let action: OptionsAction
    let quantity: Int
    let price: Decimal
    let timeInForce: TimeInForce
}

enum OptionsAction: String, Codable {
    case buy = "buy"
    case sell = "sell"
    
    var displayName: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }
}

enum OptionsOrderType: String, Codable {
    case buyToOpen = "buy_to_open"
    case sellToOpen = "sell_to_open"
    case buyToClose = "buy_to_close"
    case sellToClose = "sell_to_close"
    case multiLeg = "multi_leg"
    
    var displayName: String {
        switch self {
        case .buyToOpen: return "Buy to Open"
        case .sellToOpen: return "Sell to Open"
        case .buyToClose: return "Buy to Close"
        case .sellToClose: return "Sell to Close"
        case .multiLeg: return "Multi-Leg"
        }
    }
}

// MARK: - Risk Analysis for Options

struct OptionsRiskAnalysis {
    let maxLoss: Decimal
    let maxProfit: Decimal?
    let breakEvenPoints: [Decimal]
    let probabilityOfProfit: Double
    let timeDecayRisk: TimeDecayRisk
    let volatilityRisk: VolatilityRisk
    let liquidityRisk: LiquidityRisk
    let pinRisk: PinRisk?
    let assignmentRisk: AssignmentRisk?
    
    enum TimeDecayRisk: String {
        case low, medium, high, extreme
        
        var displayName: String { rawValue.capitalized }
        var color: String {
            switch self {
            case .low: return "00FF00"
            case .medium: return "FFFF00"
            case .high: return "FF8000"
            case .extreme: return "FF0000"
            }
        }
    }
    
    enum VolatilityRisk: String {
        case low, medium, high
        
        var displayName: String { rawValue.capitalized }
    }
    
    enum LiquidityRisk: String {
        case low, medium, high
        
        var displayName: String { rawValue.capitalized }
    }
    
    enum PinRisk: String {
        case low, medium, high
        
        var displayName: String { rawValue.capitalized }
    }
    
    enum AssignmentRisk: String {
        case low, medium, high
        
        var displayName: String { rawValue.capitalized }
    }
}