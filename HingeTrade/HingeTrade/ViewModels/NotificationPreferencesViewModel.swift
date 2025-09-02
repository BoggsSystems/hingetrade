//
//  NotificationPreferencesViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine
import UserNotifications

@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    // MARK: - General Settings
    @Published var notificationsEnabled = false
    @Published var soundEnabled = true
    @Published var badgeEnabled = true
    @Published var notificationStyle: NotificationStyle = .banner
    
    // MARK: - Price Alerts Settings
    @Published var priceAlertsEnabled = true
    @Published var priceCheckFrequency = 0 // 0 = Real-time, 1 = 5min, etc.
    @Published var enabledAlertTypes: Set<String> = ["priceAbove", "priceBelow", "percentChange", "volumeSpike"]
    
    // MARK: - Order Settings
    @Published var orderFillsEnabled = true
    @Published var partialFillsEnabled = true
    @Published var orderRejectionsEnabled = true
    @Published var minimumOrderValue: Decimal = 100
    
    // MARK: - Creator Settings
    @Published var creatorContentEnabled = true
    @Published var liveStreamsEnabled = true
    @Published var enabledContentTypes: Set<String> = ["tradingVideos", "marketAnalysis", "educational", "liveTrading"]
    
    // MARK: - News Settings
    @Published var marketNewsEnabled = true
    @Published var breakingNewsOnly = false
    @Published var enabledNewsCategories: Set<String> = ["earnings", "economicData", "companyNews", "marketMovers", "regulatory"]
    
    // MARK: - Schedule Settings
    @Published var doNotDisturbEnabled = false
    @Published var quietHoursStart = Date()
    @Published var quietHoursEnd = Date()
    @Published var weekendNotificationsEnabled = false
    @Published var tradingHoursOnly = false
    
    // MARK: - State
    @Published var isLoading = false
    @Published var error: PreferencesError?
    @Published var showingError = false
    
    // Services
    private let notificationService: NotificationService
    private let preferencesService: PreferencesService
    
    private var cancellables = Set<AnyCancellable>()
    
    enum NotificationStyle: Int, CaseIterable {
        case banner = 0
        case alert = 1
        case none = 2
        
        var displayName: String {
            switch self {
            case .banner: return "Banner"
            case .alert: return "Alert"
            case .none: return "None"
            }
        }
    }
    
    init(
        notificationService: NotificationService = NotificationService.shared,
        preferencesService: PreferencesService = PreferencesService()
    ) {
        self.notificationService = notificationService
        self.preferencesService = preferencesService
        
        setupBindings()
        setupDefaultTimes()
    }
    
    // MARK: - Data Loading
    
    func loadPreferences() async {
        isLoading = true
        error = nil
        
        do {
            // Check system notification authorization
            await notificationService.checkAuthorizationStatus()
            notificationsEnabled = notificationService.isAuthorized
            
            // Load saved preferences
            let preferences = try await preferencesService.getPreferences()
            await updateFromPreferences(preferences)
            
        } catch {
            self.error = PreferencesError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    private func updateFromPreferences(_ preferences: NotificationPreferences) async {
        // General
        soundEnabled = preferences.soundEnabled
        badgeEnabled = preferences.badgeEnabled
        notificationStyle = NotificationStyle(rawValue: preferences.notificationStyle) ?? .banner
        
        // Price Alerts
        priceAlertsEnabled = preferences.priceAlertsEnabled
        priceCheckFrequency = preferences.priceCheckFrequency
        enabledAlertTypes = preferences.enabledAlertTypes
        
        // Orders
        orderFillsEnabled = preferences.orderFillsEnabled
        partialFillsEnabled = preferences.partialFillsEnabled
        orderRejectionsEnabled = preferences.orderRejectionsEnabled
        minimumOrderValue = preferences.minimumOrderValue
        
        // Creators
        creatorContentEnabled = preferences.creatorContentEnabled
        liveStreamsEnabled = preferences.liveStreamsEnabled
        enabledContentTypes = preferences.enabledContentTypes
        
        // News
        marketNewsEnabled = preferences.marketNewsEnabled
        breakingNewsOnly = preferences.breakingNewsOnly
        enabledNewsCategories = preferences.enabledNewsCategories
        
        // Schedule
        doNotDisturbEnabled = preferences.doNotDisturbEnabled
        quietHoursStart = preferences.quietHoursStart
        quietHoursEnd = preferences.quietHoursEnd
        weekendNotificationsEnabled = preferences.weekendNotificationsEnabled
        tradingHoursOnly = preferences.tradingHoursOnly
    }
    
    // MARK: - Preferences Management
    
    func savePreferences() async {
        do {
            let preferences = NotificationPreferences(
                // General
                soundEnabled: soundEnabled,
                badgeEnabled: badgeEnabled,
                notificationStyle: notificationStyle.rawValue,
                
                // Price Alerts
                priceAlertsEnabled: priceAlertsEnabled,
                priceCheckFrequency: priceCheckFrequency,
                enabledAlertTypes: enabledAlertTypes,
                
                // Orders
                orderFillsEnabled: orderFillsEnabled,
                partialFillsEnabled: partialFillsEnabled,
                orderRejectionsEnabled: orderRejectionsEnabled,
                minimumOrderValue: minimumOrderValue,
                
                // Creators
                creatorContentEnabled: creatorContentEnabled,
                liveStreamsEnabled: liveStreamsEnabled,
                enabledContentTypes: enabledContentTypes,
                
                // News
                marketNewsEnabled: marketNewsEnabled,
                breakingNewsOnly: breakingNewsOnly,
                enabledNewsCategories: enabledNewsCategories,
                
                // Schedule
                doNotDisturbEnabled: doNotDisturbEnabled,
                quietHoursStart: quietHoursStart,
                quietHoursEnd: quietHoursEnd,
                weekendNotificationsEnabled: weekendNotificationsEnabled,
                tradingHoursOnly: tradingHoursOnly
            )
            
            try await preferencesService.savePreferences(preferences)
            
        } catch {
            self.error = PreferencesError.savingFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func resetToDefaults() {
        // General
        soundEnabled = true
        badgeEnabled = true
        notificationStyle = .banner
        
        // Price Alerts
        priceAlertsEnabled = true
        priceCheckFrequency = 0
        enabledAlertTypes = ["priceAbove", "priceBelow", "percentChange", "volumeSpike"]
        
        // Orders
        orderFillsEnabled = true
        partialFillsEnabled = true
        orderRejectionsEnabled = true
        minimumOrderValue = 100
        
        // Creators
        creatorContentEnabled = true
        liveStreamsEnabled = true
        enabledContentTypes = ["tradingVideos", "marketAnalysis", "educational", "liveTrading"]
        
        // News
        marketNewsEnabled = true
        breakingNewsOnly = false
        enabledNewsCategories = ["earnings", "economicData", "companyNews", "marketMovers", "regulatory"]
        
        // Schedule
        doNotDisturbEnabled = false
        setupDefaultTimes()
        weekendNotificationsEnabled = false
        tradingHoursOnly = false
        
        // Save the reset preferences
        Task {
            await savePreferences()
        }
    }
    
    private func setupDefaultTimes() {
        let calendar = Calendar.current
        let now = Date()
        
        // Set default quiet hours: 10 PM to 7 AM
        quietHoursStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now) ?? now
        quietHoursEnd = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
    }
    
    // MARK: - Notification Testing
    
    func sendTestNotification() async {
        guard notificationsEnabled else {
            error = PreferencesError.notificationsDisabled
            showingError = true
            return
        }
        
        do {
            // Create a test notification
            let content = UNMutableNotificationContent()
            content.title = "HingeTrade Test"
            content.body = "This is a test notification to verify your settings are working correctly."
            content.sound = soundEnabled ? .default : nil
            content.badge = badgeEnabled ? 1 : 0
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
            
            let center = UNUserNotificationCenter.current()
            try await center.add(request)
            
        } catch {
            self.error = PreferencesError.testNotificationFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    // MARK: - Utility Methods
    
    func isNotificationAllowed(at date: Date = Date()) -> Bool {
        guard notificationsEnabled else { return false }
        
        let calendar = Calendar.current
        
        // Check do not disturb hours
        if doNotDisturbEnabled {
            let hour = calendar.component(.hour, from: date)
            let startHour = calendar.component(.hour, from: quietHoursStart)
            let endHour = calendar.component(.hour, from: quietHoursEnd)
            
            if startHour > endHour { // Crosses midnight
                if hour >= startHour || hour < endHour {
                    return false
                }
            } else { // Same day
                if hour >= startHour && hour < endHour {
                    return false
                }
            }
        }
        
        // Check weekend notifications
        if !weekendNotificationsEnabled {
            let weekday = calendar.component(.weekday, from: date)
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                return false
            }
        }
        
        // Check trading hours only
        if tradingHoursOnly {
            let hour = calendar.component(.hour, from: date)
            let weekday = calendar.component(.weekday, from: date)
            
            // Monday-Friday 9:30 AM - 4:00 PM EST
            if weekday >= 2 && weekday <= 6 { // Monday-Friday
                if hour < 9 || hour >= 16 {
                    return false
                }
            } else {
                return false // Weekend
            }
        }
        
        return true
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // Auto-save when preferences change
        Publishers.CombineLatest4(
            $soundEnabled.dropFirst(),
            $badgeEnabled.dropFirst(),
            $priceAlertsEnabled.dropFirst(),
            $orderFillsEnabled.dropFirst()
        )
        .debounce(for: .seconds(1), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            Task {
                await self?.savePreferences()
            }
        }
        .store(in: &cancellables)
        
        Publishers.CombineLatest4(
            $creatorContentEnabled.dropFirst(),
            $marketNewsEnabled.dropFirst(),
            $doNotDisturbEnabled.dropFirst(),
            $tradingHoursOnly.dropFirst()
        )
        .debounce(for: .seconds(1), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            Task {
                await self?.savePreferences()
            }
        }
        .store(in: &cancellables)
        
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
            }
            .store(in: &cancellables)
        
        // Update notification service when general settings change
        $notificationsEnabled
            .sink { [weak self] enabled in
                if enabled {
                    Task {
                        _ = await self?.notificationService.requestAuthorization()
                    }
                }
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

// MARK: - Preferences Service

protocol PreferencesService {
    func getPreferences() async throws -> NotificationPreferences
    func savePreferences(_ preferences: NotificationPreferences) async throws
}

class PreferencesService: PreferencesService {
    func getPreferences() async throws -> NotificationPreferences {
        // Simulate loading from storage
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Return default preferences
        return NotificationPreferences(
            soundEnabled: true,
            badgeEnabled: true,
            notificationStyle: 0,
            priceAlertsEnabled: true,
            priceCheckFrequency: 0,
            enabledAlertTypes: ["priceAbove", "priceBelow", "percentChange", "volumeSpike"],
            orderFillsEnabled: true,
            partialFillsEnabled: true,
            orderRejectionsEnabled: true,
            minimumOrderValue: 100,
            creatorContentEnabled: true,
            liveStreamsEnabled: true,
            enabledContentTypes: ["tradingVideos", "marketAnalysis", "educational", "liveTrading"],
            marketNewsEnabled: true,
            breakingNewsOnly: false,
            enabledNewsCategories: ["earnings", "economicData", "companyNews", "marketMovers", "regulatory"],
            doNotDisturbEnabled: false,
            quietHoursStart: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
            quietHoursEnd: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
            weekendNotificationsEnabled: false,
            tradingHoursOnly: false
        )
    }
    
    func savePreferences(_ preferences: NotificationPreferences) async throws {
        // Simulate saving to storage
        try await Task.sleep(nanoseconds: 300_000_000)
        // In a real implementation, this would save to UserDefaults, Core Data, or server
    }
}

// MARK: - Models

struct NotificationPreferences {
    // General
    let soundEnabled: Bool
    let badgeEnabled: Bool
    let notificationStyle: Int
    
    // Price Alerts
    let priceAlertsEnabled: Bool
    let priceCheckFrequency: Int
    let enabledAlertTypes: Set<String>
    
    // Orders
    let orderFillsEnabled: Bool
    let partialFillsEnabled: Bool
    let orderRejectionsEnabled: Bool
    let minimumOrderValue: Decimal
    
    // Creators
    let creatorContentEnabled: Bool
    let liveStreamsEnabled: Bool
    let enabledContentTypes: Set<String>
    
    // News
    let marketNewsEnabled: Bool
    let breakingNewsOnly: Bool
    let enabledNewsCategories: Set<String>
    
    // Schedule
    let doNotDisturbEnabled: Bool
    let quietHoursStart: Date
    let quietHoursEnd: Date
    let weekendNotificationsEnabled: Bool
    let tradingHoursOnly: Bool
}

// MARK: - Error Types

enum PreferencesError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case savingFailed(String)
    case testNotificationFailed(String)
    case notificationsDisabled
    case unauthorized
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .savingFailed(let message),
             .testNotificationFailed(let message):
            return message
        case .notificationsDisabled:
            return "notifications_disabled"
        case .unauthorized:
            return "unauthorized"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load preferences: \(message)"
        case .savingFailed(let message):
            return "Failed to save preferences: \(message)"
        case .testNotificationFailed(let message):
            return "Failed to send test notification: \(message)"
        case .notificationsDisabled:
            return "Notifications are disabled. Please enable them in settings to send test notifications."
        case .unauthorized:
            return "You are not authorized to modify notification preferences"
        }
    }
}