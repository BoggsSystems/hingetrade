//
//  AccountsViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class AccountsViewModel: ObservableObject {
    @Published var account: Account?
    @Published var isLoading: Bool = false
    @Published var error: AccountError?
    @Published var showingError: Bool = false
    
    // Account Metrics
    @Published var totalEquity: Decimal = 0.0
    @Published var buyingPower: Decimal = 0.0
    @Published var cashBalance: Decimal = 0.0
    @Published var longMarketValue: Decimal = 0.0
    @Published var shortMarketValue: Decimal = 0.0
    @Published var todaysPL: Decimal = 0.0
    @Published var todaysPLPercentage: Double = 0.0
    
    // Account Details
    @Published var accountType: AccountType = .cash
    @Published var marginEnabled: Bool = false
    @Published var dayTradesUsed: Int = 0
    @Published var dayTradesLimit: Int = 3
    
    // Position Summaries
    @Published var openPositionsCount: Int = 0
    @Published var biggestWinner: PositionSummary?
    @Published var biggestLoser: PositionSummary?
    
    // Real-time updates
    @Published var lastUpdated: Date = Date()
    
    private let tradingService: TradingService
    private let webSocketService: WebSocketService
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    enum AccountType {
        case cash
        case margin
        case pdtMargin
        
        var displayName: String {
            switch self {
            case .cash: return "Cash"
            case .margin: return "Margin"
            case .pdtMargin: return "PDT Margin"
            }
        }
    }
    
    struct PositionSummary {
        let symbol: String
        let unrealizedPL: Decimal
        let unrealizedPLPercent: Double
    }
    
    init(tradingService: TradingService = TradingService(), webSocketService: WebSocketService = WebSocketService()) {
        self.tradingService = tradingService
        self.webSocketService = webSocketService
        setupRealTimeUpdates()
        setupErrorHandling()
    }
    
    // MARK: - Data Loading
    
    func loadAccountData() async {
        isLoading = true
        error = nil
        
        do {
            // Load account information
            let accountData = try await tradingService.getAccount()
            self.account = accountData
            updateAccountMetrics(from: accountData)
            
            // Load position summaries
            await loadPositionSummaries()
            
            lastUpdated = Date()
        } catch {
            self.error = AccountError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadAccountData()
    }
    
    private func loadPositionSummaries() async {
        do {
            let positions = try await tradingService.getPositions()
            openPositionsCount = positions.count
            
            // Calculate biggest winner and loser
            let sortedByPL = positions.sorted { $0.unrealizedPL > $1.unrealizedPL }
            
            if let winner = sortedByPL.first, winner.unrealizedPL > 0 {
                biggestWinner = PositionSummary(
                    symbol: winner.symbol,
                    unrealizedPL: winner.unrealizedPL,
                    unrealizedPLPercent: Double(winner.unrealizedPL / winner.marketValue)
                )
            }
            
            if let loser = sortedByPL.last, loser.unrealizedPL < 0 {
                biggestLoser = PositionSummary(
                    symbol: loser.symbol,
                    unrealizedPL: loser.unrealizedPL,
                    unrealizedPLPercent: Double(loser.unrealizedPL / loser.marketValue)
                )
            }
            
        } catch {
            print("Failed to load position summaries: \(error)")
        }
    }
    
    private func updateAccountMetrics(from account: Account) {
        totalEquity = account.equity
        buyingPower = account.buyingPower
        cashBalance = account.cash
        longMarketValue = account.longMarketValue
        shortMarketValue = account.shortMarketValue
        
        // Calculate today's P&L
        let previousEquity = account.lastDayEquity
        todaysPL = totalEquity - previousEquity
        todaysPLPercentage = previousEquity > 0 ? Double(todaysPL / previousEquity) : 0.0
        
        // Account type and settings
        accountType = account.marginEnabled ? .margin : .cash
        marginEnabled = account.marginEnabled
        dayTradesUsed = account.dayTradeCount
        dayTradesLimit = account.marginEnabled ? (totalEquity >= 25000 ? Int.max : 3) : 3
    }
    
    // MARK: - Real-Time Updates
    
    private func setupRealTimeUpdates() {
        // Subscribe to WebSocket account updates
        webSocketService.accountUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accountUpdate in
                self?.handleAccountUpdate(accountUpdate)
            }
            .store(in: &cancellables)
        
        // Set up periodic refresh timer (every 30 seconds)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshData()
            }
        }
    }
    
    private func handleAccountUpdate(_ update: Account) {
        account = update
        updateAccountMetrics(from: update)
        lastUpdated = Date()
    }
    
    // MARK: - Computed Properties
    
    var todaysPLChange: Decimal {
        return todaysPL
    }
    
    var marginUtilization: Double {
        guard marginEnabled, buyingPower > 0 else { return 0.0 }
        let usedMargin = longMarketValue - cashBalance
        return Double(usedMargin / buyingPower)
    }
    
    var accountHealthScore: Double {
        // Simple health score calculation
        let plScore = todaysPLPercentage > 0 ? 1.0 : 0.5
        let marginScore = marginEnabled ? (1.0 - marginUtilization) : 1.0
        return (plScore + marginScore) / 2.0
    }
    
    // MARK: - Actions
    
    func fundAccount() {
        // TODO: Navigate to funding flow
        print("Fund account tapped")
    }
    
    func viewFullPositions() {
        // TODO: Navigate to full positions view
        print("View full positions tapped")
    }
    
    func exportAccountStatement() {
        // TODO: Generate and export account statement
        print("Export account statement tapped")
    }
    
    // MARK: - Error Handling
    
    private func setupErrorHandling() {
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
    
    // MARK: - Cleanup
    
    deinit {
        updateTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - AccountError

enum AccountError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case updateFailed(String)
    case networkError(String)
    case unauthorized
    case accountSuspended
    case maintenanceMode
    case unknown(String)
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .updateFailed(let message),
             .networkError(let message),
             .unknown(let message):
            return message
        case .unauthorized:
            return "unauthorized"
        case .accountSuspended:
            return "account_suspended"
        case .maintenanceMode:
            return "maintenance_mode"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load account data: \(message)"
        case .updateFailed(let message):
            return "Failed to update account: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "You are not authorized to access this account"
        case .accountSuspended:
            return "Your account has been suspended"
        case .maintenanceMode:
            return "Account services are currently under maintenance"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadingFailed, .updateFailed:
            return "Please try again in a moment."
        case .networkError:
            return "Please check your internet connection and try again."
        case .unauthorized:
            return "Please sign in again or contact support."
        case .accountSuspended:
            return "Please contact customer support for assistance."
        case .maintenanceMode:
            return "Please try again later."
        case .unknown:
            return "Please contact support if this issue persists."
        }
    }
}