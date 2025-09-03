//
//  OnboardingViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedExperience: TradingExperience = .beginner
    @Published var selectedRiskProfile: RiskProfile = .moderate
    @Published var notificationPreferences: [OnboardingNotificationType: Bool] = [:]
    @Published var displayName: String = ""
    @Published var email: String = ""
    
    // MARK: - State
    @Published var isLoading = false
    @Published var error: OnboardingError?
    @Published var showingError = false
    
    // Services
    private let onboardingService: OnboardingService
    private let userSettings = UserSettings.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init(onboardingService: DefaultOnboardingService = DefaultOnboardingService()) {
        self.onboardingService = onboardingService
        setupInitialPreferences()
        setupBindings()
    }
    
    // MARK: - Onboarding Completion
    
    func completeOnboarding() {
        isLoading = true
        
        Task {
            do {
                try await saveOnboardingData()
                try await applyUserPreferences()
                
                // Mark onboarding as complete
                UserDefaults.standard.set(true, forKey: "onboarding_completed")
                UserDefaults.standard.set(Date(), forKey: "onboarding_completed_date")
                
                await MainActor.run {
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.error = OnboardingError.saveFailed(error.localizedDescription)
                    self.showingError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveOnboardingData() async throws {
        let onboardingData = OnboardingData(
            experience: selectedExperience,
            riskProfile: selectedRiskProfile,
            notificationPreferences: notificationPreferences,
            displayName: displayName,
            email: email,
            completedAt: Date()
        )
        
        try await onboardingService.saveOnboardingData(onboardingData)
    }
    
    private func applyUserPreferences() async throws {
        // Apply trading experience settings
        applyTradingExperienceSettings()
        
        // Apply risk profile settings
        applyRiskProfileSettings()
        
        // Apply notification preferences
        applyNotificationPreferences()
        
        // Apply user profile settings
        applyUserProfileSettings()
        
        // Set theme based on preferences
        applyThemeSettings()
    }
    
    // MARK: - Settings Application
    
    private func applyTradingExperienceSettings() {
        switch selectedExperience {
        case .beginner:
            userSettings.autoConfirmOrders = false
            userSettings.enableExtendedHours = false
            userSettings.defaultOrderType = OrderType.market.rawValue
            userSettings.showExtendedQuotes = false
            
        case .intermediate:
            userSettings.autoConfirmOrders = false
            userSettings.enableExtendedHours = true
            userSettings.defaultOrderType = OrderType.limit.rawValue
            userSettings.showExtendedQuotes = true
            
        case .advanced:
            userSettings.autoConfirmOrders = true
            userSettings.enableExtendedHours = true
            userSettings.defaultOrderType = OrderType.limit.rawValue
            userSettings.showExtendedQuotes = true
            userSettings.enableFractionalShares = true
            
        case .expert:
            userSettings.autoConfirmOrders = true
            userSettings.enableExtendedHours = true
            userSettings.defaultOrderType = OrderType.stopLimit.rawValue
            userSettings.showExtendedQuotes = true
            userSettings.enableFractionalShares = true
            userSettings.betaFeatures = true
        }
    }
    
    private func applyRiskProfileSettings() {
        userSettings.riskProfile = selectedRiskProfile.rawValue
        
        switch selectedRiskProfile {
        case .conservative:
            userSettings.maxPositionSize = 0.05 // 5%
            userSettings.maxDailyLoss = 0.02 // 2%
            userSettings.enableStopLosses = true
            userSettings.defaultStopLossPercent = 0.05 // 5%
            userSettings.enablePositionSizing = true
            
        case .moderate:
            userSettings.maxPositionSize = 0.10 // 10%
            userSettings.maxDailyLoss = 0.05 // 5%
            userSettings.enableStopLosses = true
            userSettings.defaultStopLossPercent = 0.08 // 8%
            userSettings.enablePositionSizing = true
            
        case .aggressive:
            userSettings.maxPositionSize = 0.20 // 20%
            userSettings.maxDailyLoss = 0.10 // 10%
            userSettings.enableStopLosses = false
            userSettings.defaultStopLossPercent = 0.15 // 15%
            userSettings.enablePositionSizing = false
            
        case .custom:
            // For custom profiles, use moderate defaults
            userSettings.maxPositionSize = 0.10 // 10%
            userSettings.maxDailyLoss = 0.05 // 5%
            userSettings.enableStopLosses = true
            userSettings.defaultStopLossPercent = 0.08 // 8%
            userSettings.enablePositionSizing = true
        }
    }
    
    private func applyNotificationPreferences() {
        userSettings.notificationsEnabled = true
        userSettings.priceAlertsEnabled = notificationPreferences[.priceAlerts] ?? true
        userSettings.orderUpdatesEnabled = notificationPreferences[.orderUpdates] ?? true
        userSettings.portfolioUpdatesEnabled = notificationPreferences[.portfolioUpdates] ?? true
        userSettings.marketNewsEnabled = notificationPreferences[.marketNews] ?? false
        userSettings.researchReportsEnabled = notificationPreferences[.researchReports] ?? false
    }
    
    private func applyUserProfileSettings() {
        if !displayName.isEmpty {
            userSettings.displayName = displayName
        }
        
        if !email.isEmpty {
            userSettings.emailAddress = email
        }
    }
    
    private func applyThemeSettings() {
        // Default to dark theme for tvOS
        userSettings.theme = AppTheme.dark.rawValue
        userSettings.colorScheme = ColorScheme.blue.rawValue
        
        // Adjust based on risk profile
        switch selectedRiskProfile {
        case .conservative:
            userSettings.colorScheme = ColorScheme.green.rawValue
        case .moderate:
            userSettings.colorScheme = ColorScheme.blue.rawValue
        case .aggressive:
            userSettings.colorScheme = ColorScheme.red.rawValue
        case .custom:
            userSettings.colorScheme = ColorScheme.blue.rawValue
        }
    }
    
    // MARK: - Validation
    
    func validateUserInput() -> [OnboardingValidationError] {
        var errors: [OnboardingValidationError] = []
        
        if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyDisplayName)
        }
        
        if !email.isEmpty && !isValidEmail(email) {
            errors.append(.invalidEmail)
        }
        
        return errors
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialPreferences() {
        // Set default notification preferences
        OnboardingNotificationType.allCases.forEach { type in
            notificationPreferences[type] = type.defaultEnabled
        }
    }
    
    private func setupBindings() {
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
            }
            .store(in: &cancellables)
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

enum OnboardingStepType: String, CaseIterable {
    case welcome = "welcome"
    case experience = "experience"
    case riskProfile = "risk_profile"
    case notifications = "notifications"
    case account = "account"
    case ready = "ready"
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .experience: return "Trading Experience"
        case .riskProfile: return "Risk Profile"
        case .notifications: return "Notifications"
        case .account: return "Account Setup"
        case .ready: return "Ready to Start"
        }
    }
}

enum TradingExperience: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "New to Trading"
        case .intermediate: return "Some Experience"
        case .advanced: return "Experienced Trader"
        case .expert: return "Professional/Expert"
        }
    }
    
    var description: String {
        switch self {
        case .beginner:
            return "I'm just getting started with investing and trading"
        case .intermediate:
            return "I have some experience with basic trades and market concepts"
        case .advanced:
            return "I'm comfortable with various trading strategies and market analysis"
        case .expert:
            return "I have extensive experience and use sophisticated trading techniques"
        }
    }
}

