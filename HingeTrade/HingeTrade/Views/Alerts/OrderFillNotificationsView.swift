//
//  OrderFillNotificationsView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct OrderFillNotificationsView: View {
    @StateObject private var orderFillViewModel = OrderFillNotificationViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: OrderFillSection?
    
    @State private var selectedFilter: OrderFillFilter = .all
    @State private var selectedOrder: Order?
    
    enum OrderFillSection: Hashable {
        case back
        case filter(OrderFillFilter)
        case order(String)
        case preferences
    }
    
    enum OrderFillFilter: String, CaseIterable {
        case all = "All"
        case filled = "Filled"
        case partialFill = "Partial"
        case pending = "Pending"
        case cancelled = "Cancelled"
        
        var systemImage: String {
            switch self {
            case .all: return "list.bullet"
            case .filled: return "checkmark.circle.fill"
            case .partialFill: return "clock.badge.checkmark.fill"
            case .pending: return "clock.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .filled: return .green
            case .partialFill: return .orange
            case .pending: return .yellow
            case .cancelled: return .red
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                orderFillHeader
                
                // Filters
                filtersView
                
                // Content
                if orderFillViewModel.isLoading {
                    LoadingStateView(message: "Loading order notifications...")
                        .frame(maxHeight: .infinity)
                } else if orderFillViewModel.filteredOrders.isEmpty {
                    emptyStateView
                } else {
                    orderNotificationsListView
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await orderFillViewModel.loadOrders()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(item: $selectedOrder) { order in
            OrderDetailNotificationView(order: order)
                .environmentObject(orderFillViewModel)
        }
    }
    
    // MARK: - Header
    
    private var orderFillHeader: some View {
        VStack(spacing: 20) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                Text("Order Fill Notifications")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                FocusableButton("Preferences", systemImage: "gear") {
                    // Show notification preferences
                }
                .focused($focusedSection, equals: .preferences)
            }
            
            // Stats Row
            orderStatsView
        }
        .padding(.horizontal, 60)
        .padding(.top, 40)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var orderStatsView: some View {
        HStack(spacing: 40) {
            OrderFillStatCard(
                title: "Filled Today",
                value: orderFillViewModel.filledTodayCount.formatted(.number),
                color: .green
            )
            
            OrderFillStatCard(
                title: "Pending Orders",
                value: orderFillViewModel.pendingOrdersCount.formatted(.number),
                color: .orange
            )
            
            OrderFillStatCard(
                title: "Total Volume",
                value: orderFillViewModel.totalVolumeToday.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                color: .blue
            )
            
            OrderFillStatCard(
                title: "Fill Rate",
                value: orderFillViewModel.fillRate.formatted(.percent.precision(.fractionLength(0))),
                color: orderFillViewModel.fillRate > 0.8 ? .green : .orange
            )
            
            Spacer()
        }
    }
    
    // MARK: - Filters
    
    private var filtersView: some View {
        HStack(spacing: 16) {
            ForEach(OrderFillFilter.allCases, id: \.self) { filter in
                OrderFilterButton(
                    filter: filter,
                    isSelected: selectedFilter == filter,
                    isFocused: focusedSection == .filter(filter),
                    count: orderFillViewModel.getCount(for: filter)
                ) {
                    selectedFilter = filter
                    orderFillViewModel.setFilter(filter)
                }
                .focused($focusedSection, equals: .filter(filter))
            }
            
            Spacer()
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Content
    
    private var orderNotificationsListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(orderFillViewModel.filteredOrders, id: \.id) { order in
                    OrderNotificationRow(
                        order: order,
                        isFocused: focusedSection == .order(order.id)
                    ) {
                        selectedOrder = order
                    }
                    .focused($focusedSection, equals: .order(order.id))
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            title: emptyStateTitle,
            message: emptyStateMessage,
            systemImage: "bell.slash",
            actionTitle: nil,
            action: nil
        )
        .frame(maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return "No Order Notifications"
        case .filled:
            return "No Filled Orders"
        case .partialFill:
            return "No Partial Fills"
        case .pending:
            return "No Pending Orders"
        case .cancelled:
            return "No Cancelled Orders"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "Order fill notifications will appear here when your trades are executed"
        case .filled:
            return "You haven't had any orders filled recently"
        case .partialFill:
            return "No orders have been partially filled"
        case .pending:
            return "You don't have any pending orders"
        case .cancelled:
            return "No orders have been cancelled recently"
        }
    }
}

// MARK: - Supporting Views

struct OrderFillStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct OrderFilterButton: View {
    let filter: OrderFillNotificationsView.OrderFillFilter
    let isSelected: Bool
    let isFocused: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.systemImage)
                    .font(.body)
                    .foregroundColor(filter.color)
                
                Text(filter.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
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
            return filter.color
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return filter.color.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return filter.color
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

struct OrderNotificationRow: View {
    let order: Order
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Status Indicator
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                    .frame(width: 24)
                
                // Order Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(order.symbol)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text("\(order.side.rawValue.capitalized) \(order.formattedQty)")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Order value
                        VStack(alignment: .trailing, spacing: 2) {
                            if let filledAvgPrice = order.filledAvgPrice, let priceValue = Double(filledAvgPrice) {
                                Text(priceValue.formatted(.currency(code: "USD")))
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            } else if let limitPrice = order.limitPrice, let priceValue = Double(limitPrice) {
                                Text("@ \(priceValue.formatted(.currency(code: "USD")))")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            
                            Text(order.formattedOrderValue)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        // Order type and time in force
                        HStack(spacing: 4) {
                            Text(order.type.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.blue.opacity(0.2))
                                )
                            
                            Text(order.timeInForce.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.purple.opacity(0.2))
                                )
                        }
                        
                        Spacer()
                        
                        // Timestamp
                        if let filledAt = order.filledAt {
                            Text("Filled \(filledAt.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if let submittedAt = order.submittedAt {
                            Text("Submitted \(submittedAt.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Created \(order.createdAt.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Status indicator
                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var statusIcon: String {
        switch order.status {
        case .filled:
            return "checkmark.circle.fill"
        case .partiallyFilled:
            return "clock.badge.checkmark.fill"
        case .pendingNew, .pendingCancel, .pendingReplace:
            return "clock.fill"
        case .canceled:
            return "xmark.circle.fill"
        case .rejected:
            return "exclamationmark.triangle.fill"
        default:
            return "clock.fill"
        }
    }
    
    private var statusColor: Color {
        switch order.status {
        case .filled:
            return .green
        case .partiallyFilled:
            return .orange
        case .pendingNew, .pendingCancel, .pendingReplace:
            return .yellow
        case .canceled:
            return .red
        case .rejected:
            return .red
        default:
            return .gray
        }
    }
    
    private var borderColor: Color {
        switch order.status {
        case .filled:
            return .green
        case .partiallyFilled:
            return .orange
        case .pendingNew, .pendingCancel, .pendingReplace:
            return .yellow
        case .canceled, .rejected:
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Order Detail View

struct OrderDetailNotificationView: View {
    let order: Order
    
    @EnvironmentObject private var orderFillViewModel: OrderFillNotificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Order Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Detailed order view would go here")
                    .foregroundColor(.gray)
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    OrderFillNotificationsView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}