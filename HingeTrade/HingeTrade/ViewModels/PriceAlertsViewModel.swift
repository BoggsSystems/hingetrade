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
        alertService: AlertService = DefaultAlertService(),
        notificationService: NotificationService = NotificationService.shared,
        marketDataService: MarketDataService = MarketDataService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager()))
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
            let activeSymbols = Set(loadedAlerts.filter { alert in alert.isActive }.map { $0.symbol })
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
            do {
                let quote = try await withCheckedThrowingContinuation { continuation in
                    marketDataService.getQuote(symbol: symbol)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    continuation.resume(throwing: error)
                                }
                            },
                            receiveValue: { quote in
                                continuation.resume(returning: quote)
                            }
                        )
                        .store(in: &cancellables)
                }
                quotes[symbol] = quote
            } catch {
                print("Failed to get quote for \(symbol): \(error)")
            }
        }
        
        return quotes
    }
    
    private func updateAlertWithQuote(_ alert: PriceAlert, quote: Quote) -> PriceAlert {
        // Check if alert should be triggered
        if alert.isActive && alert.triggeredAt == nil {
            let shouldTrigger = checkAlertCondition(alert: alert, quote: quote)
            
            if shouldTrigger {
                let updatedAlert = PriceAlert(
                    id: alert.id,
                    userId: alert.userId,
                    symbol: alert.symbol,
                    price: alert.price,
                    condition: alert.condition,
                    message: alert.message,
                    isActive: alert.isActive,
                    createdAt: alert.createdAt,
                    updatedAt: Date(),
                    triggeredAt: Date()
                )
                
                // Schedule notification
                Task {
                    try? await notificationService.schedulePriceAlert(updatedAlert)
                }
                
                return updatedAlert
            }
        }
        
        return alert
    }
    
    private func checkAlertCondition(alert: PriceAlert, quote: Quote) -> Bool {
        switch alert.condition {
        case .above, .crossesAbove:
            return quote.bidPrice >= alert.price
        case .below, .crossesBelow:
            return quote.bidPrice <= alert.price
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
        let updatedAlert = PriceAlert(
            id: alert.id,
            userId: alert.userId,
            symbol: alert.symbol,
            price: alert.price,
            condition: alert.condition,
            message: alert.message,
            isActive: !alert.isActive,
            createdAt: alert.createdAt,
            updatedAt: Date(),
            triggeredAt: alert.triggeredAt
        )
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
            filtered = filtered.filter { alert in alert.isActive && alert.triggeredAt == nil }
        case .triggered:
            filtered = filtered.filter { alert in alert.triggeredAt != nil }
        case .expired:
            filtered = filtered.compactMap { (alert: PriceAlert) -> PriceAlert? in
                if let expiresAt = alert.expiresAt {
                    return Date() > expiresAt ? alert : nil
                }
                return nil
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { alert in
                alert.symbol.lowercased().contains(searchLower)
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
            return alerts.filter { alert in alert.isActive && alert.triggeredAt == nil }.count
        case .triggered:
            return alerts.filter { alert in alert.triggeredAt != nil }.count
        case .expired:
            return alerts.compactMap { (alert: PriceAlert) -> PriceAlert? in
                if let expiresAt = alert.expiresAt {
                    return Date() > expiresAt ? alert : nil
                }
                return nil
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
        let activeAlerts = alerts.filter { alert in alert.isActive && alert.triggeredAt == nil }
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
        activeAlertsCount = alerts.filter { alert in alert.isActive && alert.triggeredAt == nil }.count
        
        // Count triggered today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        triggeredTodayCount = alerts.filter { alert in
            guard let triggeredAt = alert.triggeredAt else { return false }
            return calendar.startOfDay(for: triggeredAt) == today
        }.count
        
        // Calculate success rate
        let triggeredAlerts = alerts.filter { alert in alert.triggeredAt != nil }
        if !triggeredAlerts.isEmpty {
            // Success could be defined as alerts that triggered within their timeframe
            let successfulAlerts = triggeredAlerts.compactMap { (alert: PriceAlert) -> PriceAlert? in
                if let expiresAt = alert.expiresAt,
                   let triggeredAt = alert.triggeredAt {
                    return triggeredAt <= expiresAt ? alert : nil
                } else {
                    return alert
                }
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

class DefaultAlertService: AlertService {
    func getAllAlerts() async throws -> [PriceAlert] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 800_000_000)
        
        return [
            PriceAlert(
                id: "alert-1",
                userId: "user-123",
                symbol: "AAPL",
                price: 180.00,
                condition: .above,
                message: "AAPL price alert",
                isActive: true,
                createdAt: Date().addingTimeInterval(-86400 * 3),
                updatedAt: Date().addingTimeInterval(-86400 * 3),
                triggeredAt: nil
            ),
            PriceAlert(
                id: "alert-2",
                userId: "user-123",
                symbol: "TSLA",
                price: 240.00,
                condition: .below,
                message: "TSLA price alert",
                isActive: true,
                createdAt: Date().addingTimeInterval(-86400 * 2),
                updatedAt: Date().addingTimeInterval(-86400 * 2),
                triggeredAt: Date().addingTimeInterval(-3600)
            ),
            PriceAlert(
                id: "alert-3",
                userId: "user-123",
                symbol: "NVDA",
                price: 0,
                condition: .crossesAbove,
                message: "NVDA percent change alert",
                isActive: true,
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400),
                triggeredAt: nil
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