extension RiskProfile {
    var profileDescription: String {
        switch self {
        case .conservative:
            return "I prefer lower risk investments with steady, predictable returns. Capital preservation is my priority."
        case .moderate:
            return "I'm comfortable with some risk for potentially higher returns. I want a balanced approach."
        case .aggressive:
            return "I'm willing to accept higher risk for the potential of significant returns. I can handle volatility."
        case .custom:
            return "I prefer a customized risk approach tailored to my specific needs and preferences."
        }
    }
    
    var riskLevel: Int {
        switch self {
        case .conservative: return 2
        case .moderate: return 3
        case .aggressive: return 5
        case .custom: return 4
        }
    }
}

enum OnboardingNotificationType: String, CaseIterable, Codable {
    case priceAlerts = "price_alerts"
    case orderUpdates = "order_updates"
    case portfolioUpdates = "portfolio_updates"
    case marketNews = "market_news"
    case researchReports = "research_reports"
    
    var displayName: String {
        switch self {
        case .priceAlerts: return "Price Alerts"
        case .orderUpdates: return "Order Updates"
        case .portfolioUpdates: return "Portfolio Updates"
        case .marketNews: return "Market News"
        case .researchReports: return "Research Reports"
        }
    }
    
    var description: String {
        switch self {
        case .priceAlerts:
            return "Get notified when stocks reach your target prices"
        case .orderUpdates:
            return "Receive updates about your order status and fills"
        case .portfolioUpdates:
            return "Daily summaries of your portfolio performance"
        case .marketNews:
            return "Breaking news that might affect your holdings"
        case .researchReports:
            return "Analyst reports and investment recommendations"
        }
    }
    
