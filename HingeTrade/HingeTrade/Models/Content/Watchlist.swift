import Foundation

// MARK: - Watchlist Model
struct Watchlist: Codable, Identifiable, Equatable {
    let id: String
    let accountId: String
    var name: String
    var items: [String] // Array of symbols
    let createdAt: Date
    var updatedAt: Date
    
    // Optional metadata
    var description: String?
    let isDefault: Bool?
    var sortOrder: Int?
    var color: String? // Hex color code for UI theming
    var isPublic: Bool? // For sharing watchlists
    
    // Social and performance features
    var isFavorite: Bool
    var dailyPerformance: Double?
    var gainers: Int
    var losers: Int
    var lastUpdated: Date?
    
    // Computed property for symbols (compatibility)
    var symbols: [String] {
        get { items }
        set { items = newValue }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, items, description, color
        case accountId = "account_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isDefault = "is_default"
        case sortOrder = "sort_order"
        case isPublic = "is_public"
        case isFavorite = "is_favorite"
        case dailyPerformance = "daily_performance"
        case gainers, losers
        case lastUpdated = "last_updated"
    }
    
    // MARK: - Computed Properties
    
    /// Number of symbols in the watchlist
    var symbolCount: Int {
        return items.count
    }
    
    /// Formatted symbol count
    var formattedSymbolCount: String {
        return "\(symbolCount) symbol\(symbolCount == 1 ? "" : "s")"
    }
    
    /// Whether the watchlist is empty
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    /// Whether the watchlist has reached maximum capacity (if there's a limit)
    var isFull: Bool {
        return items.count >= maxSymbolLimit
    }
    
    /// Maximum symbol limit (configurable)
    var maxSymbolLimit: Int {
        return 100 // Default limit, could be configurable per account type
    }
    
    /// Remaining slots available
    var remainingSlots: Int {
        return max(0, maxSymbolLimit - items.count)
    }
    
    /// Age of the watchlist
    var age: TimeInterval {
        return Date().timeIntervalSince(createdAt)
    }
    
    /// Formatted age
    var formattedAge: String {
        return createdAt.timeAgoDisplay
    }
    
    /// Last modified time
    var formattedLastModified: String {
        return updatedAt.timeAgoDisplay
    }
    
    /// Whether this is the default watchlist
    var isDefaultWatchlist: Bool {
        return isDefault == true
    }
    
    /// Display color (default to blue if not specified)
    var displayColor: WatchlistColor {
        guard let color = color else { return .blue }
        return WatchlistColor(hexString: color) ?? .blue
    }
    
    /// Whether the watchlist can be deleted (default lists typically cannot be)
    var canDelete: Bool {
        return !isDefaultWatchlist
    }
    
    /// Whether the watchlist can be edited
    var canEdit: Bool {
        return true // Most watchlists can be edited
    }
    
    /// Contains a specific symbol
    func containsSymbol(_ symbol: String) -> Bool {
        return items.contains(symbol.uppercased())
    }
    
    /// Add symbol to watchlist (returns new watchlist)
    func addingSymbol(_ symbol: String) -> Watchlist {
        let upperSymbol = symbol.uppercased()
        guard !containsSymbol(upperSymbol) && !isFull else { return self }
        
        var newItems = items
        newItems.append(upperSymbol)
        
        return Watchlist(
            id: id,
            accountId: accountId,
            name: name,
            items: newItems,
            createdAt: createdAt,
            updatedAt: Date(),
            description: description,
            isDefault: isDefault,
            sortOrder: sortOrder,
            color: color,
            isPublic: isPublic,
            isFavorite: isFavorite,
            dailyPerformance: dailyPerformance,
            gainers: gainers,
            losers: losers,
            lastUpdated: lastUpdated
        )
    }
    
    /// Remove symbol from watchlist (returns new watchlist)
    func removingSymbol(_ symbol: String) -> Watchlist {
        let upperSymbol = symbol.uppercased()
        guard containsSymbol(upperSymbol) else { return self }
        
        let newItems = items.filter { $0 != upperSymbol }
        
        return Watchlist(
            id: id,
            accountId: accountId,
            name: name,
            items: newItems,
            createdAt: createdAt,
            updatedAt: Date(),
            description: description,
            isDefault: isDefault,
            sortOrder: sortOrder,
            color: color,
            isPublic: isPublic,
            isFavorite: isFavorite,
            dailyPerformance: dailyPerformance,
            gainers: gainers,
            losers: losers,
            lastUpdated: lastUpdated
        )
    }
    
