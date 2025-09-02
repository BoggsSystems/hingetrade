//
//  OptionsViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class OptionsViewModel: ObservableObject {
    // MARK: - Options Chain Data
    @Published var optionsChain: OptionsChain?
    @Published var availableExpirations: [Date] = []
    @Published var selectedExpiration: Date?
    @Published var selectedContract: OptionsContract?
    
    // MARK: - Positions
    @Published var optionsPositions: [OptionsPosition] = []
    @Published var totalOptionsValue: Decimal = 0
    @Published var totalUnrealizedPnL: Decimal = 0
    @Published var totalDayChange: Decimal = 0
    
    // MARK: - Strategies
    @Published var strategyTemplates: [StrategyTemplate] = []
    @Published var customStrategies: [OptionsStrategy] = []
    
    // MARK: - Analytics
    @Published var portfolioGreeks: PortfolioGreeks?
    @Published var riskMetrics: OptionsRiskMetrics?
    @Published var impliedVolatilityAnalysis: IVAnalysis?
    
    // MARK: - State
    @Published var isLoading = false
    @Published var error: OptionsError?
    @Published var showingError = false
    
    // Services
    private let optionsService: OptionsService
    private let optionsAnalyticsService: OptionsAnalyticsService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        optionsService: OptionsService = OptionsService(),
        optionsAnalyticsService: OptionsAnalyticsService = OptionsAnalyticsService()
    ) {
        self.optionsService = optionsService
        self.optionsAnalyticsService = optionsAnalyticsService
        
        setupBindings()
        loadStrategyTemplates()
    }
    
    // MARK: - Data Loading
    
    func loadOptionsChain(for symbol: String) async {
        isLoading = true
        error = nil
        
        do {
            let chain = try await optionsService.getOptionsChain(symbol: symbol)
            
            optionsChain = chain
            availableExpirations = chain.expirations.sorted()
            
            if selectedExpiration == nil && !availableExpirations.isEmpty {
                selectedExpiration = availableExpirations.first
            }
            
            // Load related data
            async let positionsTask = loadOptionsPositions(for: symbol)
            async let analyticsTask = loadOptionsAnalytics(for: symbol)
            
            await positionsTask
            await analyticsTask
            
        } catch {
            self.error = OptionsError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    private func loadOptionsPositions(for symbol: String) async {
        do {
            let positions = try await optionsService.getOptionsPositions(symbol: symbol)
            optionsPositions = positions
            
            updatePositionsSummary()
            
        } catch {
            // Handle silently for now - positions are not critical for chain viewing
        }
    }
    
    private func loadOptionsAnalytics(for symbol: String) async {
        do {
            async let greeksTask = optionsAnalyticsService.calculatePortfolioGreeks(positions: optionsPositions)
            async let riskTask = optionsAnalyticsService.calculateRiskMetrics(positions: optionsPositions)
            async let ivTask = optionsAnalyticsService.analyzeImpliedVolatility(chain: optionsChain)
            
            let (greeks, risk, iv) = try await (greeksTask, riskTask, ivTask)
            
            portfolioGreeks = greeks
            riskMetrics = risk
            impliedVolatilityAnalysis = iv
            
        } catch {
            // Handle analytics errors silently
        }
    }
    
    // MARK: - Selection Management
    
    func setSelectedExpiration(_ date: Date) {
        selectedExpiration = date
        
        // Update filtered options for the selected expiration
        updateFilteredOptions()
    }
    
    func selectContract(_ contract: OptionsContract) {
        selectedContract = contract
    }
    
    private func updateFilteredOptions() {
        // This would filter the options chain by selected expiration
        // Implementation would update displayed contracts
    }
    
    // MARK: - Strategy Management
    
    private func loadStrategyTemplates() {
        strategyTemplates = [
            StrategyTemplate(
                id: "covered-call-conservative",
                name: "Conservative Covered Call",
                strategy: .coveredCall,
                description: "Generate income on existing stock position with OTM calls",
                legs: [] // Would be populated with actual legs
            ),
            StrategyTemplate(
                id: "protective-put-insurance",
                name: "Portfolio Insurance Put",
                strategy: .protectivePut,
                description: "Protect stock position with ATM or ITM puts",
                legs: []
            ),
            StrategyTemplate(
                id: "bull-call-spread-moderate",
                name: "Moderate Bull Call Spread",
                strategy: .bullCallSpread,
                description: "Limited risk bullish strategy for moderate gains",
                legs: []
            ),
            StrategyTemplate(
                id: "iron-condor-income",
                name: "Monthly Income Condor",
                strategy: .ironCondor,
                description: "Neutral income strategy for sideways markets",
                legs: []
            )
        ]
    }
    
    func createCustomStrategy(_ strategy: OptionsStrategy, legs: [OptionsOrderLeg]) async {
        do {
            // This would create and validate a custom options strategy
            // For now, just add to custom strategies list
            customStrategies.append(strategy)
            
        } catch {
            self.error = OptionsError.strategyCreationFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    // MARK: - Order Management
    
    func submitOptionsOrder(_ order: OptionsOrder) async {
        do {
            _ = try await optionsService.submitOptionsOrder(order)
            
            // Refresh positions after order submission
            if let symbol = optionsChain?.symbol {
                await loadOptionsPositions(for: symbol)
            }
            
        } catch {
            self.error = OptionsError.orderSubmissionFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func closePosition(_ position: OptionsPosition) async {
        do {
            // Create closing order
            let closingOrder = createClosingOrder(for: position)
            await submitOptionsOrder(closingOrder)
            
        } catch {
            self.error = OptionsError.positionClosingFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    private func createClosingOrder(for position: OptionsPosition) -> OptionsOrder {
        let action: OptionsAction = position.isLong ? .sell : .buy
        
        let leg = OptionsOrderLeg(
            id: UUID().uuidString,
            contract: position.contract,
            action: action,
            quantity: abs(position.quantity),
            price: position.contract.midPrice,
            timeInForce: .day
        )
        
        return OptionsOrder(
            id: UUID().uuidString,
            strategy: .buyCall, // Would be determined by position type
            legs: [leg],
            netDebit: position.isShort ? position.contract.midPrice * Decimal(position.quantity) * 100 : nil,
            netCredit: position.isLong ? position.contract.midPrice * Decimal(position.quantity) * 100 : nil,
            maxProfit: nil,
            maxLoss: nil,
            breakEvenPoints: [],
            probabilityOfProfit: nil,
            status: .pending,
            submittedAt: Date()
        )
    }
    
    // MARK: - Position Analysis
    
    private func updatePositionsSummary() {
        totalOptionsValue = optionsPositions.reduce(0) { $0 + $1.marketValue }
        totalUnrealizedPnL = optionsPositions.reduce(0) { $0 + $1.unrealizedPnL }
        
        // Calculate day change (would need previous day's values)
        totalDayChange = totalUnrealizedPnL * Decimal(0.1) // Placeholder calculation
    }
    
    // MARK: - Risk Analysis
    
    func analyzeStrategyRisk(_ strategy: OptionsStrategy, legs: [OptionsOrderLeg]) async -> OptionsRiskAnalysis? {
        do {
            return try await optionsAnalyticsService.analyzeStrategyRisk(strategy: strategy, legs: legs)
        } catch {
            return nil
        }
    }
    
    func calculateBreakEven(for strategy: OptionsStrategy, legs: [OptionsOrderLeg]) -> [Decimal] {
        // Simplified break-even calculation
        // Real implementation would be more sophisticated based on strategy type
        
        switch strategy {
        case .buyCall, .sellPut:
            // Break-even = Strike + Premium Paid
            if let leg = legs.first {
                return [leg.contract.strike + leg.price]
            }
            
        case .buyPut, .sellCall:
            // Break-even = Strike - Premium Paid
            if let leg = legs.first {
                return [leg.contract.strike - leg.price]
            }
            
        case .straddle, .strangle:
            // Two break-even points
            if legs.count >= 2 {
                let totalPremium = legs.reduce(0) { $0 + $1.price }
                let strike = legs[0].contract.strike
                return [strike - totalPremium, strike + totalPremium]
            }
            
        default:
            // More complex strategies would need detailed calculations
            break
        }
        
        return []
    }
    
    // MARK: - Market Analysis
    
    func getImpliedVolatilitySkew() -> [IVSkewPoint] {
        guard let chain = optionsChain else { return [] }
        
        // Calculate IV skew across strikes for selected expiration
        var skewPoints: [IVSkewPoint] = []
        
        let strikes = chain.strikes.sorted()
        for strike in strikes {
            if let callOption = chain.getCallOption(strike: strike, expiration: selectedExpiration ?? Date()) {
                skewPoints.append(IVSkewPoint(
                    strike: strike,
                    moneyness: Double(truncating: (strike / chain.underlyingPrice) as NSNumber),
                    impliedVolatility: callOption.impliedVolatility
                ))
            }
        }
        
        return skewPoints
    }
    
    func getVolatilitySmile() -> [VolatilitySmilePoint] {
        guard let chain = optionsChain,
              let expiration = selectedExpiration else { return [] }
        
        var smilePoints: [VolatilitySmilePoint] = []
        
        let strikes = chain.strikes.sorted()
        for strike in strikes {
            if let callOption = chain.getCallOption(strike: strike, expiration: expiration),
               let putOption = chain.getPutOption(strike: strike, expiration: expiration) {
                
                let moneyness = Double(truncating: (strike / chain.underlyingPrice) as NSNumber)
                let avgIV = (callOption.impliedVolatility + putOption.impliedVolatility) / 2
                
                smilePoints.append(VolatilitySmilePoint(
                    strike: strike,
                    moneyness: moneyness,
                    callIV: callOption.impliedVolatility,
                    putIV: putOption.impliedVolatility,
                    averageIV: avgIV
                ))
            }
        }
        
        return smilePoints
    }
    
    // MARK: - Bindings
    
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
    }
}

// MARK: - Supporting Models

struct PortfolioGreeks {
    let totalDelta: Double
    let totalGamma: Double
    let totalTheta: Double
    let totalVega: Double
    let totalRho: Double
    let netLiquidity: Decimal
    
    var deltaRisk: RiskLevel {
        let absDelta = abs(totalDelta)
        switch absDelta {
        case 0...10: return .low
        case 10...25: return .medium
        case 25...50: return .high
        default: return .extreme
        }
    }
    
    var thetaDecay: Decimal {
        return Decimal(totalTheta)
    }
}

struct OptionsRiskMetrics {
    let maxLoss: Decimal
    let maxProfit: Decimal?
    let probabilityOfProfit: Double
    let expectedValue: Decimal
    let riskRewardRatio: Double?
    let timeDecayRisk: Double
    let volatilityRisk: Double
    let liquidityScore: Double
}

struct IVAnalysis {
    let averageIV: Double
    let ivRank: Double // Percentile of current IV vs 1-year range
    let ivPercentile: Double
    let skewness: Double
    let termStructure: [IVTermPoint]
    let recommendation: IVRecommendation
}

struct IVTermPoint {
    let expiration: Date
    let daysToExpiration: Int
    let averageIV: Double
}

enum IVRecommendation {
    case buy // Low IV, good time to buy options
    case sell // High IV, good time to sell options
    case neutral // IV at normal levels
    
    var displayName: String {
        switch self {
        case .buy: return "Favor Buying"
        case .sell: return "Favor Selling"
        case .neutral: return "Neutral"
        }
    }
    
    var color: String {
        switch self {
        case .buy: return "00FF00"
        case .sell: return "FF0000"
        case .neutral: return "FFFF00"
        }
    }
}

struct IVSkewPoint {
    let strike: Decimal
    let moneyness: Double
    let impliedVolatility: Double
}

struct VolatilitySmilePoint {
    let strike: Decimal
    let moneyness: Double
    let callIV: Double
    let putIV: Double
    let averageIV: Double
}

// MARK: - Services

protocol OptionsService {
    func getOptionsChain(symbol: String) async throws -> OptionsChain
    func getOptionsPositions(symbol: String) async throws -> [OptionsPosition]
    func submitOptionsOrder(_ order: OptionsOrder) async throws -> String
    func getOptionsQuote(contractSymbol: String) async throws -> OptionsContract
}

class OptionsService: OptionsService {
    func getOptionsChain(symbol: String) async throws -> OptionsChain {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        let underlyingPrice: Decimal = 175.50 // AAPL example price
        let expirations = generateExpirations()
        let strikes = generateStrikes(around: underlyingPrice)
        
        let callOptions = generateCallOptions(strikes: strikes, expirations: expirations, underlyingPrice: underlyingPrice)
        let putOptions = generatePutOptions(strikes: strikes, expirations: expirations, underlyingPrice: underlyingPrice)
        
        return OptionsChain(
            id: UUID().uuidString,
            symbol: symbol,
            underlyingPrice: underlyingPrice,
            expirations: expirations,
            strikes: strikes,
            callOptions: callOptions,
            putOptions: putOptions,
            impliedVolatilityRank: 0.65, // 65th percentile
            impliedVolatilityPercentile: 0.72 // 72nd percentile
        )
    }
    
    func getOptionsPositions(symbol: String) async throws -> [OptionsPosition] {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        // Mock positions
        return [
            // Would return actual options positions
        ]
    }
    
    func submitOptionsOrder(_ order: OptionsOrder) async throws -> String {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        
        // Simulate potential failure
        if Bool.random() && Bool.random() { // 25% failure rate
            throw OptionsError.orderSubmissionFailed("Insufficient buying power for options trade")
        }
        
        return UUID().uuidString
    }
    
    func getOptionsQuote(contractSymbol: String) async throws -> OptionsContract {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Mock quote - would return real options quote
        return generateMockContract()
    }
    
    // MARK: - Mock Data Generation
    
    private func generateExpirations() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        var expirations: [Date] = []
        
        // Weekly expirations for next 4 weeks
        for week in 1...4 {
            if let friday = calendar.date(byAdding: .weekOfYear, value: week, to: today) {
                let weekday = calendar.component(.weekday, from: friday)
                let daysToFriday = (6 - weekday + 7) % 7
                if let expiration = calendar.date(byAdding: .day, value: daysToFriday, to: friday) {
                    expirations.append(expiration)
                }
            }
        }
        
        // Monthly expirations for next 6 months
        for month in 1...6 {
            if let monthlyExpiration = calendar.date(byAdding: .month, value: month, to: today) {
                // Third Friday of the month
                let components = calendar.dateComponents([.year, .month], from: monthlyExpiration)
                if let firstOfMonth = calendar.date(from: components) {
                    let weekday = calendar.component(.weekday, from: firstOfMonth)
                    let daysToFirstFriday = (6 - weekday + 7) % 7
                    if let thirdFriday = calendar.date(byAdding: .day, value: daysToFirstFriday + 14, to: firstOfMonth) {
                        expirations.append(thirdFriday)
                    }
                }
            }
        }
        
        return expirations.sorted()
    }
    
    private func generateStrikes(around price: Decimal) -> [Decimal] {
        var strikes: [Decimal] = []
        let baseStrike = price
        let increment: Decimal = 2.50
        
        // Generate strikes from 20% below to 20% above current price
        let lowerBound = baseStrike * 0.8
        let upperBound = baseStrike * 1.2
        
        var currentStrike = (lowerBound / increment).rounded(.down) * increment
        
        while currentStrike <= upperBound {
            strikes.append(currentStrike)
            currentStrike += increment
        }
        
        return strikes
    }
    
    private func generateCallOptions(strikes: [Decimal], expirations: [Date], underlyingPrice: Decimal) -> [OptionsContract] {
        var calls: [OptionsContract] = []
        
        for expiration in expirations {
            let daysToExp = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
            
            for strike in strikes {
                let contract = generateMockCallContract(
                    strike: strike,
                    expiration: expiration,
                    underlyingPrice: underlyingPrice,
                    daysToExpiration: daysToExp
                )
                calls.append(contract)
            }
        }
        
        return calls
    }
    
    private func generatePutOptions(strikes: [Decimal], expirations: [Date], underlyingPrice: Decimal) -> [OptionsContract] {
        var puts: [OptionsContract] = []
        
        for expiration in expirations {
            let daysToExp = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
            
            for strike in strikes {
                let contract = generateMockPutContract(
                    strike: strike,
                    expiration: expiration,
                    underlyingPrice: underlyingPrice,
                    daysToExpiration: daysToExp
                )
                puts.append(contract)
            }
        }
        
        return puts
    }
    
    private func generateMockCallContract(strike: Decimal, expiration: Date, underlyingPrice: Decimal, daysToExpiration: Int) -> OptionsContract {
        let isITM = strike < underlyingPrice
        let intrinsicValue = max(0, underlyingPrice - strike)
        
        // Mock pricing based on moneyness and time to expiration
        let timeValue = Decimal(Double.random(in: 0.10...5.00))
        let lastPrice = intrinsicValue + timeValue
        
        let bid = lastPrice - Decimal(0.05)
        let ask = lastPrice + Decimal(0.05)
        
        return OptionsContract(
            id: UUID().uuidString,
            symbol: "AAPL", // Mock underlying
            contractSymbol: "AAPL\(expiration.formatted(.dateTime.month(.twoDigits).day(.twoDigits).year(.twoDigits)))C\(strike.formatted(.number.precision(.fractionLength(0))))",
            strike: strike,
            expiration: expiration,
            optionType: .call,
            bid: bid,
            ask: ask,
            lastPrice: lastPrice,
            volume: Int.random(in: 0...1000),
            openInterest: Int.random(in: 100...10000),
            impliedVolatility: Double.random(in: 0.15...0.80),
            delta: isITM ? Double.random(in: 0.50...0.95) : Double.random(in: 0.05...0.50),
            gamma: Double.random(in: 0.001...0.05),
            theta: Double.random(in: -0.50...0.05),
            vega: Double.random(in: 0.05...0.30),
            rho: Double.random(in: 0.01...0.15),
            daysToExpiration: daysToExpiration,
            isInTheMoney: isITM,
            intrinsicValue: intrinsicValue,
            timeValue: timeValue
        )
    }
    
    private func generateMockPutContract(strike: Decimal, expiration: Date, underlyingPrice: Decimal, daysToExpiration: Int) -> OptionsContract {
        let isITM = strike > underlyingPrice
        let intrinsicValue = max(0, strike - underlyingPrice)
        
        // Mock pricing based on moneyness and time to expiration
        let timeValue = Decimal(Double.random(in: 0.10...5.00))
        let lastPrice = intrinsicValue + timeValue
        
        let bid = lastPrice - Decimal(0.05)
        let ask = lastPrice + Decimal(0.05)
        
        return OptionsContract(
            id: UUID().uuidString,
            symbol: "AAPL", // Mock underlying
            contractSymbol: "AAPL\(expiration.formatted(.dateTime.month(.twoDigits).day(.twoDigits).year(.twoDigits)))P\(strike.formatted(.number.precision(.fractionLength(0))))",
            strike: strike,
            expiration: expiration,
            optionType: .put,
            bid: bid,
            ask: ask,
            lastPrice: lastPrice,
            volume: Int.random(in: 0...1000),
            openInterest: Int.random(in: 100...10000),
            impliedVolatility: Double.random(in: 0.15...0.80),
            delta: isITM ? Double.random(in: -0.95...(-0.50)) : Double.random(in: -0.50...(-0.05)),
            gamma: Double.random(in: 0.001...0.05),
            theta: Double.random(in: -0.50...(-0.05)),
            vega: Double.random(in: 0.05...0.30),
            rho: Double.random(in: -0.15...(-0.01)),
            daysToExpiration: daysToExpiration,
            isInTheMoney: isITM,
            intrinsicValue: intrinsicValue,
            timeValue: timeValue
        )
    }
    
    private func generateMockContract() -> OptionsContract {
        return generateMockCallContract(
            strike: 175,
            expiration: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            underlyingPrice: 175.50,
            daysToExpiration: 30
        )
    }
}

protocol OptionsAnalyticsService {
    func calculatePortfolioGreeks(positions: [OptionsPosition]) async throws -> PortfolioGreeks
    func calculateRiskMetrics(positions: [OptionsPosition]) async throws -> OptionsRiskMetrics
    func analyzeImpliedVolatility(chain: OptionsChain?) async throws -> IVAnalysis
    func analyzeStrategyRisk(strategy: OptionsStrategy, legs: [OptionsOrderLeg]) async throws -> OptionsRiskAnalysis
}

class OptionsAnalyticsService: OptionsAnalyticsService {
    func calculatePortfolioGreeks(positions: [OptionsPosition]) async throws -> PortfolioGreeks {
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Mock calculations
        return PortfolioGreeks(
            totalDelta: positions.reduce(0) { $0 + $1.contract.delta * Double($1.quantity) },
            totalGamma: positions.reduce(0) { $0 + $1.contract.gamma * Double($1.quantity) },
            totalTheta: positions.reduce(0) { $0 + $1.contract.theta * Double($1.quantity) },
            totalVega: positions.reduce(0) { $0 + $1.contract.vega * Double($1.quantity) },
            totalRho: positions.reduce(0) { $0 + ($1.contract.rho ?? 0) * Double($1.quantity) },
            netLiquidity: positions.reduce(0) { $0 + $1.marketValue }
        )
    }
    
    func calculateRiskMetrics(positions: [OptionsPosition]) async throws -> OptionsRiskMetrics {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock risk metrics
        return OptionsRiskMetrics(
            maxLoss: 5000, // Maximum potential loss
            maxProfit: 15000, // Maximum potential profit
            probabilityOfProfit: 0.65, // 65% probability of profit
            expectedValue: 750, // Expected profit/loss
            riskRewardRatio: 3.0, // 3:1 reward to risk
            timeDecayRisk: 0.25, // 25% of portfolio value at risk from time decay
            volatilityRisk: 0.40, // 40% sensitivity to volatility changes
            liquidityScore: 0.75 // 75% liquidity score
        )
    }
    
    func analyzeImpliedVolatility(chain: OptionsChain?) async throws -> IVAnalysis {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard let chain = chain else {
            throw OptionsError.insufficientData
        }
        
        // Mock IV analysis
        return IVAnalysis(
            averageIV: 0.35, // 35% average implied volatility
            ivRank: chain.impliedVolatilityRank,
            ivPercentile: chain.impliedVolatilityPercentile,
            skewness: -0.15, // Slight put skew
            termStructure: [], // Would be calculated from actual data
            recommendation: chain.impliedVolatilityRank > 0.70 ? .sell : chain.impliedVolatilityRank < 0.30 ? .buy : .neutral
        )
    }
    
    func analyzeStrategyRisk(strategy: OptionsStrategy, legs: [OptionsOrderLeg]) async throws -> OptionsRiskAnalysis {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock risk analysis
        return OptionsRiskAnalysis(
            maxLoss: legs.reduce(0) { $0 + $1.price * Decimal($1.quantity) * 100 },
            maxProfit: nil, // Would be calculated based on strategy
            breakEvenPoints: [], // Would be calculated based on strategy
            probabilityOfProfit: 0.50,
            timeDecayRisk: .medium,
            volatilityRisk: .medium,
            liquidityRisk: .low,
            pinRisk: .low,
            assignmentRisk: .low
        )
    }
}

// MARK: - Error Types

enum OptionsError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case orderSubmissionFailed(String)
    case strategyCreationFailed(String)
    case positionClosingFailed(String)
    case insufficientData
    case invalidStrategy(String)
    case riskLimitExceeded
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .orderSubmissionFailed(let message),
             .strategyCreationFailed(let message),
             .positionClosingFailed(let message),
             .invalidStrategy(let message):
            return message
        case .insufficientData:
            return "insufficient_data"
        case .riskLimitExceeded:
            return "risk_limit_exceeded"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load options data: \(message)"
        case .orderSubmissionFailed(let message):
            return "Options order failed: \(message)"
        case .strategyCreationFailed(let message):
            return "Strategy creation failed: \(message)"
        case .positionClosingFailed(let message):
            return "Failed to close position: \(message)"
        case .insufficientData:
            return "Insufficient data for options analysis"
        case .invalidStrategy(let message):
            return "Invalid options strategy: \(message)"
        case .riskLimitExceeded:
            return "Options trade exceeds risk limits"
        }
    }
}