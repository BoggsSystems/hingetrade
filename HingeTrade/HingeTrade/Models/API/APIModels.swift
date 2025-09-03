import Foundation

// MARK: - Base API Response
struct APIResponse<T: Codable>: Codable {
    let data: T?
    let message: String?
    let success: Bool
    let error: APIError?
    let timestamp: Date?
    let requestId: String?
    
    enum CodingKeys: String, CodingKey {
        case data, message, success, error, timestamp
        case requestId = "request_id"
    }
}

// MARK: - API Error
struct APIError: Codable, Error {
    let code: String
    let message: String
    let details: String?
    let field: String? // For validation errors
    
    var localizedDescription: String {
        return message
    }
    
    var isNetworkError: Bool {
        return code.hasPrefix("NETWORK_") || code.hasPrefix("CONNECTION_")
    }
    
    var isAuthenticationError: Bool {
        return code.hasPrefix("AUTH_") || code == "UNAUTHORIZED"
    }
    
    var isValidationError: Bool {
        return code.hasPrefix("VALIDATION_") || field != nil
    }
    
    var isServerError: Bool {
        return code.hasPrefix("SERVER_") || code.hasPrefix("INTERNAL_")
    }
}

// MARK: - Pagination
struct PaginationMeta: Codable {
    let page: Int
    let perPage: Int
    let totalPages: Int
    let totalCount: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
    
    enum CodingKeys: String, CodingKey {
        case page, totalPages, totalCount
        case perPage = "per_page"
        case hasNextPage = "has_next_page"
        case hasPreviousPage = "has_previous_page"
    }
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: PaginationMeta
    let message: String?
    let success: Bool
}

// MARK: - Authentication API Models
struct LoginRequest: Codable {
    let email: String
    let password: String
    let deviceId: String?
    let appVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case email, password
        case deviceId = "device_id"
        case appVersion = "app_version"
    }
}

struct LoginResponse: Codable {
    let user: User
    let tokens: AuthTokens
    let account: Account?
}

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case tokenType = "token_type"
    }
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
    
    var timeUntilExpiry: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - Trading API Models
struct PlaceOrderRequest: Codable {
    let symbol: String
    let side: OrderSide
    let type: OrderType
    let timeInForce: OrderTimeInForce
    let qty: String?
    let notional: String?
    let limitPrice: String?
    let stopPrice: String?
    let extendedHours: Bool
    let clientOrderId: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol, side, type, qty, notional
        case timeInForce = "time_in_force"
        case limitPrice = "limit_price"
        case stopPrice = "stop_price"
        case extendedHours = "extended_hours"
        case clientOrderId = "client_order_id"
    }
}

struct OrderResponse: Codable {
    let order: Order
    let message: String?
}

struct CancelOrderRequest: Codable {
    let orderId: String
    
    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
    }
}

struct ReplaceOrderRequest: Codable {
    let orderId: String
    let qty: String?
    let limitPrice: String?
    let stopPrice: String?
    let timeInForce: OrderTimeInForce?
    
    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case qty
        case limitPrice = "limit_price"
        case stopPrice = "stop_price"
        case timeInForce = "time_in_force"
    }
}

// MARK: - Market Data API Models
struct QuoteRequest: Codable {
    let symbols: [String]
    let feed: String? // "iex" or "sip"
}

struct QuoteResponse: Codable {
    let quotes: [String: Quote]
}

struct BarsRequest: Codable {
    let symbols: [String]
    let timeframe: String // "1Min", "5Min", "15Min", "1Hour", "1Day"
    let start: Date?
    let end: Date?
    let limit: Int?
    let adjustment: String? // "raw", "split", "dividend", "all"
    let feed: String? // "iex" or "sip"
    
    enum CodingKeys: String, CodingKey {
        case symbols, timeframe, start, end, limit, adjustment, feed
    }
}

struct BarsResponse: Codable {
    let bars: [String: [Bar]]
    let nextPageToken: String?
    
    enum CodingKeys: String, CodingKey {
        case bars
        case nextPageToken = "next_page_token"
    }
}

struct LatestTradeRequest: Codable {
    let symbols: [String]
    let feed: String?
}

struct TradeResponse: Codable {
    let symbol: String
    let timestamp: Date
    let price: Double
    let size: Int
    let conditions: [String]?
    let exchange: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol, timestamp, price, size, conditions, exchange
    }
}

// MARK: - Watchlist API Models
struct CreateWatchlistRequest: Codable {
    let name: String
    let symbols: [String]?
}

struct UpdateWatchlistRequest: Codable {
    let name: String?
    let symbols: [String]?
}

struct AddSymbolToWatchlistRequest: Codable {
    let symbol: String
}

struct RemoveSymbolFromWatchlistRequest: Codable {
    let symbol: String
}

// MARK: - Alert API Models
struct CreateAlertRequest: Codable {
    let symbol: String
    let price: Double
    let condition: AlertCondition
    let message: String?
    let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case symbol, price, condition, message
        case isActive = "is_active"
    }
}