    /// Reorder symbols in watchlist
    func reorderingSymbols(_ newOrder: [String]) -> Watchlist {
        // Validate that all symbols in newOrder exist in current items
        let upperNewOrder = newOrder.map { $0.uppercased() }
        let validOrder = upperNewOrder.filter { items.contains($0) }
        
        return Watchlist(
            id: id,
            accountId: accountId,
            name: name,
            items: validOrder,
            createdAt: createdAt,
            updatedAt: Date(),
            description: description,
            isDefault: isDefault,
            sortOrder: sortOrder,
            color: color,
            isPublic: isPublic,
            isFavorite: isFavorite,
            dailyPerformance: dailyPerformance,
            gainers: gainers,
            losers: losers,
            lastUpdated: lastUpdated
        )
    }
    
    /// Update watchlist metadata
    func updating(name: String? = nil, description: String? = nil, color: String? = nil) -> Watchlist {
        return Watchlist(
            id: id,
            accountId: accountId,
            name: name ?? self.name,
            items: items,
            createdAt: createdAt,
            updatedAt: Date(),
            description: description ?? self.description,
            isDefault: isDefault,
            sortOrder: sortOrder,
            color: color ?? self.color,
            isPublic: isPublic,
            isFavorite: isFavorite,
            dailyPerformance: dailyPerformance,
            gainers: gainers,
            losers: losers,
            lastUpdated: lastUpdated
        )
    }
    
    /// Get symbols grouped by asset class (requires asset data)
    func symbolsByAssetClass(_ assets: [Asset]) -> [AssetClass: [String]] {
        let assetDict = Dictionary(uniqueKeysWithValues: assets.map { ($0.symbol, $0) })
        var grouped: [AssetClass: [String]] = [:]
        
        for symbol in items {
            if let asset = assetDict[symbol] {
                if grouped[asset.assetClass] == nil {
                    grouped[asset.assetClass] = []
                }
                grouped[asset.assetClass]?.append(symbol)
            }
        }
        
        return grouped
    }
    
    /// Performance summary (requires market data)
    func performanceSummary(quotes: [String: Quote]) -> WatchlistPerformance {
        var totalChange: Double = 0
        var positiveCount = 0
        var negativeCount = 0
        var neutralCount = 0
        var validQuotes = 0
        
        for symbol in items {
            if let quote = quotes[symbol], let changePercent = quote.dailyChangePercent {
                totalChange += changePercent
                validQuotes += 1
                
                if changePercent > 0 {
                    positiveCount += 1
                } else if changePercent < 0 {
                    negativeCount += 1
                } else {
                    neutralCount += 1
                }
            }
        }
        
        let averageChange = validQuotes > 0 ? totalChange / Double(validQuotes) : 0
        
        return WatchlistPerformance(
            totalSymbols: items.count,
            validQuotes: validQuotes,
            averageChangePercent: averageChange,
            positiveCount: positiveCount,
            negativeCount: negativeCount,
            neutralCount: neutralCount
        )
    }
}

// MARK: - Watchlist Performance
struct WatchlistPerformance {
    let totalSymbols: Int
    let validQuotes: Int
    let averageChangePercent: Double
    let positiveCount: Int
    let negativeCount: Int
    let neutralCount: Int
    
    var formattedAverageChange: String {
        let sign = averageChangePercent >= 0 ? "+" : ""
        return "\(sign)\(averageChangePercent.asPercentage(decimals: 2))"
    }
    
    var performanceColor: WatchlistPerformanceColor {
        if averageChangePercent > 0 { return .positive }
        if averageChangePercent < 0 { return .negative }
        return .neutral
    }
    
    var winRate: Double {
        guard totalSymbols > 0 else { return 0 }
        return Double(positiveCount) / Double(totalSymbols)
    }
    
    var formattedWinRate: String {
        return winRate.asPercentage(decimals: 1)
    }
}

