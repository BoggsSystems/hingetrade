//
//  OrderManagementViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class OrderManagementViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var filteredOrders: [Order] = []
    @Published var currentFilter: OrderManagementView.OrderFilterType = .all
    @Published var isLoading: Bool = false
    @Published var error: OrderManagementError?
    
    // Quick Stats
    @Published var totalOrders: Int = 0
    @Published var openOrdersCount: Int = 0
    @Published var filledTodayCount: Int = 0
    @Published var cancelledOrdersCount: Int = 0
    
    // Services
    private let tradingService: TradingService
    private let webSocketService: WebSocketService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        tradingService: TradingService = TradingService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager())),
        webSocketService: WebSocketService = WebSocketService(url: URL(string: "wss://api.alpaca.markets/stream")!)
    ) {
        self.tradingService = tradingService
        self.webSocketService = webSocketService
        
        setupRealTimeUpdates()
    }
    
    // MARK: - Data Loading
    
    func loadOrders() async {
        isLoading = true
        error = nil
        
        do {
            let loadedOrders = try await withCheckedThrowingContinuation { continuation in
                tradingService.getOrders(status: nil)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { orders in
                            continuation.resume(returning: orders)
                        }
                    )
                    .store(in: &cancellables)
            }
            self.orders = loadedOrders
            updateFilteredOrders()
            updateOrderStats()
        } catch {
            self.error = OrderManagementError.loadingFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func refreshOrders() async {
        await loadOrders()
    }
    
    // MARK: - Filtering
    
    func setFilter(_ filterType: OrderManagementView.OrderFilterType) {
        currentFilter = filterType
        updateFilteredOrders()
    }
    
    private func updateFilteredOrders() {
        filteredOrders = orders.filter { order in
            switch currentFilter {
            case .all:
                return true
            case .open:
                return order.status == .new || order.status == .partiallyFilled
            case .filled:
                return order.status == .filled
            case .cancelled:
                return order.status == .canceled
            case .pending:
                return order.status == .pendingNew
            }
        }
    }
    
    func getOrderCount(for filterType: OrderManagementView.OrderFilterType) -> Int {
        switch filterType {
        case .all:
            return totalOrders
        case .open:
            return openOrdersCount
        case .filled:
            return orders.filter { $0.status == .filled }.count
        case .cancelled:
            return cancelledOrdersCount
        case .pending:
            return orders.filter { $0.status == .pendingNew }.count
        }
    }
    
    // MARK: - Order Actions
    
    func cancelOrder(_ order: Order) async {
        do {
            try await withCheckedThrowingContinuation { continuation in
                tradingService.cancelOrder(id: order.id)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                continuation.resume()
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            }
            
            // Update the order status in our list
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                // Create a modified order with cancelled status
                var updatedOrder = orders[index]
                // Since Order is a struct with let properties, we'd need to create a new one
                // For now, just remove it and reload
                await refreshOrders()
            }
            
        } catch {
            self.error = OrderManagementError.cancellationFailed(error.localizedDescription)
        }
    }
    
    func modifyOrder(_ order: Order) async {
        // For now, this would open a modification interface
        // In a full implementation, this might present a modal to modify the order
        print("Modify order requested for: \(order.symbol)")
        
        // This could trigger a sheet presentation in the UI
        // For now, we'll just log it
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // For now, skip real-time updates since WebSocketService doesn't have orderUpdates
        // This would be implemented when WebSocket service is properly configured
    }
    
    private func handleOrderUpdate(_ updatedOrder: Order) {
        // Update or add the order in our list
        if let index = orders.firstIndex(where: { $0.id == updatedOrder.id }) {
            orders[index] = updatedOrder
        } else {
            orders.append(updatedOrder)
        }
        
        updateFilteredOrders()
        updateOrderStats()
    }
    
    // MARK: - Statistics
    
    private func updateOrderStats() {
        totalOrders = orders.count
        openOrdersCount = orders.filter { $0.status == .new || $0.status == .partiallyFilled }.count
        cancelledOrdersCount = orders.filter { $0.status == .canceled }.count
        
        // Count orders filled today
        let today = Calendar.current.startOfDay(for: Date())
        filledTodayCount = orders.filter { order in
            guard order.status == .filled,
                  let filledAt = order.filledAt else {
                return false
            }
            return Calendar.current.startOfDay(for: filledAt) == today
        }.count
    }
    
    // MARK: - Error Handling
    
    func dismissError() {
        error = nil
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Error Types

enum OrderManagementError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case cancellationFailed(String)
    case modificationFailed(String)
    case networkError(String)
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .cancellationFailed(let message),
             .modificationFailed(let message),
             .networkError(let message):
            return message
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load orders: \(message)"
        case .cancellationFailed(let message):
            return "Failed to cancel order: \(message)"
        case .modificationFailed(let message):
            return "Failed to modify order: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadingFailed, .networkError:
            return "Please check your internet connection and try again."
        case .cancellationFailed, .modificationFailed:
            return "Please try again or contact support if the issue persists."
        }
    }
}