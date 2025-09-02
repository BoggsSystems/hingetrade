import Foundation

// MARK: - Account Model
struct Account: Codable, Identifiable, Equatable {
    let id: String
    let accountNumber: String
    let status: String
    let currency: String
    let buyingPower: String
    let cash: String
    let portfolioValue: String
    let patternDayTrader: Bool
    let tradingBlocked: Bool
    let transfersBlocked: Bool
    let accountBlocked: Bool
    let tradeSuspendedByUser: Bool
    let multiplier: String
    let shortingEnabled: Bool
    let equity: String
    let lastEquity: String
    let longMarketValue: String
    let shortMarketValue: String
    let initialMargin: String
    let maintenanceMargin: String
    let lastMaintenanceMargin: String
    let sma: String
    let daytradeCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, status, currency, multiplier, equity, sma
        case accountNumber = "account_number"
        case buyingPower = "buying_power"
        case cash = "cash"
        case portfolioValue = "portfolio_value"
        case patternDayTrader = "pattern_day_trader"
        case tradingBlocked = "trading_blocked"
        case transfersBlocked = "transfers_blocked"
        case accountBlocked = "account_blocked"
        case tradeSuspendedByUser = "trade_suspended_by_user"
        case shortingEnabled = "shorting_enabled"
        case lastEquity = "last_equity"
        case longMarketValue = "long_market_value"
        case shortMarketValue = "short_market_value"
        case initialMargin = "initial_margin"
        case maintenanceMargin = "maintenance_margin"
        case lastMaintenanceMargin = "last_maintenance_margin"
        case daytradeCount = "daytrade_count"
    }
    
    // MARK: - Computed Properties
    
    /// Formatted buying power display
    var formattedBuyingPower: String {
        guard let value = Double(buyingPower) else { return buyingPower }
        return value.asCurrency()
    }
    
    /// Formatted cash balance display
    var formattedCash: String {
        guard let value = Double(cash) else { return cash }
        return value.asCurrency()
    }
    
    /// Formatted portfolio value display
    var formattedPortfolioValue: String {
        guard let value = Double(portfolioValue) else { return portfolioValue }
        return value.asCurrency()
    }
    
    /// Formatted equity display
    var formattedEquity: String {
        guard let value = Double(equity) else { return equity }
        return value.asCurrency()
    }
    
    /// Formatted long market value display
    var formattedLongMarketValue: String {
        guard let value = Double(longMarketValue) else { return longMarketValue }
        return value.asCurrency()
    }
    
    /// Formatted short market value display
    var formattedShortMarketValue: String {
        guard let value = Double(shortMarketValue) else { return shortMarketValue }
        return value.asCurrency()
    }
    
    /// Formatted initial margin display
    var formattedInitialMargin: String {
        guard let value = Double(initialMargin) else { return initialMargin }
        return value.asCurrency()
    }
    
    /// Formatted maintenance margin display
    var formattedMaintenanceMargin: String {
        guard let value = Double(maintenanceMargin) else { return maintenanceMargin }
        return value.asCurrency()
    }
    
    /// Formatted SMA (Special Memorandum Account) display
    var formattedSMA: String {
        guard let value = Double(sma) else { return sma }
        return value.asCurrency()
    }
    
    /// Daily P&L calculation
    var dailyPL: Double? {
        guard let currentEquity = Double(equity),
              let previousEquity = Double(lastEquity) else { return nil }
        return currentEquity - previousEquity
    }
    
    /// Formatted daily P&L display
    var formattedDailyPL: String {
        guard let dailyPL = dailyPL else { return "--" }
        let sign = dailyPL >= 0 ? "+" : ""
        return "\(sign)\(dailyPL.asCurrency())"
    }
    
    /// Daily P&L percentage
    var dailyPLPercentage: Double? {
        guard let dailyPL = dailyPL,
              let previousEquity = Double(lastEquity),
              previousEquity > 0 else { return nil }
        return dailyPL / previousEquity
    }
    
    /// Formatted daily P&L percentage display
    var formattedDailyPLPercentage: String {
        guard let percentage = dailyPLPercentage else { return "--" }
        let sign = percentage >= 0 ? "+" : ""
        return "\(sign)\(percentage.asPercentage(decimals: 2))"
    }
    
    /// Color for daily P&L display
    var dailyPLColor: AccountPLColor {
        guard let dailyPL = dailyPL else { return .neutral }
        return dailyPL >= 0 ? .positive : .negative
    }
    
    /// Account health status
    var healthStatus: AccountHealthStatus {
        if accountBlocked || tradingBlocked || transfersBlocked {
            return .restricted
        }
        
        if patternDayTrader && daytradeCount >= 3 {
            return .warning
        }
        
        // Check margin health
        if let maintenanceMarginValue = Double(maintenanceMargin),
           let equityValue = Double(equity),
           maintenanceMarginValue > 0 {
            let marginRatio = maintenanceMarginValue / equityValue
            if marginRatio > 0.8 {
                return .warning
            }
        }
        
        return .healthy
    }
    
    /// Buying power utilization percentage
    var buyingPowerUtilization: Double? {
        guard let buyingPowerValue = Double(buyingPower),
              let longValue = Double(longMarketValue),
              buyingPowerValue > 0 else { return nil }
        return longValue / buyingPowerValue
    }
    
    /// Formatted buying power utilization
    var formattedBuyingPowerUtilization: String {
        guard let utilization = buyingPowerUtilization else { return "--" }
        return utilization.asPercentage(decimals: 1)
    }
    
    /// Whether the account can trade
    var canTrade: Bool {
        return !tradingBlocked && !accountBlocked && !tradeSuspendedByUser && status.lowercased() == "active"
    }
    
    /// Whether the account has margin enabled
    var hasMargin: Bool {
        guard let multiplierValue = Double(multiplier) else { return false }
        return multiplierValue > 1.0
    }
    
    /// Remaining day trades for PDT accounts
    var remainingDayTrades: Int {
        return patternDayTrader ? max(0, 3 - daytradeCount) : Int.max
    }
    
    /// Formatted account multiplier display
    var formattedMultiplier: String {
        return "\(multiplier):1"
    }
}

// MARK: - Account Colors and Status
enum AccountPLColor {
    case positive
    case negative
    case neutral
}

enum AccountHealthStatus {
    case healthy
    case warning
    case restricted
    
    var displayName: String {
        switch self {
        case .healthy:
            return "Healthy"
        case .warning:
            return "Warning"
        case .restricted:
            return "Restricted"
        }
    }
    
    var color: AccountHealthColor {
        switch self {
        case .healthy:
            return .green
        case .warning:
            return .yellow
        case .restricted:
            return .red
        }
    }
}

enum AccountHealthColor {
    case green
    case yellow
    case red
}

// MARK: - Sample Data
extension Account {
    static let sampleData: Account = Account(
        id: "2a87c088-ffb7-4739-b5d5-5b3b5c9c6e00",
        accountNumber: "123456789",
        status: "ACTIVE",
        currency: "USD",
        buyingPower: "25847.32",
        cash: "12543.18",
        portfolioValue: "45691.23",
        patternDayTrader: false,
        tradingBlocked: false,
        transfersBlocked: false,
        accountBlocked: false,
        tradeSuspendedByUser: false,
        multiplier: "2",
        shortingEnabled: true,
        equity: "45691.23",
        lastEquity: "44834.67",
        longMarketValue: "33148.05",
        shortMarketValue: "0.00",
        initialMargin: "16574.03",
        maintenanceMargin: "9944.41",
        lastMaintenanceMargin: "9722.15",
        sma: "8903.27",
        daytradeCount: 1
    )
}