//
//  SettingsService.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import Foundation

// MARK: - Service Protocols

protocol SettingsService {
    func updateNotificationSettings(enabled: Bool, priceAlerts: Bool, orderUpdates: Bool, marketNews: Bool, portfolioUpdates: Bool, researchReports: Bool) async throws
    func updateTradingPreferences(_ preferences: TradingPreferences) async throws
    func updateRiskSettings(_ settings: RiskSettings) async throws
    func getDataUsageStats() async throws -> DataUsageStats
    func getCacheSize() async throws -> Int
    func getLastBackupDate() async throws -> Date?
    func clearCache() async throws
    func exportSettings(_ settings: [String: Any]) async throws -> URL
    func importSettings(from url: URL) async throws -> [String: Any]
    func createBackup() async throws
}

protocol SecurityService {
    func getBiometricAvailability() async throws -> BiometricStatus
    func getSecurityInfo() async throws -> SecurityInfo
    func enableBiometricAuth() async throws -> Bool
    func disableBiometricAuth() async throws
    func enableTwoFactorAuth() async throws -> Bool
    func changePassword(current: String, new: String) async throws
}

protocol AccountService {
    func getUserProfile() async throws -> UserProfile
    func getAccountInformation() async throws -> AccountInformation
    func getSubscriptionInfo() async throws -> SubscriptionInfo
    func updateUserProfile(_ profile: UserProfile) async throws
}

// MARK: - Service Implementations

class DefaultSettingsService: SettingsService {
    
    func updateNotificationSettings(enabled: Bool, priceAlerts: Bool, orderUpdates: Bool, marketNews: Bool, portfolioUpdates: Bool, researchReports: Bool) async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 800_000_000)
        
        // Mock validation
        if Bool.random() && Bool.random() { // 25% failure rate
            throw SettingsError.updateFailed("Failed to update notification settings on server")
        }
        
        // In real implementation, would update server-side notification preferences
        print("Updated notification settings: enabled=\(enabled), priceAlerts=\(priceAlerts)")
    }
    
    func updateTradingPreferences(_ preferences: TradingPreferences) async throws {
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Validate trading preferences
        if preferences.defaultQuantity <= 0 {
            throw SettingsError.validationError([.invalidRiskSetting("Default quantity must be greater than 0")])
        }
        
        // Mock API call
        print("Updated trading preferences: orderType=\(preferences.defaultOrderType), timeInForce=\(preferences.defaultTimeInForce)")
    }
    
    func updateRiskSettings(_ settings: RiskSettings) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Validate risk settings
        var errors: [SettingsValidationError] = []
        
        if settings.maxPositionSize <= 0 || settings.maxPositionSize > 1.0 {
            errors.append(.invalidRiskSetting("Max position size must be between 0% and 100%"))
        }
        
        if settings.maxDailyLoss <= 0 || settings.maxDailyLoss > 0.5 {
            errors.append(.invalidRiskSetting("Max daily loss must be between 0% and 50%"))
        }
        
        if settings.defaultStopLossPercent <= 0 || settings.defaultStopLossPercent > 1.0 {
            errors.append(.invalidRiskSetting("Default stop loss must be between 0% and 100%"))
        }
        
        if !errors.isEmpty {
            throw SettingsError.validationError(errors)
        }
        
        print("Updated risk settings: profile=\(settings.profile), maxPosition=\(settings.maxPositionSize)")
    }
    
    func getDataUsageStats() async throws -> DataUsageStats {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return DataUsageStats(
            totalDataUsed: Int.random(in: 50_000_000...500_000_000), // 50MB - 500MB
            cacheSize: Int.random(in: 20...150), // MB
            lastCleared: Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...30), to: Date()),
            quotesConsumed: Int.random(in: 5000...50000),
            apiCallsThisMonth: Int.random(in: 10000...100000),
            avgDailyUsage: Int.random(in: 1_000_000...10_000_000) // bytes
        )
    }
    
    func getCacheSize() async throws -> Int {
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Mock cache size calculation
        return Int.random(in: 20...150) // MB
    }
    
    func getLastBackupDate() async throws -> Date? {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock last backup date
        return Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...14), to: Date())
    }
    
    func clearCache() async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Mock cache clearing process
        if Bool.random() && Bool.random() && Bool.random() { // 12.5% failure rate
            throw SettingsError.dataError("Failed to clear cache: Permission denied")
        }
        
        print("Cache cleared successfully")
    }
    
    func exportSettings(_ settings: [String: Any]) async throws -> URL {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = documentsPath.appendingPathComponent("hingetrade_settings_\(Date().timeIntervalSince1970).json")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
            try jsonData.write(to: exportURL)
            return exportURL
        } catch {
            throw SettingsError.exportError("Failed to export settings: \(error.localizedDescription)")
        }
    }
    
    func importSettings(from url: URL) async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        do {
            let data = try Data(contentsOf: url)
            if let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return settings
            } else {
                throw SettingsError.importError("Invalid settings file format")
            }
        } catch {
            throw SettingsError.importError("Failed to import settings: \(error.localizedDescription)")
        }
    }
    
    func createBackup() async throws {
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        // Mock backup creation
        if Bool.random() && Bool.random() { // 25% failure rate
            throw SettingsError.dataError("Backup failed: Insufficient cloud storage")
        }
        
        print("Backup created successfully")
    }
}

