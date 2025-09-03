import Foundation

// MARK: - Position Side Enum
enum PositionSide: String, CaseIterable, Codable {
    case long = "long"
    case short = "short"
    
    var displayName: String {
        switch self {
        case .long:
            return "Long"
        case .short:
            return "Short"
        }
    }
    
    var color: PositionSideColor {
        switch self {
        case .long:
            return .long
        case .short:
            return .short
        }
    }
}

// MARK: - Position Model
struct Position: Codable, Identifiable, Equatable {
    let assetId: String
    let symbol: String
    let exchange: String
    let assetClass: AssetClass
    let avgEntryPrice: String
    let qty: String
    let side: PositionSide
    let marketValue: String
    let costBasis: String
    let unrealizedPl: String?
    let unrealizedPlpc: String?
    let unrealizedIntradayPl: String?
    let unrealizedIntradayPlpc: String?
    let currentPrice: String?
    let lastdayPrice: String?
    let changeToday: String?
    
    // Computed ID for Identifiable protocol
    var id: String { "\(assetId)-\(side.rawValue)" }
    
    enum CodingKeys: String, CodingKey {
        case symbol, exchange, qty, side
        case assetId = "asset_id"
        case assetClass = "asset_class"
        case avgEntryPrice = "avg_entry_price"
        case marketValue = "market_value"
        case costBasis = "cost_basis"
        case unrealizedPl = "unrealized_pl"
        case unrealizedPlpc = "unrealized_plpc"
        case unrealizedIntradayPl = "unrealized_intraday_pl"
        case unrealizedIntradayPlpc = "unrealized_intraday_plpc"
        case currentPrice = "current_price"
        case lastdayPrice = "lastday_price"
        case changeToday = "change_today"
    }
    
    // MARK: - Computed Properties
    
    /// Formatted quantity display
    var formattedQty: String {
        guard let qtyValue = Double(qty) else { return qty }
        return qtyValue.asFormatted(decimals: qtyValue.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 3)
    }
    
    /// Formatted average entry price
    var formattedAvgEntryPrice: String {
        guard let priceValue = Double(avgEntryPrice) else { return avgEntryPrice }
        return priceValue.asCurrency()
    }
    
    /// Formatted current price
    var formattedCurrentPrice: String {
        guard let currentPrice = currentPrice, let priceValue = Double(currentPrice) else { return "--" }
        return priceValue.asCurrency()
    }
    
    /// Formatted market value
    var formattedMarketValue: String {
        guard let valueAmount = Double(marketValue) else { return marketValue }
        return valueAmount.asCurrency()
    }
    
    /// Formatted cost basis
    var formattedCostBasis: String {
        guard let basisAmount = Double(costBasis) else { return costBasis }
        return basisAmount.asCurrency()
    }
    
    /// Formatted unrealized P&L
    var formattedUnrealizedPl: String {
        guard let unrealizedPl = unrealizedPl, let plValue = Double(unrealizedPl) else { return "--" }
        let sign = plValue >= 0 ? "+" : ""
        return "\(sign)\(plValue.asCurrency())"
    }
    
    /// Formatted unrealized P&L percentage
    var formattedUnrealizedPlpc: String {
        guard let unrealizedPlpc = unrealizedPlpc, let plpcValue = Double(unrealizedPlpc) else { return "--" }
        let sign = plpcValue >= 0 ? "+" : ""
        return "\(sign)\(plpcValue.asPercentage(decimals: 2))"
    }
    
    /// Formatted intraday P&L
    var formattedIntradayPl: String {
        guard let unrealizedIntradayPl = unrealizedIntradayPl, let plValue = Double(unrealizedIntradayPl) else { return "--" }
        let sign = plValue >= 0 ? "+" : ""
        return "\(sign)\(plValue.asCurrency())"
    }
    
    /// Formatted intraday P&L percentage
    var formattedIntradayPlpc: String {
        guard let unrealizedIntradayPlpc = unrealizedIntradayPlpc, let plpcValue = Double(unrealizedIntradayPlpc) else { return "--" }
        let sign = plpcValue >= 0 ? "+" : ""
        return "\(sign)\(plpcValue.asPercentage(decimals: 2))"
    }
    
    /// Formatted today's change
    var formattedChangeToday: String {
        guard let changeToday = changeToday, let changeValue = Double(changeToday) else { return "--" }
        let sign = changeValue >= 0 ? "+" : ""
        return "\(sign)\(changeValue.asCurrency())"
    }
    