enum AlertCondition: String, CaseIterable, Codable {
    case above = "above"
    case below = "below"
    case crossesAbove = "crosses_above"
    case crossesBelow = "crosses_below"
    
    var displayName: String {
        switch self {
        case .above:
            return "Above"
        case .below:
            return "Below"
        case .crossesAbove:
            return "Crosses Above"
        case .crossesBelow:
            return "Crosses Below"
        }
    }
}

struct UpdateAlertRequest: Codable {
    let price: Double?
    let condition: AlertCondition?
    let message: String?
    let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case price, condition, message
        case isActive = "is_active"
    }
}

struct PriceAlert: Codable, Identifiable {
    let id: String
    let userId: String
    let symbol: String
    let price: Double
    let condition: AlertCondition
    let message: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let triggeredAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, symbol, price, condition, message, createdAt, updatedAt, triggeredAt
        case userId = "user_id"
        case isActive = "is_active"
    }
    
    var isTriggered: Bool {
        return triggeredAt != nil
    }
    
    var formattedPrice: String {
        return price.asCurrency()
    }
    
    var formattedCondition: String {
        return condition.displayName
    }
}

// MARK: - Portfolio API Models
struct PortfolioHistoryRequest: Codable {
    let period: String // "1D", "7D", "1M", "3M", "1Y", "5Y"
    let timeframe: String? // "1Min", "5Min", "15Min", "1Hour", "1Day"
    let extendedHours: Bool?
    
    enum CodingKeys: String, CodingKey {
        case period, timeframe
        case extendedHours = "extended_hours"
    }
}

struct PortfolioSnapshot: Codable {
    let timestamp: Date
    let equity: Double
    let profitLoss: Double
    let profitLossPercent: Double
    let baseValue: Double
    let timeframe: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp, equity, timeframe
        case profitLoss = "profit_loss"
        case profitLossPercent = "profit_loss_percent"
        case baseValue = "base_value"
    }
}

struct PortfolioHistoryResponse: Codable {
    let history: [PortfolioSnapshot]
    let baseValue: Double
    let timeframe: String
    
    enum CodingKeys: String, CodingKey {
        case history, timeframe
        case baseValue = "base_value"
    }
}

// MARK: - Search API Models
struct AssetSearchRequest: Codable {
    let query: String
    let limit: Int?
    let assetClass: AssetClass?
    let exchange: String?
    
    enum CodingKeys: String, CodingKey {
        case query, limit, exchange
        case assetClass = "asset_class"
    }
}

struct AssetSearchResponse: Codable {
    let assets: [Asset]
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case assets
        case totalCount = "total_count"
    }
}

// MARK: - WebSocket Models
struct WebSocketMessage: Codable {
    let type: WebSocketMessageType
    let data: Data? // JSON data varies by type
    let timestamp: Date
    let id: String?
}

enum WebSocketMessageType: String, CaseIterable, Codable {
    case quote = "quote"
    case trade = "trade"
    case bar = "bar"
    case orderUpdate = "order_update"
    case positionUpdate = "position_update"
    case accountUpdate = "account_update"
    case alert = "alert"
    case error = "error"
    case heartbeat = "heartbeat"
    case subscribe = "subscribe"
    case unsubscribe = "unsubscribe"
}

struct WebSocketSubscription: Codable {
    let type: WebSocketMessageType
    let symbols: [String]?
    let channels: [String]?
}

// MARK: - Error Extensions
extension APIError {
    static let networkError = APIError(
        code: "NETWORK_ERROR",
        message: "Network connection failed",
        details: "Please check your internet connection and try again",
        field: nil
    )
    
    static let unauthorized = APIError(
        code: "UNAUTHORIZED",
        message: "Authentication required",
        details: "Please log in to continue",
        field: nil
    )
    
    static let invalidSymbol = APIError(
        code: "VALIDATION_INVALID_SYMBOL",
        message: "Invalid symbol",
        details: "The provided symbol is not valid or supported",
        field: "symbol"
    )
    
    static let insufficientFunds = APIError(
        code: "TRADING_INSUFFICIENT_FUNDS",
        message: "Insufficient buying power",
        details: "You don't have enough buying power to place this order",
        field: "qty"
    )
    
    static let marketClosed = APIError(
        code: "TRADING_MARKET_CLOSED",
        message: "Market is closed",
        details: "This order cannot be placed when the market is closed",
        field: nil
    )
}

// MARK: - Sample API Responses
extension APIResponse {
    static func success<U: Codable>(_ data: U) -> APIResponse<U> {
        return APIResponse<U>(
            data: data,
            message: "Success",
            success: true,
            error: nil,
            timestamp: Date(),
            requestId: UUID().uuidString
        )
    }
    
    static func error<U: Codable>(_ error: APIError) -> APIResponse<U> {
        return APIResponse<U>(
            data: nil,
            message: error.message,
            success: false,
            error: error,
            timestamp: Date(),
            requestId: UUID().uuidString
        )
    }
}