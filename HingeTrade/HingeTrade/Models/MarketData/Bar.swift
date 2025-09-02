import Foundation

// MARK: - Bar (OHLC) Model
struct Bar: Codable, Identifiable, Equatable {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
    let numberOfTrades: Int?
    let volumeWeightedAveragePrice: Double?
    
    // Symbol context (not part of API response but needed for identification)
    let symbol: String?
    
    // Computed ID for Identifiable protocol
    var id: String { 
        let symbolPart = symbol ?? "unknown"
        return "\(symbolPart)-\(timestamp.timeIntervalSince1970)"
    }
    
    enum CodingKeys: String, CodingKey {
        case timestamp = "t"
        case open = "o"
        case high = "h"
        case low = "l"
        case close = "c"
        case volume = "v"
        case numberOfTrades = "n"
        case volumeWeightedAveragePrice = "vw"
        case symbol
    }
    
    // MARK: - Computed Properties
    
    /// Formatted open price
    var formattedOpen: String {
        return open.asCurrency()
    }
    
    /// Formatted high price
    var formattedHigh: String {
        return high.asCurrency()
    }
    
    /// Formatted low price
    var formattedLow: String {
        return low.asCurrency()
    }
    
    /// Formatted close price
    var formattedClose: String {
        return close.asCurrency()
    }
    
    /// Formatted volume
    var formattedVolume: String {
        return volume.asAbbreviated()
    }
    
    /// Formatted VWAP
    var formattedVWAP: String {
        guard let vwap = volumeWeightedAveragePrice else { return "--" }
        return vwap.asCurrency()
    }
    
    /// Price change (close - open)
    var change: Double {
        return close - open
    }
    
    /// Formatted price change
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(change.asCurrency())"
    }
    
    /// Price change percentage
    var changePercent: Double {
        guard open > 0 else { return 0 }
        return change / open
    }
    
    /// Formatted price change percentage
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(changePercent.asPercentage(decimals: 2))"
    }
    
    /// Color for price change display
    var changeColor: BarChangeColor {
        if change > 0 { return .positive }
        if change < 0 { return .negative }
        return .neutral
    }
    
    /// Price range (high - low)
    var range: Double {
        return high - low
    }
    
    /// Formatted price range
    var formattedRange: String {
        return range.asCurrency()
    }
    
    /// Range as percentage of open price
    var rangePercent: Double {
        guard open > 0 else { return 0 }
        return range / open
    }
    
    /// Formatted range percentage
    var formattedRangePercent: String {
        return rangePercent.asPercentage(decimals: 2)
    }
    
    /// Whether this is a green (bullish) candle
    var isBullish: Bool {
        return close > open
    }
    
    /// Whether this is a red (bearish) candle
    var isBearish: Bool {
        return close < open
    }
    
    /// Whether this is a doji (open ~= close)
    var isDoji: Bool {
        let tolerance = range * 0.05 // 5% of range
        return abs(close - open) <= tolerance
    }
    
    /// Candle body size (absolute difference between open and close)
    var bodySize: Double {
        return abs(close - open)
    }
    
    /// Upper shadow/wick size
    var upperShadow: Double {
        return high - max(open, close)
    }
    
    /// Lower shadow/wick size
    var lowerShadow: Double {
        return min(open, close) - low
    }
    
    /// Body as percentage of total range
    var bodyToRangeRatio: Double {
        guard range > 0 else { return 0 }
        return bodySize / range
    }
    
    /// Whether this is a hammer pattern (small body, long lower shadow)
    var isHammer: Bool {
        guard range > 0 else { return false }
        let bodyRatio = bodyToRangeRatio
        let lowerShadowRatio = lowerShadow / range
        return bodyRatio < 0.3 && lowerShadowRatio > 0.6
    }
    
    /// Whether this is a shooting star pattern (small body, long upper shadow)
    var isShootingStar: Bool {
        guard range > 0 else { return false }
        let bodyRatio = bodyToRangeRatio
        let upperShadowRatio = upperShadow / range
        return bodyRatio < 0.3 && upperShadowRatio > 0.6
    }
    
    /// Whether this is a spinning top (small body, long shadows on both sides)
    var isSpinningTop: Bool {
        guard range > 0 else { return false }
        let bodyRatio = bodyToRangeRatio
        let upperRatio = upperShadow / range
        let lowerRatio = lowerShadow / range
        return bodyRatio < 0.3 && upperRatio > 0.3 && lowerRatio > 0.3
    }
    
    /// Candle pattern type
    var patternType: CandlePattern {
        if isDoji { return .doji }
        if isHammer { return .hammer }
        if isShootingStar { return .shootingStar }
        if isSpinningTop { return .spinningTop }
        if isBullish { return .bullish }
        if isBearish { return .bearish }
        return .neutral
    }
    
    /// Volume intensity compared to a reference volume
    func volumeIntensity(referenceVolume: Int) -> VolumeIntensity {
        guard referenceVolume > 0 else { return .normal }
        let ratio = Double(volume) / Double(referenceVolume)
        
        switch ratio {
        case 0..<0.5:
            return .low
        case 0.5..<0.8:
            return .belowAverage
        case 0.8..<1.2:
            return .normal
        case 1.2..<2.0:
            return .aboveAverage
        case 2.0..<3.0:
            return .high
        default:
            return .extreme
        }
    }
    
    /// Formatted timestamp for display
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Formatted trades count
    var formattedTrades: String {
        guard let trades = numberOfTrades else { return "--" }
        return trades.asFormatted()
    }
    
    /// Average trade size
    var averageTradeSize: Double? {
        guard let trades = numberOfTrades, trades > 0 else { return nil }
        return Double(volume) / Double(trades)
    }
    
    /// Formatted average trade size
    var formattedAverageTradeSize: String {
        guard let avgSize = averageTradeSize else { return "--" }
        return avgSize.asFormatted(decimals: 0)
    }
}

