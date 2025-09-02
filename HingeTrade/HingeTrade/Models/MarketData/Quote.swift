import Foundation

// MARK: - Quote Model
struct Quote: Codable, Identifiable, Equatable {
    let symbol: String
    let timestamp: Date
    let askPrice: Double
    let askSize: Int
    let bidPrice: Double
    let bidSize: Int
    let lastPrice: Double
    let lastSize: Int
    
    // Additional market data (optional)
    let dailyChange: Double?
    let dailyChangePercent: Double?
    let dailyHigh: Double?
    let dailyLow: Double?
    let dailyOpen: Double?
    let previousClose: Double?
    let volume: Int?
    let averageVolume: Int?
    
    // Computed ID for Identifiable protocol
    var id: String { symbol }
    
    enum CodingKeys: String, CodingKey {
        case symbol, timestamp, lastPrice, lastSize, volume
        case askPrice = "ask_price"
        case askSize = "ask_size"  
        case bidPrice = "bid_price"
        case bidSize = "bid_size"
        case dailyChange = "daily_change"
        case dailyChangePercent = "daily_change_percent"
        case dailyHigh = "daily_high"
        case dailyLow = "daily_low"
        case dailyOpen = "daily_open"
        case previousClose = "previous_close"
        case averageVolume = "average_volume"
    }
    
    // MARK: - Computed Properties
    
    /// Formatted ask price display
    var formattedAskPrice: String {
        return askPrice.asCurrency()
    }
    
    /// Formatted bid price display
    var formattedBidPrice: String {
        return bidPrice.asCurrency()
    }
    
    /// Formatted last price display
    var formattedLastPrice: String {
        return lastPrice.asCurrency()
    }
    
    /// Formatted bid-ask spread
    var formattedSpread: String {
        let spread = askPrice - bidPrice
        return spread.asCurrency()
    }
    
    /// Bid-ask spread as percentage of last price
    var spreadPercentage: Double {
        guard lastPrice > 0 else { return 0 }
        return (askPrice - bidPrice) / lastPrice
    }
    
    /// Formatted spread percentage
    var formattedSpreadPercentage: String {
        return spreadPercentage.asPercentage(decimals: 3)
    }
    
    /// Mid price (average of bid and ask)
    var midPrice: Double {
        return (askPrice + bidPrice) / 2.0
    }
    
    /// Formatted mid price
    var formattedMidPrice: String {
        return midPrice.asCurrency()
    }
    
    /// Formatted daily change
    var formattedDailyChange: String {
        guard let change = dailyChange else { return "--" }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(change.asCurrency())"
    }
    
    /// Formatted daily change percentage
    var formattedDailyChangePercent: String {
        guard let changePercent = dailyChangePercent else { return "--" }
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(changePercent.asPercentage(decimals: 2))"
    }
    
    /// Color for daily change display
    var dailyChangeColor: QuoteChangeColor {
        guard let change = dailyChange else { return .neutral }
        return change >= 0 ? .positive : .negative
    }
    
    /// Formatted daily high
    var formattedDailyHigh: String {
        guard let high = dailyHigh else { return "--" }
        return high.asCurrency()
    }
    
    /// Formatted daily low
    var formattedDailyLow: String {
        guard let low = dailyLow else { return "--" }
        return low.asCurrency()
    }
    
    /// Formatted daily open
    var formattedDailyOpen: String {
        guard let open = dailyOpen else { return "--" }
        return open.asCurrency()
    }
    
    /// Formatted previous close
    var formattedPreviousClose: String {
        guard let close = previousClose else { return "--" }
        return close.asCurrency()
    }
    
    /// Formatted volume
    var formattedVolume: String {
        guard let vol = volume else { return "--" }
        return vol.asAbbreviated()
    }
    
    /// Volume relative to average (as percentage)
    var relativeVolume: Double? {
        guard let volume = volume, let avgVolume = averageVolume, avgVolume > 0 else { return nil }
        return Double(volume) / Double(avgVolume)
    }
    
    /// Formatted relative volume
    var formattedRelativeVolume: String {
        guard let relVol = relativeVolume else { return "--" }
        return "\(relVol.asFormatted(decimals: 2))x"
    }
    
