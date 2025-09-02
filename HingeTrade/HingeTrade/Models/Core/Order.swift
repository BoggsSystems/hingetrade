import Foundation

// MARK: - Order Side Enum
enum OrderSide: String, CaseIterable, Codable {
    case buy = "buy"
    case sell = "sell"
    
    var displayName: String {
        switch self {
        case .buy:
            return "Buy"
        case .sell:
            return "Sell"
        }
    }
    
    var color: OrderSideColor {
        switch self {
        case .buy:
            return .buy
        case .sell:
            return .sell
        }
    }
}

// MARK: - Order Type Enum
enum OrderType: String, CaseIterable, Codable {
    case market = "market"
    case limit = "limit"
    case stop = "stop"
    case stopLimit = "stop_limit"
    
    var displayName: String {
        switch self {
        case .market:
            return "Market"
        case .limit:
            return "Limit"
        case .stop:
            return "Stop"
        case .stopLimit:
            return "Stop Limit"
        }
    }
    
    var requiresLimitPrice: Bool {
        return self == .limit || self == .stopLimit
    }
    
    var requiresStopPrice: Bool {
        return self == .stop || self == .stopLimit
    }
}

// MARK: - Time in Force Enum
enum OrderTimeInForce: String, CaseIterable, Codable {
    case day = "day"
    case gtc = "gtc"
    case opg = "opg"
    case cls = "cls"
    case ioc = "ioc"
    case fok = "fok"
    
    var displayName: String {
        switch self {
        case .day:
            return "Day"
        case .gtc:
            return "Good Till Canceled"
        case .opg:
            return "At Open"
        case .cls:
            return "At Close"
        case .ioc:
            return "Immediate or Cancel"
        case .fok:
            return "Fill or Kill"
        }
    }
    
    var shortName: String {
        switch self {
        case .day:
            return "DAY"
        case .gtc:
            return "GTC"
        case .opg:
            return "OPG"
        case .cls:
            return "CLS"
        case .ioc:
            return "IOC"
        case .fok:
            return "FOK"
        }
    }
}

// MARK: - Order Status Enum
enum OrderStatus: String, CaseIterable, Codable {
    case new = "new"
    case partiallyFilled = "partially_filled"
    case filled = "filled"
    case doneForDay = "done_for_day"
    case canceled = "canceled"
    case expired = "expired"
    case replaced = "replaced"
    case pendingCancel = "pending_cancel"
    case pendingReplace = "pending_replace"
    case accepted = "accepted"
    case pendingNew = "pending_new"
    case acceptedForBidding = "accepted_for_bidding"
    case stopped = "stopped"
    case rejected = "rejected"
    case suspended = "suspended"
    case calculated = "calculated"
    
    var displayName: String {
        switch self {
        case .new:
            return "New"
        case .partiallyFilled:
            return "Partially Filled"
        case .filled:
            return "Filled"
        case .doneForDay:
            return "Done for Day"
        case .canceled:
            return "Canceled"
        case .expired:
            return "Expired"
        case .replaced:
            return "Replaced"
        case .pendingCancel:
            return "Pending Cancel"
        case .pendingReplace:
            return "Pending Replace"
        case .accepted:
            return "Accepted"
        case .pendingNew:
            return "Pending New"
        case .acceptedForBidding:
            return "Accepted for Bidding"
        case .stopped:
            return "Stopped"
        case .rejected:
            return "Rejected"
        case .suspended:
            return "Suspended"
        case .calculated:
            return "Calculated"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .new, .partiallyFilled, .accepted, .pendingNew, .pendingCancel, .pendingReplace:
            return true
        default:
            return false
        }
    }
    
    var isFinal: Bool {
        switch self {
        case .filled, .canceled, .expired, .rejected:
            return true
        default:
            return false
        }
    }
    
    var color: OrderStatusColor {
        switch self {
        case .filled:
            return .success
        case .canceled, .expired, .rejected:
            return .error
        case .partiallyFilled:
            return .warning
        default:
            return .pending
        }
    }
}

// MARK: - Order Model
struct Order: Codable, Identifiable, Equatable {
    let id: String
    let clientOrderId: String?
    let createdAt: Date
    let updatedAt: Date?
    let submittedAt: Date?
    let filledAt: Date?
    let expiredAt: Date?
    let canceledAt: Date?
    let failedAt: Date?
    let replacedAt: Date?
    let replacedBy: String?
    let replaces: String?
    
    let assetId: String
    let symbol: String
    let assetClass: AssetClass
    
    let qty: String?
    let filledQty: String?
    let notional: String?
    let filledAvgPrice: String?
    
    let side: OrderSide
    let type: OrderType
    let timeInForce: OrderTimeInForce
    let limitPrice: String?
    let stopPrice: String?
    let status: OrderStatus
    let extendedHours: Bool
    
    let legs: [Order]?
    