    var icon: String {
        switch self {
        case .priceAlerts: return "bell.fill"
        case .orderUpdates: return "checkmark.circle.fill"
        case .portfolioUpdates: return "chart.bar.fill"
        case .marketNews: return "newspaper.fill"
        case .researchReports: return "doc.text.fill"
        }
    }
    
    var defaultEnabled: Bool {
        switch self {
        case .priceAlerts, .orderUpdates, .portfolioUpdates:
            return true
        case .marketNews, .researchReports:
            return false
        }
    }
}

struct OnboardingData: Codable {
    let experience: TradingExperience
    let riskProfile: RiskProfile
    let notificationPreferences: [OnboardingNotificationType: Bool]
    let displayName: String
    let email: String
    let completedAt: Date
}

// MARK: - Error Types

enum OnboardingError: LocalizedError, Identifiable {
    case saveFailed(String)
    case validationFailed([OnboardingValidationError])
    case networkError(String)
    
    var id: String {
        switch self {
        case .saveFailed(let message),
             .networkError(let message):
            return message
        case .validationFailed(let errors):
            return errors.map { $0.localizedDescription }.joined(separator: ", ")
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save onboarding data: \(message)"
        case .validationFailed(let errors):
            return "Validation errors: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

enum OnboardingValidationError: LocalizedError {
    case emptyDisplayName
    case invalidEmail
    case missingRequiredField(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyDisplayName:
            return "Display name is required"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .missingRequiredField(let field):
            return "\(field) is required"
        }
    }
}

// MARK: - Onboarding Service

protocol OnboardingService {
    func saveOnboardingData(_ data: OnboardingData) async throws
    func getOnboardingData() async throws -> OnboardingData?
    func hasCompletedOnboarding() -> Bool
}

class DefaultOnboardingService: OnboardingService {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var onboardingDataURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("onboarding_data.json")
    }
    
    func saveOnboardingData(_ data: OnboardingData) async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Save locally
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: onboardingDataURL)
        
        // In a real implementation, this would also sync with the server
        print("Onboarding data saved successfully")
    }
    
    func getOnboardingData() async throws -> OnboardingData? {
        guard FileManager.default.fileExists(atPath: onboardingDataURL.path) else {
            return nil
        }
        
        let jsonData = try Data(contentsOf: onboardingDataURL)
        return try decoder.decode(OnboardingData.self, from: jsonData)
    }
    
    func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: "onboarding_completed")
    }
}