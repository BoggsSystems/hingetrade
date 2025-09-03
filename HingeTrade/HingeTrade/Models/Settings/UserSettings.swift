//
//  UserSettings.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Foundation

// MARK: - User Settings

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
    
    var projectedValue: UserDefault<T> {
        return self
    }
}

class UserSettings: ObservableObject {
    
    // MARK: - Account & Profile Settings
    
    @Published var displayName: String {
        didSet { UserDefaults.standard.set(displayName, forKey: "user_display_name") }
    }
    
    @Published var emailAddress: String {
        didSet { UserDefaults.standard.set(emailAddress, forKey: "user_email") }
    }
    
    @Published var accountType: String {
        didSet { UserDefaults.standard.set(accountType, forKey: "account_type") }
    }
    
    @Published var profileImageURL: String {
        didSet { UserDefaults.standard.set(profileImageURL, forKey: "profile_image_url") }
    }
    
    // MARK: - Trading Preferences
    
    @Published var defaultOrderType: String {
        didSet { UserDefaults.standard.set(defaultOrderType, forKey: "trading_default_order_type") }
    }
    
    @Published var defaultTimeInForce: String {
        didSet { UserDefaults.standard.set(defaultTimeInForce, forKey: "trading_default_time_in_force") }
    }
    
    @Published var autoConfirmOrders: Bool {
        didSet { UserDefaults.standard.set(autoConfirmOrders, forKey: "trading_auto_confirm_orders") }
    }
    
    @Published var enableFractionalShares: Bool {
        didSet { UserDefaults.standard.set(enableFractionalShares, forKey: "trading_enable_fractional_shares") }
    }
    
    @Published var defaultQuantity: Int {
        didSet { UserDefaults.standard.set(defaultQuantity, forKey: "trading_default_quantity") }
    }
    
    @Published var enableExtendedHours: Bool {
        didSet { UserDefaults.standard.set(enableExtendedHours, forKey: "trading_enable_extended_hours") }
    }
    
    // MARK: - Risk Management Settings
    
    @Published var riskProfile: String {
        didSet { UserDefaults.standard.set(riskProfile, forKey: "risk_profile") }
    }
    
    @Published var maxPositionSize: Double {
        didSet { UserDefaults.standard.set(maxPositionSize, forKey: "risk_max_position_size") }
    }
    
    @Published var maxDailyLoss: Double {
        didSet { UserDefaults.standard.set(maxDailyLoss, forKey: "risk_max_daily_loss") }
    }
    
    @Published var enableStopLosses: Bool {
        didSet { UserDefaults.standard.set(enableStopLosses, forKey: "risk_enable_stop_losses") }
    }
    
    @Published var defaultStopLossPercent: Double {
        didSet { UserDefaults.standard.set(defaultStopLossPercent, forKey: "risk_default_stop_loss_percent") }
    }
    
    @Published var enablePositionSizing: Bool {
        didSet { UserDefaults.standard.set(enablePositionSizing, forKey: "risk_enable_position_sizing") }
    }
    
    // MARK: - Display & Appearance Settings
    
    @Published var theme: String {
        didSet { UserDefaults.standard.set(theme, forKey: "display_theme") }
    }
    
    @Published var colorScheme: String {
        didSet { UserDefaults.standard.set(colorScheme, forKey: "display_color_scheme") }
    }
    
    @Published var showAfterHours: Bool {
        didSet { UserDefaults.standard.set(showAfterHours, forKey: "display_show_after_hours") }
    }
    
    @Published var showExtendedQuotes: Bool {
        didSet { UserDefaults.standard.set(showExtendedQuotes, forKey: "display_show_extended_quotes") }
    }
    
    @Published var defaultChartType: String {
        didSet { UserDefaults.standard.set(defaultChartType, forKey: "display_chart_type") }
    }
    
    @Published var priceFormat: String {
        didSet { UserDefaults.standard.set(priceFormat, forKey: "display_price_format") }
    }
    
    @Published var percentFormat: String {
        didSet { UserDefaults.standard.set(percentFormat, forKey: "display_percent_format") }
    }
    