// MARK: - Candle Pattern Types
enum CandlePattern: String, CaseIterable {
    case bullish = "Bullish"
    case bearish = "Bearish"
    case doji = "Doji"
    case hammer = "Hammer"
    case shootingStar = "Shooting Star"
    case spinningTop = "Spinning Top"
    case neutral = "Neutral"
    
    var color: CandlePatternColor {
        switch self {
        case .bullish, .hammer:
            return .green
        case .bearish, .shootingStar:
            return .red
        case .doji, .spinningTop:
            return .orange
        case .neutral:
            return .gray
        }
    }
    
    var significance: PatternSignificance {
        switch self {
        case .hammer, .shootingStar:
            return .high
        case .doji, .spinningTop:
            return .medium
        case .bullish, .bearish:
            return .low
        case .neutral:
            return .none
        }
    }
}

enum CandlePatternColor {
    case green
    case red
    case orange
    case gray
}

enum PatternSignificance {
    case none
    case low
    case medium
    case high
}

// MARK: - Volume Intensity
enum VolumeIntensity: String, CaseIterable {
    case low = "Low"
    case belowAverage = "Below Average"
    case normal = "Normal"
    case aboveAverage = "Above Average"
    case high = "High"
    case extreme = "Extreme"
    
    var color: VolumeIntensityColor {
        switch self {
        case .low:
            return .gray
        case .belowAverage:
            return .lightBlue
        case .normal:
            return .blue
        case .aboveAverage:
            return .orange
        case .high:
            return .red
        case .extreme:
            return .purple
        }
    }
}

enum VolumeIntensityColor {
    case gray
    case lightBlue
    case blue
    case orange
    case red
    case purple
}

// MARK: - Bar Change Color
enum BarChangeColor {
    case positive
    case negative
    case neutral
}

// MARK: - Sample Data
extension Bar {
    static let sampleData: [Bar] = [
        Bar(
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            open: 186.50,
            high: 188.75,
            low: 186.25,
            close: 188.34,
            volume: 2847392,
            numberOfTrades: 15628,
            volumeWeightedAveragePrice: 187.92,
            symbol: "AAPL"
        ),
        Bar(
            timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
            open: 185.20,
            high: 187.10,
            low: 184.95,
            close: 186.50,
            volume: 3124567,
            numberOfTrades: 18732,
            volumeWeightedAveragePrice: 186.15,
            symbol: "AAPL"
        ),
        Bar(
            timestamp: Date().addingTimeInterval(-10800), // 3 hours ago
            open: 184.75,
            high: 185.50,
            low: 183.80,
            close: 185.20,
            volume: 1856743,
            numberOfTrades: 11249,
            volumeWeightedAveragePrice: 184.95,
            symbol: "AAPL"
        ),
        Bar(
            timestamp: Date().addingTimeInterval(-14400), // 4 hours ago
            open: 183.90,
            high: 185.25,
            low: 183.65,
            close: 184.75,
            volume: 2193456,
            numberOfTrades: 13567,
            volumeWeightedAveragePrice: 184.50,
            symbol: "AAPL"
        )
    ]
    
    /// Generate sample intraday data for testing
    static func generateSampleIntradayData(symbol: String, count: Int = 100) -> [Bar] {
        var bars: [Bar] = []
        var currentPrice = 100.0
        var currentTime = Date().addingTimeInterval(-TimeInterval(count * 60)) // Start count minutes ago
        
        for _ in 0..<count {
            let change = Double.random(in: -2.0...2.0)
            let open = currentPrice
            let close = open + change
            let high = max(open, close) + Double.random(in: 0...1.0)
            let low = min(open, close) - Double.random(in: 0...1.0)
            let volume = Int.random(in: 50000...500000)
            
            let bar = Bar(
                timestamp: currentTime,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume,
                numberOfTrades: Int.random(in: 100...1000),
                volumeWeightedAveragePrice: (high + low + close) / 3.0,
                symbol: symbol
            )
            
            bars.append(bar)
            currentPrice = close
            currentTime = currentTime.addingTimeInterval(60) // Next minute
        }
        
        return bars
    }
}