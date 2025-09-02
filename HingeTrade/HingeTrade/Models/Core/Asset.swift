import Foundation

// MARK: - Asset Class Enum
enum AssetClass: String, CaseIterable, Codable {
    case usEquity = "us_equity"
    case crypto = "crypto"
    
    var displayName: String {
        switch self {
        case .usEquity:
            return "US Equity"
        case .crypto:
            return "Cryptocurrency"
        }
    }
}

// MARK: - Asset Model
struct Asset: Codable, Identifiable, Equatable {
    let id: String
    let assetClass: AssetClass
    let symbol: String
    let name: String
    let exchange: String?
    let status: String
    let tradable: Bool
    let marginable: Bool
    let shortable: Bool
    let easyToBorrow: Bool
    let fractionable: Bool
    
    // Market data (optional, updated from real-time feeds)
    let price: Double?
    let changePercent: Double?
    let volume: Int?
    let marketCap: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, symbol, name, exchange, status, tradable, marginable, shortable, fractionable, price, volume
        case assetClass = "class"
        case easyToBorrow = "easy_to_borrow"
        case changePercent = "change_percent"
        case marketCap = "market_cap"
    }
    
    // MARK: - Computed Properties
    
    /// Formatted price display
    var formattedPrice: String {
        guard let price = price else { return "--" }
        return price.asCurrency()
    }
    
    /// Formatted change percentage
    var formattedChangePercent: String {
        guard let changePercent = changePercent else { return "--" }
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(changePercent.asPercentage(decimals: 2))"
    }
    
    /// Color for price changes (green for positive, red for negative)
    var changeColor: AssetChangeColor {
        guard let changePercent = changePercent else { return .neutral }
        return changePercent >= 0 ? .positive : .negative
    }
    
    /// Formatted volume display
    var formattedVolume: String {
        guard let volume = volume else { return "--" }
        return volume.asAbbreviated()
    }
    
    /// Formatted market cap display
    var formattedMarketCap: String {
        guard let marketCap = marketCap else { return "--" }
        return marketCap.asAbbreviated()
    }
    
    /// Whether this asset can be traded in extended hours
    var supportsExtendedHours: Bool {
        return assetClass == .usEquity && tradable
    }
    
    /// Whether this asset supports fractional shares
    var supportsFractionalShares: Bool {
        return fractionable
    }
}

// MARK: - Asset Change Color
enum AssetChangeColor {
    case positive
    case negative
    case neutral
}

// MARK: - Sample Data
extension Asset {
    static let sampleData: [Asset] = [
        Asset(
            id: "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
            assetClass: .usEquity,
            symbol: "AAPL",
            name: "Apple Inc.",
            exchange: "NASDAQ",
            status: "active",
            tradable: true,
            marginable: true,
            shortable: true,
            easyToBorrow: true,
            fractionable: true,
            price: 188.34,
            changePercent: 2.45,
            volume: 52847392,
            marketCap: 2987654321000
        ),
        Asset(
            id: "64bbff51-59d6-4b3c-9351-13ad85e3c752",
            assetClass: .usEquity,
            symbol: "TSLA",
            name: "Tesla, Inc.",
            exchange: "NASDAQ",
            status: "active",
            tradable: true,
            marginable: true,
            shortable: true,
            easyToBorrow: false,
            fractionable: true,
            price: 183.27,
            changePercent: -1.23,
            volume: 89234567,
            marketCap: 582345678900
        ),
        Asset(
            id: "276e2673-764b-4ab6-a611-caf665ca6340",
            assetClass: .crypto,
            symbol: "BTC",
            name: "Bitcoin",
            exchange: nil,
            status: "active",
            tradable: true,
            marginable: false,
            shortable: false,
            easyToBorrow: false,
            fractionable: true,
            price: 67234.56,
            changePercent: 3.78,
            volume: 1234567,
            marketCap: 1298765432100
        )
    ]
}