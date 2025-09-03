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
    
    init(tradingService: TradingService = TradingService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager())), webSocketService: WebSocketService = WebSocketService(url: URL(string: "wss://api.alpaca.markets/stream")!)) {
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
            let accountData = try await withCheckedThrowingContinuation { continuation in
                tradingService.getAccount()
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { account in
                            continuation.resume(returning: account)
                        }
                    )
                    .store(in: &cancellables)
            }
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
            let positions = try await withCheckedThrowingContinuation { continuation in
                tradingService.getPositions()
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { positions in
                            continuation.resume(returning: positions)
                        }
                    )
                    .store(in: &cancellables)
            }
            openPositionsCount = positions.count
            
            // Calculate biggest winner and loser
            let sortedByPL = positions.sorted { position1, position2 in
                let pl1 = Decimal(string: position1.unrealizedPl ?? "0") ?? 0
                let pl2 = Decimal(string: position2.unrealizedPl ?? "0") ?? 0
                return pl1 > pl2
            }
            
            if let winner = sortedByPL.first {
                let winnerPL = Decimal(string: winner.unrealizedPl ?? "0") ?? 0
                if winnerPL > 0 {
                    let marketValue = Decimal(string: winner.marketValue) ?? 1
                    biggestWinner = PositionSummary(
                        symbol: winner.symbol,
                        unrealizedPL: winnerPL,
                        unrealizedPLPercent: Double(truncating: (winnerPL / marketValue) as NSDecimalNumber)
                    )
                }
            }
            
            if let loser = sortedByPL.last {
                let loserPL = Decimal(string: loser.unrealizedPl ?? "0") ?? 0
                if loserPL < 0 {
                    let marketValue = Decimal(string: loser.marketValue) ?? 1
                    biggestLoser = PositionSummary(
                        symbol: loser.symbol,
                        unrealizedPL: loserPL,
                        unrealizedPLPercent: Double(truncating: (loserPL / marketValue) as NSDecimalNumber)
                    )
                }
            }
            
        } catch {
            print("Failed to load position summaries: \(error)")
        }
    }
    
    private func updateAccountMetrics(from account: Account) {
        totalEquity = Decimal(string: account.equity) ?? 0
        buyingPower = Decimal(string: account.buyingPower) ?? 0
        cashBalance = Decimal(string: account.cash) ?? 0
        longMarketValue = Decimal(string: account.longMarketValue) ?? 0
        shortMarketValue = Decimal(string: account.shortMarketValue) ?? 0
        
        // Calculate today's P&L
        let previousEquity = Decimal(string: account.lastEquity) ?? 0
        todaysPL = totalEquity - previousEquity
        todaysPLPercentage = previousEquity > 0 ? Double(truncating: (todaysPL / previousEquity) as NSDecimalNumber) : 0.0
        
        // Account type and settings
        let isMarginAccount = account.patternDayTrader || (Decimal(string: account.multiplier) ?? 1) > 1
        accountType = isMarginAccount ? .margin : .cash
        marginEnabled = isMarginAccount
        dayTradesUsed = account.daytradeCount
        dayTradesLimit = isMarginAccount ? (totalEquity >= 25000 ? Int.max : 3) : 3
    }
    
    // MARK: - Real-Time Updates
    
    private func setupRealTimeUpdates() {
        // TODO: Subscribe to WebSocket account updates when available
        // webSocketService.accountUpdates
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] accountUpdate in
        //         self?.handleAccountUpdate(accountUpdate)
        //     }
        //     .store(in: &cancellables)
        
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
        return Double(truncating: (usedMargin / buyingPower) as NSDecimalNumber)
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