    // MARK: - Notification Settings
    
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notifications_enabled") }
    }
    
    @Published var priceAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(priceAlertsEnabled, forKey: "notifications_price_alerts") }
    }
    
    @Published var orderUpdatesEnabled: Bool {
        didSet { UserDefaults.standard.set(orderUpdatesEnabled, forKey: "notifications_order_updates") }
    }
    
    @Published var marketNewsEnabled: Bool {
        didSet { UserDefaults.standard.set(marketNewsEnabled, forKey: "notifications_market_news") }
    }
    
    @Published var portfolioUpdatesEnabled: Bool {
        didSet { UserDefaults.standard.set(portfolioUpdatesEnabled, forKey: "notifications_portfolio_updates") }
    }
    
    @Published var researchReportsEnabled: Bool {
        didSet { UserDefaults.standard.set(researchReportsEnabled, forKey: "notifications_research_reports") }
    }
    
    @Published var notificationSounds: Bool {
        didSet { UserDefaults.standard.set(notificationSounds, forKey: "notifications_sound_enabled") }
    }
    
    // MARK: - Data & Privacy Settings
    
    @Published var realTimeQuotes: Bool {
        didSet { UserDefaults.standard.set(realTimeQuotes, forKey: "data_real_time_quotes") }
    }
    
    @Published var analyticsEnabled: Bool {
        didSet { UserDefaults.standard.set(analyticsEnabled, forKey: "data_analytics_enabled") }
    }
    
    @Published var crashReporting: Bool {
        didSet { UserDefaults.standard.set(crashReporting, forKey: "data_crash_reporting") }
    }
    
    @Published var usageStatistics: Bool {
        didSet { UserDefaults.standard.set(usageStatistics, forKey: "data_usage_statistics") }
    }
    
    @Published var personalizationEnabled: Bool {
        didSet { UserDefaults.standard.set(personalizationEnabled, forKey: "data_personalization") }
    }
    
    // MARK: - Security Settings
    
    @Published var biometricAuthEnabled: Bool {
        didSet { UserDefaults.standard.set(biometricAuthEnabled, forKey: "security_biometric_enabled") }
    }
    
    @Published var autoLogoutMinutes: Int {
        didSet { UserDefaults.standard.set(autoLogoutMinutes, forKey: "security_auto_logout_minutes") }
    }
    
    @Published var requireAuthForTrades: Bool {
        didSet { UserDefaults.standard.set(requireAuthForTrades, forKey: "security_require_auth_for_trades") }
    }
    
    @Published var maskSensitiveData: Bool {
        didSet { UserDefaults.standard.set(maskSensitiveData, forKey: "security_mask_sensitive_data") }
    }
    
    @Published var twoFactorEnabled: Bool {
        didSet { UserDefaults.standard.set(twoFactorEnabled, forKey: "security_two_factor_enabled") }
    }
    
    // MARK: - Accessibility Settings
    
    @Published var largeText: Bool {
        didSet { UserDefaults.standard.set(largeText, forKey: "accessibility_large_text") }
    }
    
    @Published var highContrast: Bool {
        didSet { UserDefaults.standard.set(highContrast, forKey: "accessibility_high_contrast") }
    }
    
    @Published var reduceMotion: Bool {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: "accessibility_reduce_motion") }
    }
    
    @Published var voiceOverEnabled: Bool {
        didSet { UserDefaults.standard.set(voiceOverEnabled, forKey: "accessibility_voice_over") }
    }
    
    @Published var hapticFeedback: Bool {
        didSet { UserDefaults.standard.set(hapticFeedback, forKey: "accessibility_haptic_feedback") }
    }
    
    // MARK: - Advanced Settings
    
    @Published var debugMode: Bool {
        didSet { UserDefaults.standard.set(debugMode, forKey: "advanced_debug_mode") }
    }
    
    @Published var betaFeatures: Bool {
        didSet { UserDefaults.standard.set(betaFeatures, forKey: "advanced_beta_features") }
    }
    
    @Published var apiEnvironment: String {
        didSet { UserDefaults.standard.set(apiEnvironment, forKey: "advanced_api_environment") }
    }
    
    @Published var cacheSizeMB: Int {
        didSet { UserDefaults.standard.set(cacheSizeMB, forKey: "advanced_cache_size_mb") }
    }
    
    @Published var logLevel: String {
        didSet { UserDefaults.standard.set(logLevel, forKey: "advanced_log_level") }
    }
    
    // MARK: - Watchlist Settings
    
    @Published var watchlistAutoSync: Bool {
        didSet { UserDefaults.standard.set(watchlistAutoSync, forKey: "watchlist_auto_sync") }
    }
    
    @Published var defaultWatchlistSort: String {
        didSet { UserDefaults.standard.set(defaultWatchlistSort, forKey: "watchlist_default_sort") }
    }
    
    @Published var showChangePercent: Bool {
        didSet { UserDefaults.standard.set(showChangePercent, forKey: "watchlist_show_change_percent") }
    }
    
    @Published var showVolume: Bool {
        didSet { UserDefaults.standard.set(showVolume, forKey: "watchlist_show_volume") }
    }
    
    @Published var showMarketCap: Bool {
        didSet { UserDefaults.standard.set(showMarketCap, forKey: "watchlist_show_market_cap") }
    }
    
    // MARK: - Chart Settings
    
    @Published var defaultChartTimeframe: String {
        didSet { UserDefaults.standard.set(defaultChartTimeframe, forKey: "charts_default_timeframe") }
    }
    
    @Published var chartsShowVolume: Bool {
        didSet { UserDefaults.standard.set(chartsShowVolume, forKey: "charts_show_volume") }
    }
    
    @Published var chartsShowIndicators: Bool {
        didSet { UserDefaults.standard.set(chartsShowIndicators, forKey: "charts_show_indicators") }
    }
    
    @Published var chartsAutoScale: Bool {
        didSet { UserDefaults.standard.set(chartsAutoScale, forKey: "charts_auto_scale") }
    }
    
    // MARK: - Helper Methods
    
    static let shared = UserSettings()
    
    private init() {
        // Load values from UserDefaults with fallback to defaults
        self.displayName = UserDefaults.standard.object(forKey: "user_display_name") as? String ?? ""
        self.emailAddress = UserDefaults.standard.object(forKey: "user_email") as? String ?? ""
        self.accountType = UserDefaults.standard.object(forKey: "account_type") as? String ?? AccountType.individual.rawValue
        self.profileImageURL = UserDefaults.standard.object(forKey: "profile_image_url") as? String ?? ""
        
        // Trading preferences
        self.defaultOrderType = UserDefaults.standard.object(forKey: "trading_default_order_type") as? String ?? OrderType.market.rawValue
        self.defaultTimeInForce = UserDefaults.standard.object(forKey: "trading_default_time_in_force") as? String ?? OrderTimeInForce.day.rawValue
        self.autoConfirmOrders = UserDefaults.standard.object(forKey: "trading_auto_confirm_orders") as? Bool ?? false
        self.enableFractionalShares = UserDefaults.standard.object(forKey: "trading_enable_fractional_shares") as? Bool ?? true
        self.defaultQuantity = UserDefaults.standard.object(forKey: "trading_default_quantity") as? Int ?? 1
        self.enableExtendedHours = UserDefaults.standard.object(forKey: "trading_enable_extended_hours") as? Bool ?? false
        
        // Risk management
        self.riskProfile = UserDefaults.standard.object(forKey: "risk_profile") as? String ?? RiskProfile.moderate.rawValue
        self.maxPositionSize = UserDefaults.standard.object(forKey: "risk_max_position_size") as? Double ?? 0.10
        self.maxDailyLoss = UserDefaults.standard.object(forKey: "risk_max_daily_loss") as? Double ?? 0.05
        self.enableStopLosses = UserDefaults.standard.object(forKey: "risk_enable_stop_losses") as? Bool ?? true
        self.defaultStopLossPercent = UserDefaults.standard.object(forKey: "risk_default_stop_loss_percent") as? Double ?? 0.08
        self.enablePositionSizing = UserDefaults.standard.object(forKey: "risk_enable_position_sizing") as? Bool ?? true
        
        // Display settings
        self.theme = UserDefaults.standard.object(forKey: "display_theme") as? String ?? "dark" // AppTheme.dark.rawValue
        self.colorScheme = UserDefaults.standard.object(forKey: "display_color_scheme") as? String ?? "blue" // ColorScheme.blue.rawValue
        self.showAfterHours = UserDefaults.standard.object(forKey: "display_show_after_hours") as? Bool ?? true
        self.showExtendedQuotes = UserDefaults.standard.object(forKey: "display_show_extended_quotes") as? Bool ?? false
        self.defaultChartType = UserDefaults.standard.object(forKey: "display_chart_type") as? String ?? "candlestick" // ChartDisplayType.candlestick.rawValue
        self.priceFormat = UserDefaults.standard.object(forKey: "display_price_format") as? String ?? "currency" // PriceFormat.currency.rawValue
        self.percentFormat = UserDefaults.standard.object(forKey: "display_percent_format") as? String ?? "decimal" // PercentFormat.decimal.rawValue
        
        // Notifications
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notifications_enabled") as? Bool ?? true
        self.priceAlertsEnabled = UserDefaults.standard.object(forKey: "notifications_price_alerts") as? Bool ?? true
        self.orderUpdatesEnabled = UserDefaults.standard.object(forKey: "notifications_order_updates") as? Bool ?? true
        self.marketNewsEnabled = UserDefaults.standard.object(forKey: "notifications_market_news") as? Bool ?? false
        self.portfolioUpdatesEnabled = UserDefaults.standard.object(forKey: "notifications_portfolio_updates") as? Bool ?? true
        self.researchReportsEnabled = UserDefaults.standard.object(forKey: "notifications_research_reports") as? Bool ?? false
        self.notificationSounds = UserDefaults.standard.object(forKey: "notifications_sound_enabled") as? Bool ?? true
        
        // Data & Privacy
        self.realTimeQuotes = UserDefaults.standard.object(forKey: "data_real_time_quotes") as? Bool ?? true
        self.analyticsEnabled = UserDefaults.standard.object(forKey: "data_analytics_enabled") as? Bool ?? true
        self.crashReporting = UserDefaults.standard.object(forKey: "data_crash_reporting") as? Bool ?? true
        self.usageStatistics = UserDefaults.standard.object(forKey: "data_usage_statistics") as? Bool ?? false
        self.personalizationEnabled = UserDefaults.standard.object(forKey: "data_personalization") as? Bool ?? true
        
        // Security
        self.biometricAuthEnabled = UserDefaults.standard.object(forKey: "security_biometric_enabled") as? Bool ?? false
        self.autoLogoutMinutes = UserDefaults.standard.object(forKey: "security_auto_logout_minutes") as? Int ?? 30
        self.requireAuthForTrades = UserDefaults.standard.object(forKey: "security_require_auth_for_trades") as? Bool ?? true
        self.maskSensitiveData = UserDefaults.standard.object(forKey: "security_mask_sensitive_data") as? Bool ?? false
        self.twoFactorEnabled = UserDefaults.standard.object(forKey: "security_two_factor_enabled") as? Bool ?? false
        
        // Accessibility
        self.largeText = UserDefaults.standard.object(forKey: "accessibility_large_text") as? Bool ?? false
        self.highContrast = UserDefaults.standard.object(forKey: "accessibility_high_contrast") as? Bool ?? false
        self.reduceMotion = UserDefaults.standard.object(forKey: "accessibility_reduce_motion") as? Bool ?? false
        self.voiceOverEnabled = UserDefaults.standard.object(forKey: "accessibility_voice_over") as? Bool ?? false
        self.hapticFeedback = UserDefaults.standard.object(forKey: "accessibility_haptic_feedback") as? Bool ?? true
        
        // Advanced
        self.debugMode = UserDefaults.standard.object(forKey: "advanced_debug_mode") as? Bool ?? false
        self.betaFeatures = UserDefaults.standard.object(forKey: "advanced_beta_features") as? Bool ?? false
        self.apiEnvironment = UserDefaults.standard.object(forKey: "advanced_api_environment") as? String ?? "production" // APIEnvironment.production.rawValue
        self.cacheSizeMB = UserDefaults.standard.object(forKey: "advanced_cache_size_mb") as? Int ?? 100
        self.logLevel = UserDefaults.standard.object(forKey: "advanced_log_level") as? String ?? "info" // LogLevel.info.rawValue
        
        // Watchlist
        self.watchlistAutoSync = UserDefaults.standard.object(forKey: "watchlist_auto_sync") as? Bool ?? true
        self.defaultWatchlistSort = UserDefaults.standard.object(forKey: "watchlist_default_sort") as? String ?? "alphabetical" // WatchlistSort.alphabetical.rawValue
        self.showChangePercent = UserDefaults.standard.object(forKey: "watchlist_show_change_percent") as? Bool ?? true
        self.showVolume = UserDefaults.standard.object(forKey: "watchlist_show_volume") as? Bool ?? false
        self.showMarketCap = UserDefaults.standard.object(forKey: "watchlist_show_market_cap") as? Bool ?? false
        
        // Charts
        self.defaultChartTimeframe = UserDefaults.standard.object(forKey: "charts_default_timeframe") as? String ?? "oneDay" // ChartTimeframe.oneDay.rawValue
        self.chartsShowVolume = UserDefaults.standard.object(forKey: "charts_show_volume") as? Bool ?? true
        self.chartsShowIndicators = UserDefaults.standard.object(forKey: "charts_show_indicators") as? Bool ?? false
        self.chartsAutoScale = UserDefaults.standard.object(forKey: "charts_auto_scale") as? Bool ?? true
    }
    
    func resetToDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
    func exportSettings() -> [String: Any] {
        let defaults = UserDefaults.standard.dictionaryRepresentation()
        return defaults.filter { $0.key.hasPrefix("user_") || $0.key.hasPrefix("trading_") || $0.key.hasPrefix("display_") }
    }
    
    func importSettings(_ settings: [String: Any]) {
        for (key, value) in settings {
            UserDefaults.standard.set(value, forKey: key)
        }
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Supporting Enums

enum AccountType: String, CaseIterable, Codable {
    case individual = "individual"
    case joint = "joint"
    case business = "business"
    case retirement = "retirement"
    
    var displayName: String {
        switch self {
        case .individual: return "Individual"
        case .joint: return "Joint"
        case .business: return "Business"
        case .retirement: return "Retirement"
        }
    }
}

enum AppTheme: String, CaseIterable {
    case dark = "dark"
    case light = "light"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .auto: return "Automatic"
        }
    }
}

