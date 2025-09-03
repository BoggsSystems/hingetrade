//
//  OrderManagementView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct OrderManagementView: View {
    @StateObject private var orderManagementViewModel = OrderManagementViewModel()
    @State private var selectedOrderType: OrderFilterType = .all
    @State private var selectedOrder: Order?
    @State private var showingOrderDetail = false
    @FocusState private var focusedOrder: String?
    @FocusState private var focusedFilter: OrderFilterType?
    
    enum OrderFilterType: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case filled = "Filled"
        case cancelled = "Cancelled"
        case pending = "Pending"
        
        var systemImage: String {
            switch self {
            case .all: return "list.bullet"
            case .open: return "clock"
            case .filled: return "checkmark.circle"
            case .cancelled: return "xmark.circle"
            case .pending: return "hourglass"
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header with filters
                orderHeaderView
                
                // Orders list
                if orderManagementViewModel.isLoading {
                    LoadingStateView(message: "Loading orders...")
                } else if orderManagementViewModel.filteredOrders.isEmpty {
                    emptyOrdersView
                } else {
                    ordersListView
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(item: $selectedOrder) { order in
            OrderDetailView(order: order)
                .environmentObject(orderManagementViewModel)
        }
        .onAppear {
            Task {
                await orderManagementViewModel.loadOrders()
            }
            
            // Auto-focus first filter
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedFilter = .all
            }
        }
        .refreshable {
            await orderManagementViewModel.refreshOrders()
        }
    }
    
    // MARK: - Header View
    
    private var orderHeaderView: some View {
        VStack(spacing: 20) {
            // Title and Summary
            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Orders")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(orderManagementViewModel.totalOrders) total orders")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                // Quick Stats
                HStack(spacing: 30) {
                    OrderStatCard(
                        title: "Open Orders",
                        count: orderManagementViewModel.openOrdersCount,
                        color: .blue
                    )
                    
                    OrderStatCard(
                        title: "Filled Today",
                        count: orderManagementViewModel.filledTodayCount,
                        color: .green
                    )
                    
                    OrderStatCard(
                        title: "Cancelled",
                        count: orderManagementViewModel.cancelledOrdersCount,
                        color: .orange
                    )
                }
                
                Spacer()
            }
            
            // Filter Buttons
            HStack(spacing: 16) {
                ForEach(OrderFilterType.allCases, id: \.self) { filterType in
                    OrderManagementFilterButton(
                        filterType: filterType,
                        isSelected: selectedOrderType == filterType,
                        isFocused: focusedFilter == filterType,
                        count: orderManagementViewModel.getOrderCount(for: filterType)
                    ) {
                        selectedOrderType = filterType
                        orderManagementViewModel.setFilter(filterType)
                    }
                    .focused($focusedFilter, equals: filterType)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 60)
        .padding(.top, 40)
    }
    
    // MARK: - Orders List View
    
    private var ordersListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(orderManagementViewModel.filteredOrders, id: \.id) { order in
                    OrderRowView(
                        order: order,
                        isFocused: focusedOrder == order.id
                    ) { action in
                        handleOrderAction(action, for: order)
                    }
                    .focused($focusedOrder, equals: order.id)
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyOrdersView: some View {
        EmptyStateView(
            title: emptyStateTitle,
            message: emptyStateMessage,
            systemImage: "list.bullet.rectangle",
            actionTitle: "Refresh",
            action: {
                Task {
                    await orderManagementViewModel.refreshOrders()
                }
            }
        )
    }
    
    private var emptyStateTitle: String {
        switch selectedOrderType {
        case .all: return "No Orders"
        case .open: return "No Open Orders"
        case .filled: return "No Filled Orders"
        case .cancelled: return "No Cancelled Orders"
        case .pending: return "No Pending Orders"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedOrderType {
        case .all: return "You haven't placed any orders yet. Start trading to see your orders here."
        case .open: return "You don't have any open orders at the moment."
        case .filled: return "No orders have been filled recently."
        case .cancelled: return "No cancelled orders to display."
        case .pending: return "No orders are currently pending."
        }
    }
    
    // MARK: - Actions
    
    private func handleOrderAction(_ action: OrderRowAction, for order: Order) {
        switch action {
        case .view:
            selectedOrder = order
            showingOrderDetail = true
        case .cancel:
            Task {
                await orderManagementViewModel.cancelOrder(order)
            }
        case .modify:
            Task {
                await orderManagementViewModel.modifyOrder(order)
            }
        }
    }
}

// MARK: - Supporting Views

struct OrderStatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct OrderManagementFilterButton: View {
    let filterType: OrderManagementView.OrderFilterType
    let isSelected: Bool
    let isFocused: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filterType.systemImage)
                    .font(.body)
                
                Text(filterType.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .foregroundColor(buttonForegroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var buttonForegroundColor: Color {
        if isFocused {
            return .black
        } else if isSelected {
            return .blue
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return Color.blue.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

// MARK: - OrderRowView

enum OrderRowAction {
    case view
    case cancel
    case modify
}

struct OrderRowView: View {
    let order: Order
    let isFocused: Bool
    let onAction: (OrderRowAction) -> Void
    
    var body: some View {
        Button(action: {
            onAction(.view)
        }) {
            HStack(spacing: 16) {
                // Order Status Indicator
                orderStatusIndicator
                
                // Order Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(order.symbol)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(order.formattedQty)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Text("shares")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("\(order.side.rawValue.uppercased()) • \(order.type.displayName)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if let limitPrice = order.limitPrice {
                            Text(order.formattedLimitPrice)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        } else if let filledAvgPrice = order.filledAvgPrice {
                            Text(order.formattedFilledAvgPrice)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                    
                    HStack {
                        Text(order.createdAt.formatted(.dateTime.month().day().hour().minute()))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(order.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(order.status.uiColor)
                    }
                }
                
                // Action Buttons (only for open orders)
                if order.status == .new || order.status == .partiallyFilled {
                    orderActionButtons
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green, lineWidth: isFocused ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var orderStatusIndicator: some View {
        Circle()
            .fill(order.status.uiColor)
            .frame(width: 12, height: 12)
    }
    
    private var orderActionButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                onAction(.modify)
            }) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                onAction(.cancel)
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - OrderDetailView

struct OrderDetailView: View {
    let order: Order
    @EnvironmentObject private var orderViewModel: OrderManagementViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedAction: OrderDetailAction?
    
    enum OrderDetailAction {
        case close
        case cancel
        case modify
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 30) {
                // Header
                orderDetailHeader
                
                // Order Summary Card
                orderSummaryCard
                
                // Order Details
                orderDetailsSection
                
                // Actions (if applicable)
                if order.status == .new || order.status == .partiallyFilled {
                    orderActionsSection
                }
                
                Spacer()
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            // Auto-focus close button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedAction = .close
            }
        }
    }
    
    private var orderDetailHeader: some View {
        HStack {
            Text("Order Details")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            FocusableButton("Close", systemImage: "xmark") {
                dismiss()
            }
            .focused($focusedAction, equals: .close)
        }
    }
    
    private var orderSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                // Symbol and Status
                VStack(alignment: .leading, spacing: 8) {
                    Text(order.symbol)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(order.status.uiColor)
                            .frame(width: 10, height: 10)
                        
                        Text(order.status.displayName)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(order.status.uiColor)
                    }
                }
                
                Spacer()
                
                // Order Side and Type
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: order.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(order.side == .buy ? .green : .red)
                            .font(.title2)
                        
                        Text(order.side.rawValue.uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(order.side == .buy ? .green : .red)
                    }
                    
                    Text(order.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Quantity and Price Summary
            HStack(spacing: 40) {
                DetailSummaryItem(
                    title: "Quantity",
                    value: order.formattedQty,
                    subtitle: "shares"
                )
                
                if let limitPrice = order.limitPrice {
                    DetailSummaryItem(
                        title: "Limit Price",
                        value: order.formattedLimitPrice,
                        subtitle: "per share"
                    )
                } else if let filledAvgPrice = order.filledAvgPrice {
                    DetailSummaryItem(
                        title: "Filled Price",
                        value: order.formattedFilledAvgPrice,
                        subtitle: "per share"
                    )
                }
                
                if let totalValue = calculateOrderValue() {
                    DetailSummaryItem(
                        title: "Total Value",
                        value: totalValue.formatted(.currency(code: "USD")),
                        subtitle: "estimated"
                    )
                }
                
                Spacer()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(order.status.uiColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var orderDetailsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Order Information")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                OrderDetailRow(title: "Order ID", value: order.id)
                OrderDetailRow(title: "Client Order ID", value: order.clientOrderId ?? "N/A")
                OrderDetailRow(title: "Time in Force", value: order.timeInForce.displayName)
                OrderDetailRow(title: "Order Type", value: order.type.displayName)
                
                if let stopPrice = order.stopPrice {
                    OrderDetailRow(title: "Stop Price", value: order.formattedStopPrice)
                }
                
                OrderDetailRow(
                    title: "Created At",
                    value: order.createdAt.formatted(.dateTime.month().day().year().hour().minute())
                )
                
                if let filledAt = order.filledAt {
                    OrderDetailRow(
                        title: "Filled At",
                        value: filledAt.formatted(.dateTime.month().day().year().hour().minute())
                    )
                }
                
                if let updatedAt = order.updatedAt {
                    OrderDetailRow(
                        title: "Last Updated",
                        value: updatedAt.formatted(.dateTime.month().day().year().hour().minute())
                    )
                }
            }
        }
    }
    
    private var orderActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Actions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                FocusableButton("Modify Order", systemImage: "pencil") {
                    Task {
                        await orderViewModel.modifyOrder(order)
                    }
                }
                .focused($focusedAction, equals: .modify)
                
                FocusableButton("Cancel Order", systemImage: "xmark.circle.fill") {
                    Task {
                        await orderViewModel.cancelOrder(order)
                        dismiss()
                    }
                }
                .focused($focusedAction, equals: .cancel)
                
                Spacer()
            }
        }
    }
    
    private func calculateOrderValue() -> Double? {
        if let orderValue = order.orderValue {
            return orderValue
        }
        
        var price: Double?
        if let filledAvgPrice = order.filledAvgPrice, let priceValue = Double(filledAvgPrice) {
            price = priceValue
        } else if let limitPrice = order.limitPrice, let priceValue = Double(limitPrice) {
            price = priceValue
        }
        
        guard let price = price, let qty = order.qty, let qtyValue = Double(qty) else { return nil }
        return qtyValue * price
    }
}

struct DetailSummaryItem: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct OrderDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Extensions

extension OrderStatus {
    var uiColor: Color {
        switch self {
        case .new, .partiallyFilled, .accepted, .pendingNew:
            return .blue
        case .filled:
            return .green
        case .canceled, .rejected:
            return .red
        case .pendingCancel, .pendingReplace:
            return .orange
        default:
            return .gray
        }
    }
}

// OrderType displayName is already defined in the main Order.swift file

#Preview {
    OrderManagementView()
        .preferredColorScheme(.dark)
}