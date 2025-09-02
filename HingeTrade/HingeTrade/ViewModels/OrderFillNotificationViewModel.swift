//
//  OrderFillNotificationViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class OrderFillNotificationViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var filteredOrders: [Order] = []
    @Published var isLoading = false
    @Published var error: OrderError?
    @Published var showingError = false
    
    // Statistics
    @Published var filledTodayCount = 0
    @Published var pendingOrdersCount = 0
    @Published var totalVolumeToday: Decimal = 0
    @Published var fillRate: Double = 0.0
    
    // Current filter
    private var currentFilter: OrderFillNotificationsView.OrderFillFilter = .all
    
    // Services
    private let notificationService: NotificationService
    private let orderService: OrderService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        notificationService: NotificationService = NotificationService.shared,
        orderService: OrderService = OrderService()
    ) {
        self.notificationService = notificationService
        self.orderService = orderService
        
        setupBindings()
        setupRealTimeUpdates()
    }
    
    // MARK: - Data Loading
    
    func loadOrders() async {
        isLoading = true
        error = nil
        
        do {
            let loadedOrders = try await orderService.getAllOrders()
            self.orders = loadedOrders
            
            updateStatistics()
            applyFilter()
            
            // Check for orders that need notifications
            await checkForNewFills()
            
        } catch {
            self.error = OrderError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Filtering
    
    func setFilter(_ filter: OrderFillNotificationsView.OrderFillFilter) {
        currentFilter = filter
        applyFilter()
    }
    
    private func applyFilter() {
        switch currentFilter {
        case .all:
            filteredOrders = orders
        case .filled:
            filteredOrders = orders.filter { $0.status == .filled }
        case .partialFill:
            filteredOrders = orders.filter { $0.status == .partiallyFilled }
        case .pending:
            filteredOrders = orders.filter { $0.status == .pending }
        case .cancelled:
            filteredOrders = orders.filter { $0.status == .cancelled }
        }
        
        // Sort by most recent first
        filteredOrders.sort { order1, order2 in
            let date1 = order1.filledAt ?? order1.updatedAt ?? order1.submittedAt
            let date2 = order2.filledAt ?? order2.updatedAt ?? order2.submittedAt
            return date1 > date2
        }
    }
    
    func getCount(for filter: OrderFillNotificationsView.OrderFillFilter) -> Int {
        switch filter {
        case .all:
            return orders.count
        case .filled:
            return orders.filter { $0.status == .filled }.count
        case .partialFill:
            return orders.filter { $0.status == .partiallyFilled }.count
        case .pending:
            return orders.filter { $0.status == .pending }.count
        case .cancelled:
            return orders.filter { $0.status == .cancelled }.count
        }
    }
    
    // MARK: - Notification Management
    
    private func checkForNewFills() async {
        let newlyFilledOrders = orders.filter { order in
            (order.status == .filled || order.status == .partiallyFilled) &&
            !order.hasNotificationBeenSent &&
            order.filledAt != nil
        }
        
        for order in newlyFilledOrders {
            await sendOrderFillNotification(for: order)
        }
    }
    
    private func sendOrderFillNotification(for order: Order) async {
        do {
            try await notificationService.scheduleOrderFillNotification(order)
            
            // Mark notification as sent
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                orders[index].hasNotificationBeenSent = true
            }
            
        } catch {
            print("Failed to send order fill notification: \(error)")
        }
    }
    
    func markOrderNotificationAsRead(_ orderId: String) {
        notificationService.markNotificationAsRead("order-\(orderId)")
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // Check for order updates every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkForOrderUpdates()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkForOrderUpdates() async {
        // In a real app, this would check with the trading service for order updates
        // For now, simulate some order fills
        let pendingOrders = orders.filter { $0.status == .pending }
        
        for order in pendingOrders.prefix(1) { // Simulate one order filling
            if Bool.random() && order.filledAt == nil { // 50% chance
                await simulateOrderFill(order)
            }
        }
    }
    
    private func simulateOrderFill(_ order: Order) async {
        // Simulate order fill
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index].status = .filled
            orders[index].filledAt = Date()
            orders[index].fillPrice = order.limitPrice ?? Decimal(Double.random(in: 150...200))
            
            // Send notification for the filled order
            await sendOrderFillNotification(for: orders[index])
            
            updateStatistics()
            applyFilter()
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Filled today count
        filledTodayCount = orders.filter { order in
            guard let filledAt = order.filledAt else { return false }
            return calendar.startOfDay(for: filledAt) == today
        }.count
        
        // Pending orders count
        pendingOrdersCount = orders.filter { $0.status == .pending }.count
        
        // Total volume today
        let filledTodayOrders = orders.filter { order in
            guard let filledAt = order.filledAt else { return false }
            return calendar.startOfDay(for: filledAt) == today
        }
        
        totalVolumeToday = filledTodayOrders.reduce(0) { total, order in
            let price = order.fillPrice ?? order.limitPrice ?? 0
            return total + (price * Decimal(order.quantity))
        }
        
        // Fill rate (filled orders / total submitted orders)
        let totalOrders = orders.count
        let filledOrders = orders.filter { $0.status == .filled }.count
        
        if totalOrders > 0 {
            fillRate = Double(filledOrders) / Double(totalOrders)
        } else {
            fillRate = 0
        }
    }
    
    // MARK: - Bindings
    
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