enum ColorScheme: String, CaseIterable {
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case orange = "orange"
    case red = "red"
    
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .purple: return "Purple"
        case .orange: return "Orange"
        case .red: return "Red"
        }
    }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        }
    }
}

enum ChartDisplayType: String, CaseIterable {
    case line = "line"
    case candlestick = "candlestick"
    case area = "area"
    case bar = "bar"
    
    var displayName: String {
        switch self {
        case .line: return "Line"
        case .candlestick: return "Candlestick"
        case .area: return "Area"
        case .bar: return "Bar"
        }
    }
}

enum PriceFormat: String, CaseIterable {
    case currency = "currency"
    case decimal = "decimal"
    case fraction = "fraction"
    
    var displayName: String {
        switch self {
        case .currency: return "$123.45"
        case .decimal: return "123.45"
        case .fraction: return "123 45/100"
        }
    }
}

enum PercentFormat: String, CaseIterable {
    case decimal = "decimal"
    case fraction = "fraction"
    
    var displayName: String {
        switch self {
        case .decimal: return "12.34%"
        case .fraction: return "1234 bps"
        }
    }
}

enum APIEnvironment: String, CaseIterable {
    case production = "production"
    case staging = "staging"
    case development = "development"
    
    var displayName: String {
        switch self {
        case .production: return "Production"
        case .staging: return "Staging"
        case .development: return "Development"
        }
    }
}

enum LogLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

enum WatchlistSort: String, CaseIterable {
    case alphabetical = "alphabetical"
    case performance = "performance"
    case marketCap = "market_cap"
    case volume = "volume"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .alphabetical: return "Alphabetical"
        case .performance: return "Performance"
        case .marketCap: return "Market Cap"
        case .volume: return "Volume"
        case .custom: return "Custom"
        }
    }
}

enum ChartTimeframe: String, CaseIterable {
    case oneDay = "1D"
    case fiveDay = "5D"
    case oneMonth = "1M"
    case threeMonth = "3M"
    case sixMonth = "6M"
    case oneYear = "1Y"
    case twoYear = "2Y"
    case fiveYear = "5Y"
    
    var displayName: String {
        switch self {
        case .oneDay: return "1 Day"
        case .fiveDay: return "5 Days"
        case .oneMonth: return "1 Month"
        case .threeMonth: return "3 Months"
        case .sixMonth: return "6 Months"
        case .oneYear: return "1 Year"
        case .twoYear: return "2 Years"
        case .fiveYear: return "5 Years"
        }
    }
}