//
//  PositionDetailView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct PositionDetailView: View {
    let position: Position
    @Environment(\.dismiss) private var dismiss
    @StateObject private var positionDetailViewModel: PositionDetailViewModel
    @StateObject private var chartViewModel = ChartViewModel()
    @FocusState private var focusedAction: ActionButton?
    
    enum ActionButton: Hashable {
        case increasePosition
        case decreasePosition
        case closePosition
        case setAlert
        case viewChart
        case close
    }
    
    init(position: Position) {
        self.position = position
        self._positionDetailViewModel = StateObject(wrappedValue: PositionDetailViewModel(position: position))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Left Panel - Position Details
                positionDetailsPanel
                    .frame(maxWidth: .infinity)
                
                // Right Panel - Chart and Actions
                chartAndActionsPanel
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            Task {
                await positionDetailViewModel.loadDetailedData()
                await chartViewModel.loadChart(for: position.symbol)
            }
            
            // Auto-focus first action
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedAction = .viewChart
            }
        }
    }
    
    // MARK: - Position Details Panel
    
    private var positionDetailsPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                positionHeader
                
                // Key Metrics
                keyMetricsSection
                
                // Performance Metrics
                performanceSection
                
                // Position History
                positionHistorySection
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
        }
    }
    
    private var positionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(position.symbol)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .focused($focusedAction, equals: .close)
                .foregroundColor(.gray)
            }
            
            if let assetName = positionDetailViewModel.assetName {
                Text(assetName)
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 16) {
                PositionBadge(
                    text: position.side.rawValue.uppercased(),
                    color: position.side == .long ? .blue : .orange
                )
                
                if let sector = positionDetailViewModel.sector {
                    PositionBadge(text: sector, color: .purple)
                }
            }
        }
    }
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Position Details")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Quantity",
                    value: position.quantity.formatted(.number.precision(.fractionLength(0))),
                    subtitle: "Shares"
                )
                
                MetricCard(
                    title: "Avg Entry Price",
                    value: position.avgEntryPrice.formatted(.currency(code: "USD")),
                    subtitle: "Per share"
                )
                
                MetricCard(
                    title: "Current Price",
                    value: positionDetailViewModel.currentPrice.formatted(.currency(code: "USD")),
                    subtitle: "Per share",
                    changeValue: positionDetailViewModel.priceChange,
                    changePercent: positionDetailViewModel.priceChangePercent
                )
                
                MetricCard(
                    title: "Market Value",
                    value: position.marketValue.formatted(.currency(code: "USD")),
                    subtitle: "Total value"
                )
            }
        }
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Large P&L Display
            VStack(spacing: 8) {
                HStack {
                    Text("Unrealized P&L")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                
                HStack(alignment: .bottom, spacing: 12) {
                    Text(position.unrealizedPL.formatted(.currency(code: "USD")))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(position.unrealizedPL >= 0 ? .green : .red)
                    
                    Text("(\(position.unrealizedPLPercent.formatted(.percent.precision(.fractionLength(2)))))")
                        .font(.title2)
                        .foregroundColor(position.unrealizedPL >= 0 ? .green : .red)
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill((position.unrealizedPL >= 0 ? Color.green : Color.red).opacity(0.1))
                    .stroke((position.unrealizedPL >= 0 ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
            )
            
            // Additional Performance Metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Today's P&L",
                    value: positionDetailViewModel.todaysPL.formatted(.currency(code: "USD")),
                    subtitle: "Day change",
                    valueColor: positionDetailViewModel.todaysPL >= 0 ? .green : .red
                )
                
                MetricCard(
                    title: "Cost Basis",
                    value: positionDetailViewModel.costBasis.formatted(.currency(code: "USD")),
                    subtitle: "Total investment"
                )
            }
        }
    }
    
    private var positionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if positionDetailViewModel.recentOrders.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(positionDetailViewModel.recentOrders.prefix(5), id: \.id) { order in
                        OrderHistoryRow(order: order)
                    }
                }
            }
        }
    }
    
    // MARK: - Chart and Actions Panel
    
    private var chartAndActionsPanel: some View {
        VStack(spacing: 30) {
            // Interactive Chart
            chartSection
            
            // Quick Actions
            actionsSection
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Chart")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if chartViewModel.isLoading {
                LoadingStateView(message: "Loading chart...")
                    .frame(height: 400)
            } else {
                InteractiveChartView(symbol: position.symbol)
                    .environmentObject(chartViewModel)
                    .frame(height: 400)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Actions")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ActionButtonView(
                    title: "Increase Position",
                    systemImage: "plus.circle.fill",
                    color: .green,
                    isFocused: focusedAction == .increasePosition
                ) {
                    Task {
                        await positionDetailViewModel.increasePosition()
                    }
                }
                .focused($focusedAction, equals: .increasePosition)
                
                ActionButtonView(
                    title: "Decrease Position", 
                    systemImage: "minus.circle.fill",
                    color: .orange,
                    isFocused: focusedAction == .decreasePosition
                ) {
                    Task {
                        await positionDetailViewModel.decreasePosition()
                    }
                }
                .focused($focusedAction, equals: .decreasePosition)
                
                ActionButtonView(
                    title: "Close Position",
                    systemImage: "xmark.circle.fill",
                    color: .red,
                    isFocused: focusedAction == .closePosition
                ) {
                    Task {
                        await positionDetailViewModel.closePosition()
                    }
                }
                .focused($focusedAction, equals: .closePosition)
                
                ActionButtonView(
                    title: "Set Alert",
                    systemImage: "bell.fill",
                    color: .blue,
                    isFocused: focusedAction == .setAlert
                ) {
                    positionDetailViewModel.showAlertSetup = true
                }
                .focused($focusedAction, equals: .setAlert)
            }
        }
    }
}

// MARK: - Supporting Views

struct PositionBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.2))
            )
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let valueColor: Color
    let changeValue: Decimal?
    let changePercent: Double?
    
    init(
        title: String, 
        value: String, 
        subtitle: String,
        valueColor: Color = .white,
        changeValue: Decimal? = nil,
        changePercent: Double? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.valueColor = valueColor
        self.changeValue = changeValue
        self.changePercent = changePercent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
            
            HStack {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let changeValue = changeValue, let changePercent = changePercent {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(changeValue.formatted(.currency(code: "USD")))
                            .font(.caption)
                            .foregroundColor(changeValue >= 0 ? .green : .red)
                        
                        Text("(\(changePercent.formatted(.percent.precision(.fractionLength(2)))))")
                            .font(.caption2)
                            .foregroundColor(changeValue >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct ActionButtonView: View {
    let title: String
    let systemImage: String
    let color: Color
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(isFocused ? .white : color)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isFocused ? .white : color)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: isFocused ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct OrderHistoryRow: View {
    let order: Order
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: order.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(order.side == .buy ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(order.side.rawValue.uppercased()) \(order.quantity.formatted(.number))")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let executedAt = order.executedAt {
                    Text(executedAt.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let filledPrice = order.filledPrice {
                Text(filledPrice.formatted(.currency(code: "USD")))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PositionDetailView(
        position: Position(
            symbol: "AAPL",
            quantity: 100,
            side: .long,
            marketValue: 15000,
            avgEntryPrice: 140.50,
            unrealizedPL: 950.00,
            unrealizedPLPercent: 0.067
        )
    )
    .preferredColorScheme(.dark)
}