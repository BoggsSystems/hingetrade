import Foundation
import SwiftUI

// MARK: - Market Hours Model
struct MarketHours: Codable, Identifiable, Equatable {
    let date: Date
    let isOpen: Bool
    let openTime: Date?
    let closeTime: Date?
    let earlyOpenTime: Date?
    let lateCloseTime: Date?
    
    // Additional context
    let market: String? // "NYSE", "NASDAQ", "CRYPTO"
    let timezone: String? // "America/New_York", "UTC"
    let isHoliday: Bool?
    let holidayName: String?
    let notes: String?
    
    // Computed ID for Identifiable protocol
    var id: String { 
        let marketPart = market ?? "default"
        return "\(marketPart)-\(date.timeIntervalSince1970)"
    }
    
    enum CodingKeys: String, CodingKey {
        case date, market, timezone, notes
        case isOpen = "is_open"
        case openTime = "open_time"
        case closeTime = "close_time"
        case earlyOpenTime = "early_open_time"
        case lateCloseTime = "late_close_time"
        case isHoliday = "is_holiday"
        case holidayName = "holiday_name"
    }
    
    // MARK: - Computed Properties
    
    /// Formatted date display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    /// Short formatted date
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Formatted open time
    var formattedOpenTime: String {
        guard let openTime = openTime else { return "--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: openTime)
    }
    
    /// Formatted close time
    var formattedCloseTime: String {
        guard let closeTime = closeTime else { return "--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: closeTime)
    }
    
    /// Formatted early open time
    var formattedEarlyOpenTime: String {
        guard let earlyOpenTime = earlyOpenTime else { return "--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: earlyOpenTime)
    }
    
    /// Formatted late close time
    var formattedLateCloseTime: String {
        guard let lateCloseTime = lateCloseTime else { return "--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lateCloseTime)
    }
    
    /// Market session length in hours
    var sessionLength: TimeInterval? {
        guard let openTime = openTime, let closeTime = closeTime else { return nil }
        return closeTime.timeIntervalSince(openTime)
    }
    
    /// Formatted session length
    var formattedSessionLength: String {
        guard let length = sessionLength else { return "--" }
        let hours = Int(length) / 3600
        let minutes = (Int(length) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    /// Extended hours session length
    var extendedSessionLength: TimeInterval? {
        guard let earlyOpen = earlyOpenTime, let lateClose = lateCloseTime else { return nil }
        return lateClose.timeIntervalSince(earlyOpen)
    }
    
    /// Current market status
    var currentStatus: MarketStatus {
        guard isOpen else { return .closed }
        
        let now = Date()
        
        if let earlyOpen = earlyOpenTime, let regularOpen = openTime {
            if now >= earlyOpen && now < regularOpen {
                return .premarket
            }
        }
        
        if let regularOpen = openTime, let regularClose = closeTime {
            if now >= regularOpen && now < regularClose {
                return .open
            }
        }
        
        if let regularClose = closeTime, let lateClose = lateCloseTime {
            if now >= regularClose && now < lateClose {
                return .afterhours
            }
        }
        
        return .closed
    }
    
    /// Time until next market event
    var timeUntilNextEvent: (event: MarketEvent, timeInterval: TimeInterval)? {
        let now = Date()
        
        // Check if we're before early open
        if let earlyOpen = earlyOpenTime, now < earlyOpen {
            return (.premarket, earlyOpen.timeIntervalSince(now))
        }
        
        // Check if we're before regular open
        if let regularOpen = openTime, now < regularOpen {
            return (.open, regularOpen.timeIntervalSince(now))
        }
        
        // Check if we're before regular close
        if let regularClose = closeTime, now < regularClose {
            return (.close, regularClose.timeIntervalSince(now))
        }
        
        // Check if we're before late close
        if let lateClose = lateCloseTime, now < lateClose {
            return (.afterhoursClose, lateClose.timeIntervalSince(now))
        }
        
        return nil
    }
    
    /// Formatted time until next event
    var formattedTimeUntilNextEvent: String {
        guard let (event, interval) = timeUntilNextEvent else { return "Market closed" }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        var timeString = ""
        if hours > 0 {
            timeString += "\(hours)h "
        }
        if minutes > 0 {
            timeString += "\(minutes)m "
        }
        if hours == 0 && minutes < 5 {
            timeString += "\(seconds)s"
        }
        
        return "\(timeString.trimmingCharacters(in: .whitespaces)) until \(event.displayName)"
    }
    
    /// Whether the market is currently in pre-market hours
    var isPremarket: Bool {
        return currentStatus == .premarket
    }
    
    /// Whether the market is currently in regular hours
    var isRegularHours: Bool {
        return currentStatus == .open
    }
    
    /// Whether the market is currently in after-hours
    var isAfterHours: Bool {
        return currentStatus == .afterhours
    }
    
    /// Whether extended hours trading is available
    var hasExtendedHours: Bool {
        return earlyOpenTime != nil && lateCloseTime != nil
    }
    
    /// Market type classification
    var marketType: MarketType {
        guard let market = market else { return .equity }
        
        if market.uppercased().contains("CRYPTO") {
            return .crypto
        } else if market.uppercased().contains("FOREX") || market.uppercased().contains("FX") {
            return .forex
        } else {
            return .equity
        }
    }
    
    /// Trading hours summary
    var tradingHoursSummary: String {
        if marketType == .crypto {
            return "24/7 Trading"
        }
        
        if let openTime = openTime, let closeTime = closeTime {
            return "\(formattedOpenTime) - \(formattedCloseTime)"
        }
        
        return isOpen ? "Open" : "Closed"
    }
    
    /// Extended hours summary
    var extendedHoursSummary: String? {
        guard hasExtendedHours else { return nil }
        return "\(formattedEarlyOpenTime) - \(formattedLateCloseTime) (Extended)"
    }
    
    /// Status color for UI
    var statusColor: MarketStatusColor {
        return currentStatus.color
    }
    
    /// Holiday status message
    var holidayMessage: String? {
        guard let isHoliday = isHoliday, isHoliday else { return nil }
        if let holidayName = holidayName {
            return "Market closed for \(holidayName)"
        }
        return "Market closed for holiday"
    }
}

// MARK: - Market Status
enum MarketStatus: String, CaseIterable, Codable {
    case closed = "Closed"
    case premarket = "Pre-Market"
    case open = "Open"
    case afterhours = "After Hours"
    
    var displayName: String {
        return rawValue
    }
    
    var color: MarketStatusColor {
        switch self {
        case .closed:
            return .red
        case .premarket, .afterhours:
            return .orange
        case .open:
            return .green
        }
    }
    
    var canTrade: Bool {
        switch self {
        case .open:
            return true
        case .premarket, .afterhours:
            return true // Extended hours trading
        case .closed:
            return false
        }
    }
}

enum MarketStatusColor {
    case red
    case orange
    case green
    
    var swiftUIColor: Color {
        switch self {
        case .red:
            return .red
        case .orange:
            return .orange
        case .green:
            return .green
        }
    }
}

// MARK: - Market Event
enum MarketEvent: String, CaseIterable {
    case premarket = "Pre-Market Open"
    case open = "Market Open"
    case close = "Market Close"
    case afterhoursClose = "After Hours Close"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Market Type
enum MarketType: String, CaseIterable {
    case equity = "Equity"
    case crypto = "Cryptocurrency"
    case forex = "Forex"
    
    var displayName: String {
        return rawValue
    }
    
    var tradingSchedule: String {
        switch self {
        case .equity:
            return "Mon-Fri 9:30 AM - 4:00 PM ET"
        case .crypto:
            return "24/7"
        case .forex:
            return "Sun 5 PM - Fri 5 PM ET"
        }
    }
}

// MARK: - Sample Data
extension MarketHours {
    static let sampleData: [MarketHours] = [
        // Today - Regular trading day
        MarketHours(
            date: Date(),
            isOpen: true,
            openTime: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date()),
            closeTime: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()),
            earlyOpenTime: Calendar.current.date(bySettingHour: 4, minute: 0, second: 0, of: Date()),
            lateCloseTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()),
            market: "NYSE",
            timezone: "America/New_York",
            isHoliday: false,
            holidayName: nil,
            notes: "Regular trading hours"
        ),
        // Tomorrow - Regular trading day
        MarketHours(
            date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            isOpen: true,
            openTime: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()),
            closeTime: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()),
            earlyOpenTime: Calendar.current.date(bySettingHour: 4, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()),
            lateCloseTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()),
            market: "NASDAQ",
            timezone: "America/New_York",
            isHoliday: false,
            holidayName: nil,
            notes: "Regular trading hours"
        ),
        // Weekend - Market closed
        MarketHours(
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            isOpen: false,
            openTime: nil,
            closeTime: nil,
            earlyOpenTime: nil,
            lateCloseTime: nil,
            market: "NYSE",
            timezone: "America/New_York",
            isHoliday: false,
            holidayName: nil,
            notes: "Weekend - Market closed"
        ),
        // Crypto market (always open)
        MarketHours(
            date: Date(),
            isOpen: true,
            openTime: nil,
            closeTime: nil,
            earlyOpenTime: nil,
            lateCloseTime: nil,
            market: "CRYPTO",
            timezone: "UTC",
            isHoliday: false,
            holidayName: nil,
            notes: "Cryptocurrency markets are open 24/7"
        )
    ]
    
    /// Generate sample market hours for a date range
    static func generateSampleData(from startDate: Date, days: Int) -> [MarketHours] {
        var marketHours: [MarketHours] = []
        let calendar = Calendar.current
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            
            // Skip weekends for equity markets
            let isWeekend = weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
            
            let hours = MarketHours(
                date: date,
                isOpen: !isWeekend,
                openTime: isWeekend ? nil : calendar.date(bySettingHour: 9, minute: 30, second: 0, of: date),
                closeTime: isWeekend ? nil : calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date),
                earlyOpenTime: isWeekend ? nil : calendar.date(bySettingHour: 4, minute: 0, second: 0, of: date),
                lateCloseTime: isWeekend ? nil : calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date),
                market: "NYSE",
                timezone: "America/New_York",
                isHoliday: false,
                holidayName: nil,
                notes: isWeekend ? "Weekend - Market closed" : "Regular trading hours"
            )
            
            marketHours.append(hours)
        }
        
        return marketHours
    }
}