    enum CodingKeys: String, CodingKey {
        case id, symbol, qty, side, type, status, legs
        case clientOrderId = "client_order_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case submittedAt = "submitted_at"
        case filledAt = "filled_at"
        case expiredAt = "expired_at"
        case canceledAt = "canceled_at"
        case failedAt = "failed_at"
        case replacedAt = "replaced_at"
        case replacedBy = "replaced_by"
        case replaces = "replaces"
        case assetId = "asset_id"
        case assetClass = "asset_class"
        case filledQty = "filled_qty"
        case notional = "notional"
        case filledAvgPrice = "filled_avg_price"
        case timeInForce = "time_in_force"
        case limitPrice = "limit_price"
        case stopPrice = "stop_price"
        case extendedHours = "extended_hours"
    }
    
    // MARK: - Computed Properties
    
    /// Formatted quantity display
    var formattedQty: String {
        guard let qty = qty, let qtyValue = Double(qty) else { return "--" }
        return qtyValue.asFormatted(decimals: qtyValue.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 3)
    }
    
    /// Formatted filled quantity display
    var formattedFilledQty: String {
        guard let filledQty = filledQty, let filledValue = Double(filledQty) else { return "--" }
        return filledValue.asFormatted(decimals: filledValue.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 3)
    }
    
    /// Formatted limit price display
    var formattedLimitPrice: String {
        guard let limitPrice = limitPrice, let priceValue = Double(limitPrice) else { return "--" }
        return priceValue.asCurrency()
    }
    
    /// Formatted stop price display
    var formattedStopPrice: String {
        guard let stopPrice = stopPrice, let priceValue = Double(stopPrice) else { return "--" }
        return priceValue.asCurrency()
    }
    
    /// Formatted filled average price display
    var formattedFilledAvgPrice: String {
        guard let filledAvgPrice = filledAvgPrice, let priceValue = Double(filledAvgPrice) else { return "--" }
        return priceValue.asCurrency()
    }
    
    /// Order value (quantity * price)
    var orderValue: Double? {
        if let notional = notional, let notionalValue = Double(notional) {
            return notionalValue
        }
        
        guard let qty = qty, let qtyValue = Double(qty) else { return nil }
        
        if let limitPrice = limitPrice, let priceValue = Double(limitPrice) {
            return qtyValue * priceValue
        }
        
        return nil
    }
    
    /// Formatted order value display
    var formattedOrderValue: String {
        guard let value = orderValue else { return "--" }
        return value.asCurrency()
    }
    
    /// Fill percentage (0.0 to 1.0)
    var fillPercentage: Double {
        guard let qty = qty, let qtyValue = Double(qty), qtyValue > 0,
              let filledQty = filledQty, let filledValue = Double(filledQty) else {
            return 0.0
        }
        return min(filledValue / qtyValue, 1.0)
    }
    
    /// Formatted fill percentage display
    var formattedFillPercentage: String {
        return (fillPercentage * 100).asPercentage(decimals: 1)
    }
    
    /// Whether this is a multi-leg order
    var isMultiLeg: Bool {
        return legs?.isEmpty == false
    }
    
    /// Age of the order in human readable format
    var ageDescription: String {
        return createdAt.timeAgoDisplay
    }
}

// MARK: - Order Colors
enum OrderSideColor {
    case buy
    case sell
}

enum OrderStatusColor {
    case success
    case error
    case warning
    case pending
}

// MARK: - Sample Data
extension Order {
    static let sampleData: [Order] = [
        Order(
            id: "61e69015-8549-4bfd-b9c3-01e75843f47d",
            clientOrderId: "my_order_001",
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            updatedAt: Date().addingTimeInterval(-3500),
            submittedAt: Date().addingTimeInterval(-3600),
            filledAt: Date().addingTimeInterval(-3500),
            expiredAt: nil,
            canceledAt: nil,
            failedAt: nil,
            replacedAt: nil,
            replacedBy: nil,
            replaces: nil,
            assetId: "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
            symbol: "AAPL",
            assetClass: .usEquity,
            qty: "100",
            filledQty: "100",
            notional: nil,
            filledAvgPrice: "188.25",
            side: .buy,
            type: .limit,
            timeInForce: .day,
            limitPrice: "188.50",
            stopPrice: nil,
            status: .filled,
            extendedHours: false,
            legs: nil
        ),
        Order(
            id: "904837e3-3b76-47ec-b432-046db621571b",
            clientOrderId: nil,
            createdAt: Date().addingTimeInterval(-1800), // 30 minutes ago
            updatedAt: Date().addingTimeInterval(-1800),
            submittedAt: Date().addingTimeInterval(-1800),
            filledAt: nil,
            expiredAt: nil,
            canceledAt: nil,
            failedAt: nil,
            replacedAt: nil,
            replacedBy: nil,
            replaces: nil,
            assetId: "64bbff51-59d6-4b3c-9351-13ad85e3c752",
            symbol: "TSLA",
            assetClass: .usEquity,
            qty: "50",
            filledQty: "25",
            notional: nil,
            filledAvgPrice: "183.15",
            side: .sell,
            type: .limit,
            timeInForce: .gtc,
            limitPrice: "183.00",
            stopPrice: nil,
            status: .partiallyFilled,
            extendedHours: false,
            legs: nil
        )
    ]
}