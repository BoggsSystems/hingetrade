//
//  AppStateViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class AppStateViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var showingError: Bool = false
    
    // Account metrics for header display
    @Published var buyingPower: Decimal = 0.0
    @Published var totalEquity: Decimal = 0.0
    @Published var todaysPL: Decimal = 0.0
    
    // Navigation state
    @Published var selectedSymbol: String?
    @Published var showingTradeTicket: Bool = false
    @Published var deepLinkDestination: DeepLinkDestination?
    
    private let authenticationService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    enum DeepLinkDestination {
        case video(id: String)
        case position(symbol: String)
        case order(id: String)
        case alert(id: String)
    }
    
    init(authenticationService: AuthenticationService = AuthenticationService()) {
        self.authenticationService = authenticationService
        setupErrorHandling()
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let user = try await authenticationService.signIn(email: email, password: password)
            self.currentUser = user
            self.isAuthenticated = true
            await loadAccountMetrics()
        } catch {
            self.error = AppError.authenticationFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    func signOut() {
        authenticationService.signOut()
        currentUser = nil
        isAuthenticated = false
        resetAccountMetrics()
    }
    
    private func checkAuthenticationStatus() {
        isAuthenticated = authenticationService.isAuthenticated
        if isAuthenticated {
            currentUser = authenticationService.currentUser
            Task {
                await loadAccountMetrics()
            }
        }
    }
    
    // MARK: - Account Metrics
    
    private func loadAccountMetrics() async {
        // TODO: Implement with actual account service
        // Placeholder values for now
        buyingPower = 5230.45
        totalEquity = 12450.33
        todaysPL = 125.67
    }
    
    private func resetAccountMetrics() {
        buyingPower = 0.0
        totalEquity = 0.0
        todaysPL = 0.0
    }
    
    // MARK: - Navigation & Deep Linking
    
    func handleDeepLink(_ destination: DeepLinkDestination) {
        deepLinkDestination = destination
    }
    
    func selectSymbol(_ symbol: String) {
        selectedSymbol = symbol
    }
    
    func showTradeTicket(for symbol: String? = nil) {
        if let symbol = symbol {
            selectedSymbol = symbol
        }
        showingTradeTicket = true
    }
    
    func hideTradeTicket() {
        showingTradeTicket = false
        selectedSymbol = nil
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
    
    func showError(_ error: AppError) {
        self.error = error
        self.showingError = true
    }
}

// MARK: - AppError

enum AppError: LocalizedError, Identifiable {
    case authenticationFailed(String)
    case networkError(String)
    case tradingError(String)
    case dataError(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .authenticationFailed(let message),
             .networkError(let message),
             .tradingError(let message),
             .dataError(let message),
             .unknown(let message):
            return message
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .tradingError(let message):
            return "Trading error: \(message)"
        case .dataError(let message):
            return "Data error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Please check your credentials and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .tradingError:
            return "Please review your order details and try again."
        case .dataError:
            return "Please refresh the data and try again."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}