    /// Color for unrealized P&L display
    var unrealizedPlColor: PositionPLColor {
        guard let unrealizedPl = unrealizedPl, let plValue = Double(unrealizedPl) else { return .neutral }
        return plValue >= 0 ? .positive : .negative
    }
    
    /// Color for intraday P&L display
    var intradayPlColor: PositionPLColor {
        guard let unrealizedIntradayPl = unrealizedIntradayPl, let plValue = Double(unrealizedIntradayPl) else { return .neutral }
        return plValue >= 0 ? .positive : .negative
    }
    
    /// Color for today's change display
    var changeTodayColor: PositionPLColor {
        guard let changeToday = changeToday, let changeValue = Double(changeToday) else { return .neutral }
        return changeValue >= 0 ? .positive : .negative
    }
    
    /// Whether this position is profitable
    var isProfitable: Bool {
        guard let unrealizedPl = unrealizedPl, let plValue = Double(unrealizedPl) else { return false }
        return plValue > 0
    }
    
    /// Whether this position is at a loss
    var isAtLoss: Bool {
        guard let unrealizedPl = unrealizedPl, let plValue = Double(unrealizedPl) else { return false }
        return plValue < 0
    }
    
    /// Weight of this position in portfolio (requires total portfolio value to calculate)
    func weightInPortfolio(totalPortfolioValue: Double) -> Double {
        guard let marketValueDouble = Double(marketValue), totalPortfolioValue > 0 else { return 0 }
        return abs(marketValueDouble) / totalPortfolioValue
    }
    
    /// Formatted weight in portfolio
    func formattedWeightInPortfolio(totalPortfolioValue: Double) -> String {
        let weight = weightInPortfolio(totalPortfolioValue: totalPortfolioValue)
        return weight.asPercentage(decimals: 1)
    }
    
    /// Risk level based on position size relative to portfolio
    func riskLevel(totalPortfolioValue: Double) -> PositionRiskLevel {
        let weight = weightInPortfolio(totalPortfolioValue: totalPortfolioValue)
        switch weight {
        case 0..<0.05:
            return .low
        case 0.05..<0.15:
            return .medium
        case 0.15..<0.25:
            return .high
        default:
            return .veryHigh
        }
    }
}

// MARK: - Position Colors and Risk Levels
enum PositionSideColor {
    case long
    case short
}

enum PositionPLColor {
    case positive
    case negative
    case neutral
}

enum PositionRiskLevel {
    case low
    case medium
    case high
    case veryHigh
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .veryHigh:
            return "Very High"
        }
    }
}

// MARK: - Sample Data
extension Position {
    static let sampleData: [Position] = [
        Position(
            assetId: "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
            symbol: "AAPL",
            exchange: "NASDAQ",
            assetClass: .usEquity,
            avgEntryPrice: "185.50",
            qty: "100",
            side: .long,
            marketValue: "18834.00",
            costBasis: "18550.00",
            unrealizedPl: "284.00",
            unrealizedPlpc: "0.0153",
            unrealizedIntradayPl: "123.00",
            unrealizedIntradayPlpc: "0.0065",
            currentPrice: "188.34",
            lastdayPrice: "187.11",
            changeToday: "123.00"
        ),
        Position(
            assetId: "64bbff51-59d6-4b3c-9351-13ad85e3c752",
            symbol: "TSLA",
            exchange: "NASDAQ",
            assetClass: .usEquity,
            avgEntryPrice: "185.75",
            qty: "25",
            side: .long,
            marketValue: "4581.75",
            costBasis: "4643.75",
            unrealizedPl: "-62.00",
            unrealizedPlpc: "-0.0134",
            unrealizedIntradayPl: "-31.25",
            unrealizedIntradayPlpc: "-0.0068",
            currentPrice: "183.27",
            lastdayPrice: "184.52",
            changeToday: "-31.25"
        ),
        Position(
            assetId: "276e2673-764b-4ab6-a611-caf665ca6340",
            symbol: "BTC",
            exchange: "NASDAQ",
            assetClass: .crypto,
            avgEntryPrice: "65432.10",
            qty: "0.1534",
            side: .long,
            marketValue: "10314.21",
            costBasis: "10037.28",
            unrealizedPl: "276.93",
            unrealizedPlpc: "0.0276",
            unrealizedIntradayPl: "412.45",
            unrealizedIntradayPlpc: "0.0417",
            currentPrice: "67234.56",
            lastdayPrice: "64545.89",
            changeToday: "412.45"
        )
    ]
}