class DefaultSecurityService: SecurityService {
    
    func getBiometricAvailability() async throws -> BiometricStatus {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock biometric availability check
        let available = Bool.random()
        let type: BiometricType = available ? (Bool.random() ? .faceID : .touchID) : .none
        
        return BiometricStatus(available: available, type: type)
    }
    
    func getSecurityInfo() async throws -> SecurityInfo {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        return SecurityInfo(
            lastLoginDate: Calendar.current.date(byAdding: .hour, value: -Int.random(in: 1...48), to: Date()),
            failedAttempts: Int.random(in: 0...3),
            isLocked: false,
            lockoutEndTime: nil
        )
    }
    
    func enableBiometricAuth() async throws -> Bool {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Mock biometric authentication setup
        if Bool.random() && Bool.random() && Bool.random() { // 12.5% failure rate
            throw SettingsError.securityError("Biometric authentication setup failed")
        }
        
        return true
    }
    
    func disableBiometricAuth() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        print("Biometric authentication disabled")
    }
    
    func enableTwoFactorAuth() async throws -> Bool {
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        // Mock 2FA setup process
        if Bool.random() && Bool.random() { // 25% failure rate
            throw SettingsError.securityError("Two-factor authentication setup failed")
        }
        
        return true
    }
    
    func changePassword(current: String, new: String) async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Mock password validation
        if current.isEmpty || new.isEmpty {
            throw SettingsError.securityError("Password cannot be empty")
        }
        
        if new.count < 8 {
            throw SettingsError.securityError("New password must be at least 8 characters")
        }
        
        if current == "wrong_password" {
            throw SettingsError.securityError("Current password is incorrect")
        }
        
        print("Password changed successfully")
    }
}

class DefaultAccountService: AccountService {
    
    func getUserProfile() async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        return UserProfile(
            id: "user_123",
            displayName: "John Doe",
            email: "john.doe@example.com",
            firstName: "John",
            lastName: "Doe",
            phoneNumber: "+1 (555) 123-4567",
            profileImageURL: nil,
            dateJoined: Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date(),
            lastLoginDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
            isVerified: true
        )
    }
    
    func getAccountInformation() async throws -> AccountInformation {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return AccountInformation(
            accountId: "ACC_789",
            accountType: .individual,
            accountStatus: .active,
            tradingLevel: .level2,
            createdDate: Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date(),
            lastModifiedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            dayTradingBuyingPower: Decimal(25000),
            overnightBuyingPower: Decimal(50000),
            cashBalance: Decimal(12500),
            marketValue: Decimal(87500),
            totalEquity: Decimal(100000)
        )
    }
    
    func getSubscriptionInfo() async throws -> SubscriptionInfo {
        try await Task.sleep(nanoseconds: 600_000_000)
        
        return SubscriptionInfo(
            plan: .premium,
            status: .active,
            startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            autoRenew: true,
            features: [
                "Real-time market data",
                "Advanced charting tools",
                "Options trading",
                "Extended hours trading",
                "Priority customer support"
            ],
            monthlyPrice: Decimal(29.99)
        )
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        
        // Mock profile validation
        if profile.displayName.isEmpty {
            throw SettingsError.validationError([.invalidDisplaySetting("Display name cannot be empty")])
        }
        
        if profile.email.isEmpty {
            throw SettingsError.validationError([.invalidEmail])
        }
        
        // Email format validation
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        if !emailPred.evaluate(with: profile.email) {
            throw SettingsError.validationError([.invalidEmail])
        }
        
        print("User profile updated: \(profile.displayName), \(profile.email)")
    }
}

// MARK: - Mock Data Helpers

extension DefaultSettingsService {
    