// MARK: - Order Service

protocol OrderService {
    func getAllOrders() async throws -> [Order]
    func getOrder(id: String) async throws -> Order?
}

class OrderService: OrderService {
    func getAllOrders() async throws -> [Order] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return [
            Order(
                id: "order-1",
                accountId: "account-001",
                symbol: "AAPL",
                quantity: 100,
                side: .buy,
                orderType: .market,
                timeInForce: .day,
                limitPrice: nil,
                stopPrice: nil,
                submittedAt: Date().addingTimeInterval(-3600),
                status: .filled,
                filledAt: Date().addingTimeInterval(-3500),
                fillPrice: Decimal(175.50),
                updatedAt: Date().addingTimeInterval(-3500),
                hasNotificationBeenSent: true
            ),
            Order(
                id: "order-2",
                accountId: "account-001",
                symbol: "TSLA",
                quantity: 50,
                side: .sell,
                orderType: .limit,
                timeInForce: .gtc,
                limitPrice: Decimal(245.00),
                stopPrice: nil,
                submittedAt: Date().addingTimeInterval(-1800),
                status: .pending,
                filledAt: nil,
                fillPrice: nil,
                updatedAt: Date().addingTimeInterval(-1800),
                hasNotificationBeenSent: false
            ),
            Order(
                id: "order-3",
                accountId: "account-001",
                symbol: "NVDA",
                quantity: 25,
                side: .buy,
                orderType: .stop,
                timeInForce: .day,
                limitPrice: nil,
                stopPrice: Decimal(420.00),
                submittedAt: Date().addingTimeInterval(-900),
                status: .partiallyFilled,
                filledAt: Date().addingTimeInterval(-600),
                fillPrice: Decimal(418.75),
                updatedAt: Date().addingTimeInterval(-600),
                hasNotificationBeenSent: false
            ),
            Order(
                id: "order-4",
                accountId: "account-001",
                symbol: "MSFT",
                quantity: 75,
                side: .buy,
                orderType: .limit,
                timeInForce: .day,
                limitPrice: Decimal(340.00),
                stopPrice: nil,
                submittedAt: Date().addingTimeInterval(-7200),
                status: .cancelled,
                filledAt: nil,
                fillPrice: nil,
                updatedAt: Date().addingTimeInterval(-3600),
                hasNotificationBeenSent: true
            )
        ]
    }
    
    func getOrder(id: String) async throws -> Order? {
        let orders = try await getAllOrders()
        return orders.first { $0.id == id }
    }
}

// MARK: - Error Types

enum OrderError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case orderNotFound(String)
    case notificationFailed(String)
    case unauthorized
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .orderNotFound(let message),
             .notificationFailed(let message):
            return message
        case .unauthorized:
            return "unauthorized"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load orders: \(message)"
        case .orderNotFound(let message):
            return "Order not found: \(message)"
        case .notificationFailed(let message):
            return "Failed to send notification: \(message)"
        case .unauthorized:
            return "You are not authorized to view order notifications"
        }
    }
}

// MARK: - Order Model Extension

extension Order {
    var hasNotificationBeenSent: Bool {
        get {
            // This would typically be stored in the order data
            // For demo purposes, we'll simulate this
            return filledAt != nil && status == .filled
        }
        set {
            // In a real implementation, this would update the order record
        }
    }
}