// MARK: - Watchlist Color
enum WatchlistColor: String, CaseIterable {
    case blue = "#007AFF"
    case green = "#34C759"
    case orange = "#FF9500"
    case red = "#FF3B30"
    case purple = "#AF52DE"
    case pink = "#FF2D92"
    case teal = "#5AC8FA"
    case yellow = "#FFCC00"
    
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .red: return "Red"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .teal: return "Teal"
        case .yellow: return "Yellow"
        }
    }
    
    var hexString: String {
        return rawValue
    }
    
    init?(hexString: String) {
        self.init(rawValue: hexString)
    }
}

enum WatchlistPerformanceColor {
    case positive
    case negative
    case neutral
}

// MARK: - Watchlist Category
enum WatchlistCategory: String, CaseIterable {
    case stocks = "Stocks"
    case crypto = "Crypto"
    case etfs = "ETFs"
    case options = "Options"
    case mixed = "Mixed"
    case custom = "Custom"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Sample Data
extension Watchlist {
    static let sampleWatchlists: [Watchlist] = [
        Watchlist(
            id: "watchlist-tech-giants",
            accountId: "account-001",
            name: "Tech Giants",
            items: ["AAPL", "GOOGL", "MSFT", "AMZN", "META", "NVDA"],
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date().addingTimeInterval(-3600),
            description: "Large cap technology leaders",
            isDefault: true,
            sortOrder: 1,
            color: WatchlistColor.blue.hexString,
            isPublic: false,
            isFavorite: true,
            dailyPerformance: 0.024,
            gainers: 4,
            losers: 2,
            lastUpdated: Date()
        ),
        Watchlist(
            id: "watchlist-ev-stocks",
            accountId: "account-001",
            name: "Electric Vehicles",
            items: ["TSLA", "NIO", "XPEV", "LI", "RIVN", "LCID"],
            createdAt: Date().addingTimeInterval(-86400 * 14),
            updatedAt: Date().addingTimeInterval(-7200),
            description: "Electric vehicle companies",
            isDefault: false,
            sortOrder: 2,
            color: WatchlistColor.green.hexString,
            isPublic: true,
            isFavorite: false,
            dailyPerformance: -0.018,
            gainers: 2,
            losers: 4,
            lastUpdated: Date()
        ),
        Watchlist(
            id: "watchlist-crypto",
            accountId: "account-001",
            name: "Crypto Plays",
            items: ["COIN", "MSTR", "RIOT", "MARA", "CLSK"],
            createdAt: Date().addingTimeInterval(-86400 * 7),
            updatedAt: Date().addingTimeInterval(-1800),
            description: "Crypto-exposed stocks",
            isDefault: false,
            sortOrder: 3,
            color: WatchlistColor.orange.hexString,
            isPublic: false,
            isFavorite: true,
            dailyPerformance: 0.056,
            gainers: 5,
            losers: 0,
            lastUpdated: Date()
        ),
        Watchlist(
            id: "watchlist-ai-stocks",
            accountId: "account-001",
            name: "AI Revolution",
            items: ["NVDA", "AMD", "PLTR", "C3AI", "AI", "SMCI"],
            createdAt: Date().addingTimeInterval(-86400 * 21),
            updatedAt: Date().addingTimeInterval(-86400),
            description: "Artificial intelligence leaders",
            isDefault: false,
            sortOrder: 4,
            color: WatchlistColor.purple.hexString,
            isPublic: true,
            isFavorite: false,
            dailyPerformance: 0.031,
            gainers: 4,
            losers: 2,
            lastUpdated: Date()
        ),
        Watchlist(
            id: "watchlist-dividend-kings",
            accountId: "account-001",
            name: "Dividend Champions",
            items: ["JNJ", "PG", "KO", "PEP", "WMT", "HD", "JPM", "V"],
            createdAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date().addingTimeInterval(-3600 * 6),
            description: "Reliable dividend performers",
            isDefault: false,
            sortOrder: 5,
            color: WatchlistColor.teal.hexString,
            isPublic: false,
            isFavorite: false,
            dailyPerformance: 0.008,
            gainers: 5,
            losers: 3,
            lastUpdated: Date()
        )
    ]
    