    func generateMockDataUsage() -> DataUsageStats {
        return DataUsageStats(
            totalDataUsed: Int.random(in: 100_000_000...1_000_000_000),
            cacheSize: Int.random(in: 50...200),
            lastCleared: Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...7), to: Date()),
            quotesConsumed: Int.random(in: 10000...100000),
            apiCallsThisMonth: Int.random(in: 50000...500000),
            avgDailyUsage: Int.random(in: 5_000_000...50_000_000)
        )
    }
}

extension DefaultSecurityService {
    
    func generateMockSecurityStatus() -> SecurityInfo {
        return SecurityInfo(
            lastLoginDate: Calendar.current.date(byAdding: .hour, value: -Int.random(in: 1...72), to: Date()),
            failedAttempts: Int.random(in: 0...5),
            isLocked: Bool.random() && Bool.random() && Bool.random(), // 12.5% chance
            lockoutEndTime: Bool.random() ? Calendar.current.date(byAdding: .minute, value: Int.random(in: 5...60), to: Date()) : nil
        )
    }
}

extension DefaultAccountService {
    
    func generateMockUserProfile() -> UserProfile {
        let firstNames = ["John", "Jane", "Michael", "Sarah", "David", "Emily", "Robert", "Lisa"]
        let lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis"]
        
        let firstName = firstNames.randomElement() ?? "John"
        let lastName = lastNames.randomElement() ?? "Doe"
        
        return UserProfile(
            id: "user_\(UUID().uuidString.prefix(8))",
            displayName: "\(firstName) \(lastName)",
            email: "\(firstName.lowercased()).\(lastName.lowercased())@example.com",
            firstName: firstName,
            lastName: lastName,
            phoneNumber: "+1 (555) \(String(format: "%03d", Int.random(in: 100...999)))-\(String(format: "%04d", Int.random(in: 1000...9999)))",
            profileImageURL: nil,
            dateJoined: Calendar.current.date(byAdding: .month, value: -Int.random(in: 1...24), to: Date()) ?? Date(),
            lastLoginDate: Calendar.current.date(byAdding: .hour, value: -Int.random(in: 1...48), to: Date()),
            isVerified: Bool.random()
        )
    }
    
    func generateMockAccountInfo() -> AccountInformation {
        return AccountInformation(
            accountId: "ACC_\(String(format: "%06d", Int.random(in: 100000...999999)))",
            accountType: AccountType.allCases.randomElement() ?? .individual,
            accountStatus: .active,
            tradingLevel: AccountInformation.TradingLevel.allCases.randomElement() ?? .level2,
            createdDate: Calendar.current.date(byAdding: .month, value: -Int.random(in: 1...36), to: Date()) ?? Date(),
            lastModifiedDate: Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...30), to: Date()) ?? Date(),
            dayTradingBuyingPower: Decimal(Double.random(in: 10000...100000)),
            overnightBuyingPower: Decimal(Double.random(in: 20000...200000)),
            cashBalance: Decimal(Double.random(in: 1000...50000)),
            marketValue: Decimal(Double.random(in: 50000...500000)),
            totalEquity: Decimal(Double.random(in: 60000...550000))
        )
    }
    
    func generateMockSubscriptionInfo() -> SubscriptionInfo {
        let plans: [SubscriptionInfo.SubscriptionPlan] = [.free, .basic, .premium, .professional]
        let plan = plans.randomElement() ?? .free
        
        return SubscriptionInfo(
            plan: plan,
            status: .active,
            startDate: Calendar.current.date(byAdding: .month, value: -Int.random(in: 1...12), to: Date()) ?? Date(),
            endDate: plan == .free ? nil : Calendar.current.date(byAdding: .month, value: Int.random(in: 1...12), to: Date()),
            autoRenew: Bool.random(),
            features: getPlanFeatures(plan),
            monthlyPrice: getPlanPrice(plan)
        )
    }
    
    private func getPlanFeatures(_ plan: SubscriptionInfo.SubscriptionPlan) -> [String] {
        switch plan {
        case .free:
            return ["Basic market data", "Limited watchlists", "Community support"]
        case .basic:
            return ["Real-time quotes", "Advanced charts", "Email support", "Extended watchlists"]
        case .premium:
            return ["All Basic features", "Options trading", "Extended hours", "Priority support", "Advanced analytics"]
        case .professional:
            return ["All Premium features", "API access", "Custom indicators", "Dedicated support", "Advanced reporting"]
        }
    }
    
    private func getPlanPrice(_ plan: SubscriptionInfo.SubscriptionPlan) -> Decimal {
        switch plan {
        case .free: return 0
        case .basic: return 9.99
        case .premium: return 29.99
        case .professional: return 99.99
        }
    }
}