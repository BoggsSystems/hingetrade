import Foundation

// MARK: - Double Extensions
extension Double {
    /// Formats a double as currency (e.g., $1,234.56)
    func asCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    /// Formats a double as percentage (e.g., 12.34%)
    func asPercentage(decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: self)) ?? "0%"
    }
    
    /// Formats a double with specified decimal places
    func asFormatted(decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
    
    /// Formats large numbers with K, M, B suffixes
    func asAbbreviated() -> String {
        let num = abs(self)
        let sign = self < 0 ? "-" : ""
        
        switch num {
        case 1_000_000_000...:
            let formatted = num / 1_000_000_000
            return "\(sign)\(formatted.asFormatted(decimals: formatted >= 10 ? 1 : 2))B"
        case 1_000_000...:
            let formatted = num / 1_000_000
            return "\(sign)\(formatted.asFormatted(decimals: formatted >= 10 ? 1 : 2))M"
        case 1_000...:
            let formatted = num / 1_000
            return "\(sign)\(formatted.asFormatted(decimals: formatted >= 10 ? 1 : 2))K"
        default:
            return "\(sign)\(num.asFormatted(decimals: 0))"
        }
    }
    
    /// Formats basis points (e.g., 0.0123 -> 123 bps)
    func asBasisPoints() -> String {
        let bps = self * 10000
        return "\(bps.asFormatted(decimals: 0)) bps"
    }
    
    /// Checks if the number is effectively zero (within tolerance)
    func isEffectivelyZero(tolerance: Double = 0.001) -> Bool {
        return abs(self) < tolerance
    }
    
    /// Returns the sign of the number as a string
    var signString: String {
        if self > 0 { return "+" }
        if self < 0 { return "-" }
        return ""
    }
    
    /// Clamps the value between min and max
    func clamped(min: Double, max: Double) -> Double {
        return Swift.min(Swift.max(self, min), max)
    }
    
    /// Rounds to a specific number of decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Int Extensions
extension Int {
    /// Formats large numbers with K, M, B suffixes
    func asAbbreviated() -> String {
        return Double(self).asAbbreviated()
    }
    
    /// Formats with thousand separators
    func asFormatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
    
    /// Converts to ordinal string (1st, 2nd, 3rd, etc.)
    func asOrdinal() -> String {
        let suffix: String
        let ones = self % 10
        let tens = (self % 100) / 10
        
        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        
        return "\(self)\(suffix)"
    }
}

// MARK: - Date Extensions
extension Date {
    /// Formats date as "2 hours ago", "3 days ago", etc.
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Formats date as "Jan 15, 2024"
    var shortDateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Formats date as "Jan 15, 2024 at 2:30 PM"
    var mediumDateTimeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Formats time as "2:30 PM"
    var timeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Returns true if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Returns true if date is within the current week
    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Returns true if date is within the current month
    var isThisMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// Returns true if date is within the current year
    var isThisYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// Start of day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// End of day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// Start of week (Sunday)
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Start of month
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }
    
    /// Start of year
    var startOfYear: Date {
        let components = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: components) ?? self
    }
}

// MARK: - String Extensions for Numbers
extension String {
    /// Converts string to Double, returns nil if invalid
    var asDouble: Double? {
        return Double(self)
    }
    
    /// Converts string to Int, returns nil if invalid
    var asInt: Int? {
        return Int(self)
    }
    
    /// Checks if string represents a valid number
    var isNumeric: Bool {
        return asDouble != nil
    }
    
    /// Formats string as currency if it's a valid number
    var asCurrency: String? {
        guard let value = asDouble else { return nil }
        return value.asCurrency()
    }
    
    /// Truncates string to specified length with ellipsis
    func truncated(toLength length: Int, withEllipsis: Bool = true) -> String {
        if self.count <= length {
            return self
        }
        
        let truncated = String(self.prefix(length))
        return withEllipsis ? truncated + "..." : truncated
    }
}