    static let sampleData: [Watchlist] = [
        Watchlist(
            id: "watchlist-001",
            accountId: "account-001",
            name: "My Stocks",
            items: ["AAPL", "TSLA", "GOOGL", "MSFT", "AMZN"],
            createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            updatedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            description: "My favorite tech stocks",
            isDefault: true,
            sortOrder: 1,
            color: WatchlistColor.blue.hexString,
            isPublic: false,
            isFavorite: false,
            dailyPerformance: 0.015,
            gainers: 3,
            losers: 2,
            lastUpdated: Date()
        ),
        Watchlist(
            id: "watchlist-002",
            accountId: "account-001",
            name: "Crypto",
            items: ["BTC", "ETH", "ADA", "SOL", "AVAX"],
            createdAt: Date().addingTimeInterval(-86400 * 14), // 2 weeks ago
            updatedAt: Date().addingTimeInterval(-7200), // 2 hours ago
            description: "Cryptocurrency watchlist",
            isDefault: false,
            sortOrder: 2,
            color: WatchlistColor.orange.hexString,
            isPublic: false,
            isFavorite: true,
            dailyPerformance: -0.045,
            gainers: 1,
            losers: 4,
            lastUpdated: Date()
        ),
        Watchlist(
            id: "watchlist-003",
            accountId: "account-001",
            name: "Growth Stocks",
            items: ["NVDA", "AMD", "CRM", "SHOP", "SQ", "ROKU"],
            createdAt: Date().addingTimeInterval(-86400 * 7), // 1 week ago
            updatedAt: Date().addingTimeInterval(-1800), // 30 minutes ago
            description: "High-growth potential stocks",
            isDefault: false,
            sortOrder: 3,
            color: WatchlistColor.green.hexString,
            isPublic: true,
            isFavorite: false,
            dailyPerformance: 0.087,
            gainers: 5,
            losers: 1,
            lastUpdated: Date()
        ),
        Watchlist(
            id: "watchlist-004",
            accountId: "account-001",
            name: "Dividend Stocks",
            items: ["JNJ", "PG", "KO", "PEP", "T", "VZ", "JPM"],
            createdAt: Date().addingTimeInterval(-86400 * 21), // 3 weeks ago
            updatedAt: Date().addingTimeInterval(-86400), // 1 day ago
            description: "Reliable dividend-paying stocks",
            isDefault: false,
            sortOrder: 4,
            color: WatchlistColor.purple.hexString,
            isPublic: false,
            isFavorite: false,
            dailyPerformance: 0.012,
            gainers: 4,
            losers: 3,
            lastUpdated: Date()
        ),
        Watchlist(
            id: "watchlist-005",
            accountId: "account-001",
            name: "Meme Stocks",
            items: ["GME", "AMC", "BB", "NOK", "WISH"],
            createdAt: Date().addingTimeInterval(-86400 * 3), // 3 days ago
            updatedAt: Date().addingTimeInterval(-900), // 15 minutes ago
            description: "High volatility Reddit favorites",
            isDefault: false,
            sortOrder: 5,
            color: WatchlistColor.red.hexString,
            isPublic: false,
            isFavorite: true,
            dailyPerformance: -0.123,
            gainers: 0,
            losers: 5,
            lastUpdated: Date()
        )
    ]
    
    /// Create a new empty watchlist
    static func createNew(name: String, accountId: String, description: String? = nil, color: WatchlistColor = .blue) -> Watchlist {
        return Watchlist(
            id: UUID().uuidString,
            accountId: accountId,
            name: name,
            items: [],
            createdAt: Date(),
            updatedAt: Date(),
            description: description,
            isDefault: false,
            sortOrder: nil,
            color: color.hexString,
            isPublic: false,
            isFavorite: false,
            dailyPerformance: nil,
            gainers: 0,
            losers: 0,
            lastUpdated: nil
        )
    }
    
    /// Create a default watchlist with popular symbols
    static func createDefault(accountId: String) -> Watchlist {
        return Watchlist(
            id: UUID().uuidString,
            accountId: accountId,
            name: "My Watchlist",
            items: ["AAPL", "TSLA", "GOOGL", "MSFT", "AMZN", "NVDA"],
            createdAt: Date(),
            updatedAt: Date(),
            description: "Default watchlist with popular stocks",
            isDefault: true,
            sortOrder: 1,
            color: WatchlistColor.blue.hexString,
            isPublic: false,
            isFavorite: false,
            dailyPerformance: 0.0,
            gainers: 3,
            losers: 3,
            lastUpdated: Date()
        )
    }
}