    /// Time since last update
    var timeSinceUpdate: String {
        return timestamp.timeAgoDisplay
    }
    
    /// Whether the quote is stale (older than 15 seconds for equities, 1 minute for crypto)
    var isStale: Bool {
        let maxAge: TimeInterval = symbol.contains("BTC") || symbol.contains("ETH") ? 60 : 15
        return Date().timeIntervalSince(timestamp) > maxAge
    }
    
    /// Market session status based on timestamp
    var sessionStatus: MarketSession {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)
        let minute = calendar.component(.minute, from: timestamp)
        let timeInMinutes = hour * 60 + minute
        
        // Market hours: 9:30 AM - 4:00 PM ET (570 - 960 minutes)
        // Pre-market: 4:00 AM - 9:30 AM ET (240 - 570 minutes)  
        // After-hours: 4:00 PM - 8:00 PM ET (960 - 1200 minutes)
        
        switch timeInMinutes {
        case 240..<570:
            return .premarket
        case 570..<960:
            return .regular
        case 960..<1200:
            return .afterhours
        default:
            return .closed
        }
    }
    
    /// Liquidity assessment based on bid/ask size
    var liquidityLevel: LiquidityLevel {
        let totalSize = bidSize + askSize
        switch totalSize {
        case 0..<100:
            return .low
        case 100..<500:
            return .medium
        case 500..<1000:
            return .high
        default:
            return .veryHigh
        }
    }
}

// MARK: - Quote Change Color
enum QuoteChangeColor {
    case positive
    case negative  
    case neutral
}

// MARK: - Market Session
enum MarketSession: String, CaseIterable {
    case premarket = "Pre-Market"
    case regular = "Regular Hours"
    case afterhours = "After Hours"
    case closed = "Closed"
    
    var displayName: String {
        return rawValue
    }
    
    var color: MarketSessionColor {
        switch self {
        case .regular:
            return .green
        case .premarket, .afterhours:
            return .orange
        case .closed:
            return .red
        }
    }
}

enum MarketSessionColor {
    case green
    case orange
    case red
}

// MARK: - Liquidity Level
enum LiquidityLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
    
    var color: LiquidityColor {
        switch self {
        case .low:
            return .red
        case .medium:
            return .orange
        case .high:
            return .yellow
        case .veryHigh:
            return .green
        }
    }
}

enum LiquidityColor {
    case red
    case orange
    case yellow
    case green
}

// MARK: - Sample Data
extension Quote {
    static let sampleData: [Quote] = [
        Quote(
            symbol: "AAPL",
            timestamp: Date(),
            askPrice: 188.36,
            askSize: 100,
            bidPrice: 188.34,
            bidSize: 200,
            lastPrice: 188.35,
            lastSize: 150,
            dailyChange: 2.45,
            dailyChangePercent: 0.0132,
            dailyHigh: 189.12,
            dailyLow: 185.67,
            dailyOpen: 186.23,
            previousClose: 185.90,
            volume: 52847392,
            averageVolume: 48923456
        ),
        Quote(
            symbol: "TSLA",
            timestamp: Date().addingTimeInterval(-5),
            askPrice: 183.29,
            askSize: 150,
            bidPrice: 183.25,
            bidSize: 300,
            lastPrice: 183.27,
            lastSize: 200,
            dailyChange: -2.25,
            dailyChangePercent: -0.0121,
            dailyHigh: 186.45,
            dailyLow: 182.89,
            dailyOpen: 185.52,
            previousClose: 185.52,
            volume: 89234567,
            averageVolume: 72145698
        ),
        Quote(
            symbol: "BTC",
            timestamp: Date().addingTimeInterval(-30),
            askPrice: 67236.78,
            askSize: 1,
            bidPrice: 67232.34,
            bidSize: 2,
            lastPrice: 67234.56,
            lastSize: 1,
            dailyChange: 2540.12,
            dailyChangePercent: 0.0392,
            dailyHigh: 68123.45,
            dailyLow: 64567.89,
            dailyOpen: 64694.44,
            previousClose: 64694.44,
            volume: 1234567,
            averageVolume: 987654
        )
    ]
}