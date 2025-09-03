//
//  SettingsViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var userSettings = UserSettings.shared
    @Published var selectedSection: SettingsSection = .account
    @Published var isLoading = false
    @Published var error: SettingsError?
    @Published var showingError = false
    @Published var showingResetConfirmation = false
    @Published var showingExportSheet = false
    @Published var showingImportSheet = false
    
    // MARK: - Account Information
    
    @Published var currentUser: UserProfile?
    @Published var accountInfo: AccountInformation?
    @Published var subscriptionInfo: SubscriptionInfo?
    
    // MARK: - Security Status
    
    @Published var biometricAvailable = false
    @Published var biometricType: BiometricType = .none
    @Published var lastLoginDate: Date?
    @Published var loginAttempts: Int = 0
    
    // MARK: - Data Management
    
    @Published var cacheSize: Int = 0
    @Published var dataUsageStats: DataUsageStats?
    @Published var backupDate: Date?
    
    // Services
    private let settingsService: SettingsService
    private let securityService: SecurityService
    private let accountService: AccountService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        settingsService: SettingsService = DefaultSettingsService(),
        securityService: SecurityService = DefaultSecurityService(),
        accountService: AccountService = DefaultAccountService()
    ) {
        self.settingsService = settingsService
        self.securityService = securityService
        self.accountService = accountService
        
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Data Loading
    
    func loadSettings() async {
        isLoading = true
        error = nil
        
        do {
            async let userTask = loadUserProfile()
            async let accountTask = loadAccountInformation()
            async let securityTask = loadSecurityStatus()
            async let dataTask = loadDataUsageStats()
            
            await userTask
            await accountTask
            await securityTask
            await dataTask
            
        } catch {
            self.error = SettingsError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    private func loadUserProfile() async {
        do {
            currentUser = try await accountService.getUserProfile()
        } catch {
            print("Failed to load user profile: \(error)")
        }
    }
    
    private func loadAccountInformation() async {
        do {
            accountInfo = try await accountService.getAccountInformation()
            subscriptionInfo = try await accountService.getSubscriptionInfo()
        } catch {
            print("Failed to load account information: \(error)")
        }
    }
    
    private func loadSecurityStatus() async {
        do {
            let biometricStatus = try await securityService.getBiometricAvailability()
            biometricAvailable = biometricStatus.available
            biometricType = biometricStatus.type
            
            let securityInfo = try await securityService.getSecurityInfo()
            lastLoginDate = securityInfo.lastLoginDate
            loginAttempts = securityInfo.failedAttempts
            
        } catch {
            print("Failed to load security status: \(error)")
        }
    }
    
    private func loadDataUsageStats() async {
        do {
            dataUsageStats = try await settingsService.getDataUsageStats()
            cacheSize = try await settingsService.getCacheSize()
            backupDate = try await settingsService.getLastBackupDate()
        } catch {
            print("Failed to load data usage stats: \(error)")
        }
    }
    
    // MARK: - Settings Management
    
    func updateUserProfile(_ profile: UserProfile) async {
        do {
            try await accountService.updateUserProfile(profile)
            currentUser = profile
            
            // Update user settings
            userSettings.displayName = profile.displayName
            userSettings.emailAddress = profile.email
            
        } catch {
            self.error = SettingsError.updateFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func updateNotificationSettings() async {
        do {
            try await settingsService.updateNotificationSettings(
                enabled: userSettings.notificationsEnabled,
                priceAlerts: userSettings.priceAlertsEnabled,
                orderUpdates: userSettings.orderUpdatesEnabled,
                marketNews: userSettings.marketNewsEnabled,
                portfolioUpdates: userSettings.portfolioUpdatesEnabled,
                researchReports: userSettings.researchReportsEnabled
            )
        } catch {
            self.error = SettingsError.updateFailed("Failed to update notification settings")
            self.showingError = true
        }
    }
    
    func updateTradingPreferences() async {
        do {
            let preferences = TradingPreferences(
                defaultOrderType: OrderType(rawValue: userSettings.defaultOrderType) ?? .market,
                defaultTimeInForce: TimeInForce(rawValue: userSettings.defaultTimeInForce) ?? .day,
                autoConfirmOrders: userSettings.autoConfirmOrders,
                enableFractionalShares: userSettings.enableFractionalShares,
                defaultQuantity: userSettings.defaultQuantity,
                enableExtendedHours: userSettings.enableExtendedHours
            )
            
            try await settingsService.updateTradingPreferences(preferences)
            
        } catch {
            self.error = SettingsError.updateFailed("Failed to update trading preferences")
            self.showingError = true
        }
    }
    
    func updateRiskSettings() async {
        do {
            let riskSettings = RiskSettings(
                profile: RiskProfile(rawValue: userSettings.riskProfile) ?? .moderate,
                maxPositionSize: userSettings.maxPositionSize,
                maxDailyLoss: userSettings.maxDailyLoss,
                enableStopLosses: userSettings.enableStopLosses,
                defaultStopLossPercent: userSettings.defaultStopLossPercent,
                enablePositionSizing: userSettings.enablePositionSizing
            )
            
            try await settingsService.updateRiskSettings(riskSettings)
            
        } catch {
            self.error = SettingsError.updateFailed("Failed to update risk settings")
            self.showingError = true
        }
    }
    
    // MARK: - Security Management
    
    func enableBiometricAuth() async {
        do {
            let success = try await securityService.enableBiometricAuth()
            if success {
                userSettings.biometricAuthEnabled = true
            } else {
                throw SettingsError.securityError("Failed to enable biometric authentication")
            }
        } catch {
            self.error = error as? SettingsError ?? SettingsError.securityError(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func disableBiometricAuth() async {
        do {
            try await securityService.disableBiometricAuth()
            userSettings.biometricAuthEnabled = false
        } catch {
            self.error = SettingsError.securityError("Failed to disable biometric authentication")
            self.showingError = true
        }
    }
    
    func enableTwoFactorAuth() async {
        do {
            let success = try await securityService.enableTwoFactorAuth()
            if success {
                userSettings.twoFactorEnabled = true
            } else {
                throw SettingsError.securityError("Failed to enable two-factor authentication")
            }
        } catch {
            self.error = error as? SettingsError ?? SettingsError.securityError(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async {
        do {
            try await securityService.changePassword(current: currentPassword, new: newPassword)
        } catch {
            self.error = SettingsError.securityError("Failed to change password")
            self.showingError = true
        }
    }
    
    // MARK: - Data Management
    
    func clearCache() async {
        do {
            try await settingsService.clearCache()
            cacheSize = 0
        } catch {
            self.error = SettingsError.dataError("Failed to clear cache")
            self.showingError = true
        }
    }
    
    func exportSettings() async -> URL? {
        do {
            return try await settingsService.exportSettings(userSettings.exportSettings())
        } catch {
            self.error = SettingsError.exportError("Failed to export settings")
            self.showingError = true
            return nil
        }
    }
    
    func importSettings(from url: URL) async {
        do {
            let settings = try await settingsService.importSettings(from: url)
            userSettings.importSettings(settings)
        } catch {
            self.error = SettingsError.importError("Failed to import settings")
            self.showingError = true
        }
    }
    
    func createBackup() async {
        do {
            try await settingsService.createBackup()
            backupDate = Date()
        } catch {
            self.error = SettingsError.dataError("Failed to create backup")
            self.showingError = true
        }
    }
    
    // MARK: - Reset & Restore
    
    func resetAllSettings() {
        userSettings.resetToDefaults()
        showingResetConfirmation = false
        
        // Reload default data
        Task {
            await loadSettings()
        }
    }
    
    func resetSection(_ section: SettingsSection) {
        switch section {
        case .trading:
            resetTradingSettings()
        case .risk:
            resetRiskSettings()
        case .display:
            resetDisplaySettings()
        case .notifications:
            resetNotificationSettings()
        case .privacy:
            resetPrivacySettings()
        default:
            break
        }
    }
    
    private func resetTradingSettings() {
        userSettings.defaultOrderType = OrderType.market.rawValue
        userSettings.defaultTimeInForce = TimeInForce.day.rawValue
        userSettings.autoConfirmOrders = false
        userSettings.enableFractionalShares = true
        userSettings.defaultQuantity = 1
        userSettings.enableExtendedHours = false
    }
    
    private func resetRiskSettings() {
        userSettings.riskProfile = RiskProfile.moderate.rawValue
        userSettings.maxPositionSize = 0.10
        userSettings.maxDailyLoss = 0.05
        userSettings.enableStopLosses = true
        userSettings.defaultStopLossPercent = 0.08
        userSettings.enablePositionSizing = true
    }
    
    private func resetDisplaySettings() {
        userSettings.theme = AppTheme.dark.rawValue
        userSettings.colorScheme = ColorScheme.blue.rawValue
        userSettings.showAfterHours = true
        userSettings.showExtendedQuotes = false
        userSettings.defaultChartType = ChartDisplayType.candlestick.rawValue
        userSettings.priceFormat = PriceFormat.currency.rawValue
        userSettings.percentFormat = PercentFormat.decimal.rawValue
    }
    
    private func resetNotificationSettings() {
        userSettings.notificationsEnabled = true
        userSettings.priceAlertsEnabled = true
        userSettings.orderUpdatesEnabled = true
        userSettings.marketNewsEnabled = false
        userSettings.portfolioUpdatesEnabled = true
        userSettings.researchReportsEnabled = false
        userSettings.notificationSounds = true
    }
    
    private func resetPrivacySettings() {
        userSettings.analyticsEnabled = true
        userSettings.crashReporting = true
        userSettings.usageStatistics = false
        userSettings.personalizationEnabled = true
    }
    
    // MARK: - Validation
    
    func validateSettings() -> [SettingsValidationError] {
        var errors: [SettingsValidationError] = []
        
        // Validate email format
        if !userSettings.emailAddress.isEmpty && !isValidEmail(userSettings.emailAddress) {
            errors.append(.invalidEmail)
        }
        
        // Validate risk settings
        if userSettings.maxPositionSize <= 0 || userSettings.maxPositionSize > 1.0 {
            errors.append(.invalidRiskSetting("Max position size must be between 0% and 100%"))
        }
        
        if userSettings.maxDailyLoss <= 0 || userSettings.maxDailyLoss > 0.5 {
            errors.append(.invalidRiskSetting("Max daily loss must be between 0% and 50%"))
        }
        
        if userSettings.defaultStopLossPercent <= 0 || userSettings.defaultStopLossPercent > 1.0 {
            errors.append(.invalidRiskSetting("Default stop loss must be between 0% and 100%"))
        }
        
        // Validate auto logout time
        if userSettings.autoLogoutMinutes < 5 || userSettings.autoLogoutMinutes > 480 {
            errors.append(.invalidSecuritySetting("Auto logout must be between 5 and 480 minutes"))
        }
        
        return errors
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Helper Methods
    
    private func setupBindings() {
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        Task {
            await loadSettings()
        }
    }
    
    func dismissError() {
        error = nil
        showingError = false
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Supporting Models

struct UserProfile: Codable {
    let id: String
    let displayName: String
    let email: String
    let firstName: String
    let lastName: String
    let phoneNumber: String?
    let profileImageURL: String?
    let dateJoined: Date
    let lastLoginDate: Date?
    let isVerified: Bool
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

struct AccountInformation: Codable {
    let accountId: String
    let accountType: AccountType
    let accountStatus: AccountStatus
    let tradingLevel: TradingLevel
    let createdDate: Date
    let lastModifiedDate: Date
    let dayTradingBuyingPower: Decimal
    let overnightBuyingPower: Decimal
    let cashBalance: Decimal
    let marketValue: Decimal
    let totalEquity: Decimal
    
    enum AccountStatus: String, Codable {
        case active = "active"
        case suspended = "suspended"
        case closed = "closed"
        case pending = "pending"
    }
    
    enum TradingLevel: String, Codable, CaseIterable {
        case level0 = "level0" // Cash only
        case level1 = "level1" // Cash + covered calls/puts
        case level2 = "level2" // Level 1 + long options
        case level3 = "level3" // Level 2 + spreads
        case level4 = "level4" // Level 3 + naked options
    }
}

struct SubscriptionInfo: Codable {
    let plan: SubscriptionPlan
    let status: SubscriptionStatus
    let startDate: Date
    let endDate: Date?
    let autoRenew: Bool
    let features: [String]
    let monthlyPrice: Decimal
    
    enum SubscriptionPlan: String, Codable {
        case free = "free"
        case basic = "basic"
        case premium = "premium"
        case professional = "professional"
    }
    
    enum SubscriptionStatus: String, Codable {
        case active = "active"
        case expired = "expired"
        case cancelled = "cancelled"
        case trial = "trial"
    }
}

struct BiometricStatus {
    let available: Bool
    let type: BiometricType
}

enum BiometricType {
    case none
    case touchID
    case faceID
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }
}

struct SecurityInfo {
    let lastLoginDate: Date?
    let failedAttempts: Int
    let isLocked: Bool
    let lockoutEndTime: Date?
}

struct DataUsageStats {
    let totalDataUsed: Int // bytes
    let cacheSize: Int
    let lastCleared: Date?
    let quotesConsumed: Int
    let apiCallsThisMonth: Int
    let avgDailyUsage: Int
}

struct TradingPreferences {
    let defaultOrderType: OrderType
    let defaultTimeInForce: TimeInForce
    let autoConfirmOrders: Bool
    let enableFractionalShares: Bool
    let defaultQuantity: Int
    let enableExtendedHours: Bool
}

struct RiskSettings {
    let profile: RiskProfile
    let maxPositionSize: Double
    let maxDailyLoss: Double
    let enableStopLosses: Bool
    let defaultStopLossPercent: Double
    let enablePositionSizing: Bool
}

// MARK: - Settings Sections

enum SettingsSection: String, CaseIterable {
    case account = "Account"
    case trading = "Trading"
    case risk = "Risk Management"
    case display = "Display"
    case notifications = "Notifications"
    case privacy = "Privacy & Data"
    case security = "Security"
    case accessibility = "Accessibility"
    case advanced = "Advanced"
    
    var systemImage: String {
        switch self {
        case .account: return "person.circle"
        case .trading: return "chart.line.uptrend.xyaxis"
        case .risk: return "shield.fill"
        case .display: return "display"
        case .notifications: return "bell.fill"
        case .privacy: return "lock.shield"
        case .security: return "key.fill"
        case .accessibility: return "accessibility"
        case .advanced: return "gearshape.2.fill"
        }
    }
}

// MARK: - Error Types

enum SettingsError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case updateFailed(String)
    case securityError(String)
    case dataError(String)
    case exportError(String)
    case importError(String)
    case validationError([SettingsValidationError])
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .updateFailed(let message),
             .securityError(let message),
             .dataError(let message),
             .exportError(let message),
             .importError(let message):
            return message
        case .validationError(let errors):
            return errors.map { $0.localizedDescription }.joined(separator: ", ")
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load settings: \(message)"
        case .updateFailed(let message):
            return "Failed to update settings: \(message)"
        case .securityError(let message):
            return "Security error: \(message)"
        case .dataError(let message):
            return "Data error: \(message)"
        case .exportError(let message):
            return "Export error: \(message)"
        case .importError(let message):
            return "Import error: \(message)"
        case .validationError(let errors):
            return "Validation errors: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
        }
    }
}

enum SettingsValidationError: LocalizedError {
    case invalidEmail
    case invalidRiskSetting(String)
    case invalidSecuritySetting(String)
    case invalidDisplaySetting(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Invalid email address format"
        case .invalidRiskSetting(let message):
            return message
        case .invalidSecuritySetting(let message):
            return message
        case .invalidDisplaySetting(let message):
            return message
        }
    }
}