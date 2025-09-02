//
//  PriceAlertsViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class PriceAlertsViewModel: ObservableObject {
    @Published var alerts: [PriceAlert] = []
    @Published var filteredAlerts: [PriceAlert] = []
    @Published var isLoading = false
    @Published var error: AlertError?
    @Published var showingError = false
    @Published var searchText = ""
    
    // Statistics
    @Published var activeAlertsCount = 0
    @Published var triggeredTodayCount = 0
    @Published var totalAlertsCount = 0
    @Published var successRate: Double = 0.0
    
    // Current filter
    private var currentFilter: PriceAlertsView.AlertFilter = .all
    
    // Services
    private let alertService: AlertService
    private let notificationService: NotificationService
    private let marketDataService: MarketDataService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        alertService: AlertService = AlertService(),
        notificationService: NotificationService = NotificationService.shared,
        marketDataService: MarketDataService = MarketDataService()
    ) {
        self.alertService = alertService
        self.notificationService = notificationService
        self.marketDataService = marketDataService
        
        setupBindings()
        setupRealTimeUpdates()
    }
    
    // MARK: - Data Loading
    
    func loadAlerts() async {
        isLoading = true
        error = nil
        
        do {
            let loadedAlerts = try await alertService.getAllAlerts()
            
            // Load current prices for active alerts
            let activeSymbols = Set(loadedAlerts.filter { $0.isActive }.map { $0.symbol })
            let quotes = try await loadQuotes(for: Array(activeSymbols))
            
            // Update alerts with current market data
            self.alerts = loadedAlerts.map { alert in
                if let quote = quotes[alert.symbol] {
                    return updateAlertWithQuote(alert, quote: quote)
                }
                return alert
            }
            
            updateStatistics()
            applyFilter()
            
            // Check for triggered alerts
            await checkTriggeredAlerts()
            
        } catch {
            self.error = AlertError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    private func loadQuotes(for symbols: [String]) async throws -> [String: Quote] {
        var quotes: [String: Quote] = [:]
        
        for symbol in symbols {
            if let quote = try? await marketDataService.getQuote(symbol: symbol) {
                quotes[symbol] = quote
            }
        }
        
        return quotes
    }
    
    private func updateAlertWithQuote(_ alert: PriceAlert, quote: Quote) -> PriceAlert {
        // Check if alert should be triggered
        var updatedAlert = alert
        
        if alert.isActive && alert.triggeredAt == nil {
            let shouldTrigger = checkAlertCondition(alert: alert, quote: quote)
            
            if shouldTrigger {
                updatedAlert.triggeredAt = Date()
                
                // Schedule notification
                Task {
                    try? await notificationService.schedulePriceAlert(updatedAlert)
                }
            }
        }
        
        return updatedAlert
    }
    
    private func checkAlertCondition(alert: PriceAlert, quote: Quote) -> Bool {
        switch alert.alertType {
        case .priceAbove:
            return quote.bidPrice >= alert.targetPrice
        case .priceBelow:
            return quote.bidPrice <= alert.targetPrice
        case .percentChange:
            guard let percentTarget = alert.percentChange else { return false }
            return abs(quote.changePercent ?? 0) >= abs(percentTarget)
        case .volumeSpike:
            // Would need to compare against average volume
            return false
        }
    }
    
    // MARK: - Alert Management
    
    func createAlert(_ alert: PriceAlert) async {
        do {
            let createdAlert = try await alertService.createAlert(alert)
            alerts.append(createdAlert)
            
            // Request notification authorization if needed
            if !notificationService.isAuthorized {
                _ = await notificationService.requestAuthorization()
            }
            
            // Schedule notification
            if notificationService.isAuthorized {
                try? await notificationService.schedulePriceAlert(createdAlert)
            }
            
            updateStatistics()
            applyFilter()
            
        } catch {
            self.error = AlertError.creationFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func updateAlert(_ alert: PriceAlert) async {
        do {
            let updatedAlert = try await alertService.updateAlert(alert)
            
            if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
                alerts[index] = updatedAlert
                
                // Update notification
                if alert.isActive && notificationService.isAuthorized {
                    await notificationService.removePendingNotification(withId: alert.id)
                    try? await notificationService.schedulePriceAlert(updatedAlert)
                } else {
                    await notificationService.removePendingNotification(withId: alert.id)
                }
                
                updateStatistics()
                applyFilter()
            }
            
        } catch {
            self.error = AlertError.updateFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func deleteAlert(_ alert: PriceAlert) async {
        do {
            try await alertService.deleteAlert(alert.id)
            alerts.removeAll { $0.id == alert.id }
            
            // Remove notification
            await notificationService.removePendingNotification(withId: alert.id)
            
            updateStatistics()
            applyFilter()
            
        } catch {
            self.error = AlertError.deletionFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func toggleAlert(_ alert: PriceAlert) async {
        var updatedAlert = alert
        updatedAlert.isActive.toggle()
        await updateAlert(updatedAlert)
    }
    
    // MARK: - Filtering
    
    func setFilter(_ filter: PriceAlertsView.AlertFilter) {
        currentFilter = filter
        applyFilter()
    }
    
    private func applyFilter() {
        var filtered = alerts
        
        // Apply status filter
        switch currentFilter {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.isActive && $0.triggeredAt == nil }
        case .triggered:
            filtered = filtered.filter { $0.triggeredAt != nil }
        case .expired:
            filtered = filtered.filter { 
                if let expiresAt = $0.expiresAt {
                    return Date() > expiresAt
                }
                return false
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { 
                $0.symbol.lowercased().contains(searchLower)
            }
        }
        
        // Sort by creation date (newest first)
        filtered.sort { $0.createdAt > $1.createdAt }
        
        filteredAlerts = filtered
    }
    
    func getCount(for filter: PriceAlertsView.AlertFilter) -> Int {
        switch filter {
        case .all:
            return alerts.count
        case .active:
            return alerts.filter { $0.isActive && $0.triggeredAt == nil }.count
        case .triggered:
            return alerts.filter { $0.triggeredAt != nil }.count
        case .expired:
            return alerts.filter { 
                if let expiresAt = $0.expiresAt {
                    return Date() > expiresAt
                }
                return false
            }.count
        }
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // Update alerts when new quotes come in
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkTriggeredAlerts()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkTriggeredAlerts() async {
        let activeAlerts = alerts.filter { $0.isActive && $0.triggeredAt == nil }
        guard !activeAlerts.isEmpty else { return }
        
        let symbols = Set(activeAlerts.map { $0.symbol })
        guard let quotes = try? await loadQuotes(for: Array(symbols)) else { return }
        
        var hasUpdates = false
        
        for (index, alert) in alerts.enumerated() {
            if alert.isActive && alert.triggeredAt == nil,
               let quote = quotes[alert.symbol] {
                let updatedAlert = updateAlertWithQuote(alert, quote: quote)
                if updatedAlert.triggeredAt != nil {
                    alerts[index] = updatedAlert
                    hasUpdates = true
                }
            }
        }
        
        if hasUpdates {
            updateStatistics()
            applyFilter()
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        totalAlertsCount = alerts.count
        activeAlertsCount = alerts.filter { $0.isActive && $0.triggeredAt == nil }.count
        
        // Count triggered today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        triggeredTodayCount = alerts.filter { alert in
            guard let triggeredAt = alert.triggeredAt else { return false }
            return calendar.startOfDay(for: triggeredAt) == today
        }.count
        
        // Calculate success rate
        let triggeredAlerts = alerts.filter { $0.triggeredAt != nil }
        if !triggeredAlerts.isEmpty {
            // Success could be defined as alerts that triggered within their timeframe
            let successfulAlerts = triggeredAlerts.filter { alert in
                if let expiresAt = alert.expiresAt,
                   let triggeredAt = alert.triggeredAt {
                    return triggeredAt <= expiresAt
                }
                return true
            }
            successRate = Double(successfulAlerts.count) / Double(triggeredAlerts.count)
        } else {
            successRate = 0
        }
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilter()
            }
            .store(in: &cancellables)
        
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

// MARK: - Alert Service

protocol AlertService {
    func getAllAlerts() async throws -> [PriceAlert]
    func createAlert(_ alert: PriceAlert) async throws -> PriceAlert
    func updateAlert(_ alert: PriceAlert) async throws -> PriceAlert
    func deleteAlert(_ id: String) async throws
}

class AlertService: AlertService {
    func getAllAlerts() async throws -> [PriceAlert] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 800_000_000)
        
        return [
            PriceAlert(
                id: "alert-1",
                symbol: "AAPL",
                alertType: .priceAbove,
                targetPrice: 180.00,
                percentChange: nil,
                createdAt: Date().addingTimeInterval(-86400 * 3),
                isActive: true,
                triggeredAt: nil,
                expiresAt: Date().addingTimeInterval(86400 * 7)
            ),
            PriceAlert(
                id: "alert-2",
                symbol: "TSLA",
                alertType: .priceBelow,
                targetPrice: 240.00,
                percentChange: nil,
                createdAt: Date().addingTimeInterval(-86400 * 2),
                isActive: true,
                triggeredAt: Date().addingTimeInterval(-3600),
                expiresAt: nil
            ),
            PriceAlert(
                id: "alert-3",
                symbol: "NVDA",
                alertType: .percentChange,
                targetPrice: 0,
                percentChange: 5.0,
                createdAt: Date().addingTimeInterval(-86400),
                isActive: true,
                triggeredAt: nil,
                expiresAt: Date().addingTimeInterval(86400 * 30)
            )
        ]
    }
    
    func createAlert(_ alert: PriceAlert) async throws -> PriceAlert {
        try await Task.sleep(nanoseconds: 500_000_000)
        return alert
    }
    
    func updateAlert(_ alert: PriceAlert) async throws -> PriceAlert {
        try await Task.sleep(nanoseconds: 400_000_000)
        return alert
    }
    
    func deleteAlert(_ id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}

// MARK: - Error Types

enum AlertError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case notificationFailed(String)
    case unauthorized
    case limitReached
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .creationFailed(let message),
             .updateFailed(let message),
             .deletionFailed(let message),
             .notificationFailed(let message):
            return message
        case .unauthorized:
            return "unauthorized"
        case .limitReached:
            return "limit_reached"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load alerts: \(message)"
        case .creationFailed(let message):
            return "Failed to create alert: \(message)"
        case .updateFailed(let message):
            return "Failed to update alert: \(message)"
        case .deletionFailed(let message):
            return "Failed to delete alert: \(message)"
        case .notificationFailed(let message):
            return "Failed to schedule notification: \(message)"
        case .unauthorized:
            return "You need to enable notifications to create alerts"
        case .limitReached:
            return "You've reached the maximum number of alerts"
        }
    }
}