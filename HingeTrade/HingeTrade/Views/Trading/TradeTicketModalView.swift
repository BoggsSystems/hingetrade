//
//  TradeTicketModalView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct TradeTicketModalView: View {
    let symbol: String
    let videoContext: VideoContext?
    
    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var tradeTicketViewModel: TradeTicketViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: TradeField?
    
    enum TradeField: Hashable {
        case symbol
        case orderType
        case side
        case quantity
        case limitPrice
        case stopPrice
        case timeInForce
        case preview
        case submit
        case cancel
    }
    
    init(symbol: String, videoContext: VideoContext? = nil) {
        self.symbol = symbol
        self.videoContext = videoContext
        self._tradeTicketViewModel = StateObject(wrappedValue: TradeTicketViewModel(symbol: symbol, videoContext: videoContext))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Left Panel - Trade Form
                tradeFormPanel
                    .frame(maxWidth: .infinity)
                
                // Right Panel - Market Data & Preview
                marketDataPanel
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            Task {
                await tradeTicketViewModel.initialize()
            }
            
            // Auto-focus first field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .side
            }
        }
        .alert("Order Error", isPresented: $tradeTicketViewModel.showingError) {
            Button("OK") {
                tradeTicketViewModel.dismissError()
            }
        } message: {
            Text(tradeTicketViewModel.error?.localizedDescription ?? "An error occurred")
        }
        .alert("Confirm Order", isPresented: $tradeTicketViewModel.showingConfirmation) {
            Button("Cancel", role: .cancel) {
                tradeTicketViewModel.cancelConfirmation()
            }
            
            Button("Submit Order") {
                Task {
                    await tradeTicketViewModel.submitOrder()
                }
            }
            .focused($focusedField, equals: .submit)
        } message: {
            Text(tradeTicketViewModel.confirmationMessage)
        }
    }
    
    // MARK: - Trade Form Panel
    
    private var tradeFormPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                tradeFormHeader
                
                // Symbol and Quote Info
                symbolSection
                
                // Order Configuration
                orderConfigurationSection
                
                // Risk and Compliance
                riskSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
        }
    }
    
    private var tradeFormHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Place Order")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .focused($focusedField, equals: .cancel)
                .foregroundColor(.gray)
            }
            
            if let context = videoContext {
                HStack(spacing: 8) {
                    Image(systemName: "tv.fill")
                        .foregroundColor(.blue)
                    
                    Text("From: \(context.videoTitle)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
    }
    
    private var symbolSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Asset")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Symbol Display
                VStack(alignment: .leading, spacing: 4) {
                    Text("Symbol")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(tradeTicketViewModel.symbol)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Current Price
                if let quote = tradeTicketViewModel.currentQuote {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Current Price")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        Text(quote.bidPrice.formatted(.currency(code: "USD")))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Text((quote.dailyChange ?? 0).formatted(.currency(code: "USD")))
                                .font(.caption)
                            
                            Text("(\((quote.dailyChangePercent ?? 0).formatted(.percent.precision(.fractionLength(2)))))")
                                .font(.caption)
                        }
                        .foregroundColor((quote.dailyChange ?? 0) >= 0 ? .green : .red)
                    }
                }
            }
            
            // Asset name if available
            if let assetName = tradeTicketViewModel.assetName {
                Text(assetName)
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var orderConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Order Details")
                .font(.headline)
                .foregroundColor(.white)
            
            // Buy/Sell Selection
            sideSelectionView
            
            // Order Type Selection
            orderTypeSelectionView
            
            // Quantity Input
            quantityInputView
            
            // Price Inputs (conditional)
            if tradeTicketViewModel.orderType == .limit || tradeTicketViewModel.orderType == .stopLimit {
                limitPriceInputView
            }
            
            if tradeTicketViewModel.orderType == .stop || tradeTicketViewModel.orderType == .stopLimit {
                stopPriceInputView
            }
            
            // Time in Force
            timeInForceSelectionView
        }
    }
    
    private var sideSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Action")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                SideButton(
                    side: .buy,
                    isSelected: tradeTicketViewModel.side == .buy,
                    isFocused: focusedField == .side && tradeTicketViewModel.side == .buy
                ) {
                    tradeTicketViewModel.setSide(.buy)
                }
                .focused($focusedField, equals: .side)
                
                SideButton(
                    side: .sell,
                    isSelected: tradeTicketViewModel.side == .sell,
                    isFocused: focusedField == .side && tradeTicketViewModel.side == .sell
                ) {
                    tradeTicketViewModel.setSide(.sell)
                }
            }
        }
    }
    
    private var orderTypeSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Order Type")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                ForEach(OrderType.allCases, id: \.self) { orderType in
                    OrderTypeButton(
                        orderType: orderType,
                        isSelected: tradeTicketViewModel.orderType == orderType,
                        isFocused: focusedField == .orderType
                    ) {
                        tradeTicketViewModel.orderType = orderType
                    }
                }
            }
            .focused($focusedField, equals: .orderType)
        }
    }
    
    private var quantityInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quantity")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if tradeTicketViewModel.orderType != .market {
                    Text("Est. Total: \(tradeTicketViewModel.estimatedTotal.formatted(.currency(code: "USD")))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 12) {
                // Quantity Input
                TextField("0", value: $tradeTicketViewModel.quantity, format: .number.precision(.fractionLength(0...6)))
                    .textFieldStyle(TradeInputFieldStyle(isFocused: focusedField == .quantity))
                    .focused($focusedField, equals: .quantity)
                    .keyboardType(.decimalPad)
                
                Text("shares")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            // Quick Quantity Buttons
            HStack(spacing: 8) {
                ForEach([10, 25, 50, 100], id: \.self) { amount in
                    Button("\(amount)") {
                        tradeTicketViewModel.setQuantity(Decimal(amount))
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var limitPriceInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Limit Price")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                TextField("0.00", value: $tradeTicketViewModel.limitPrice, format: .currency(code: "USD"))
                    .textFieldStyle(TradeInputFieldStyle(isFocused: focusedField == .limitPrice))
                    .focused($focusedField, equals: .limitPrice)
                    .keyboardType(.decimalPad)
                
                // Quick Price Buttons
                VStack(spacing: 4) {
                    Button("+1¢") {
                        tradeTicketViewModel.adjustLimitPrice(by: 0.01)
                    }
                    .font(.caption2)
                    .foregroundColor(.green)
                    .buttonStyle(PlainButtonStyle())
                    
                    Button("-1¢") {
                        tradeTicketViewModel.adjustLimitPrice(by: -0.01)
                    }
                    .font(.caption2)
                    .foregroundColor(.red)
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var stopPriceInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stop Price")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("0.00", value: $tradeTicketViewModel.stopPrice, format: .currency(code: "USD"))
                .textFieldStyle(TradeInputFieldStyle(isFocused: focusedField == .stopPrice))
                .focused($focusedField, equals: .stopPrice)
                .keyboardType(.decimalPad)
        }
    }
    
    private var timeInForceSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time in Force")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                ForEach(OrderTimeInForce.allCases, id: \.self) { tif in
                    TimeInForceButton(
                        timeInForce: tif,
                        isSelected: tradeTicketViewModel.timeInForce == tif,
                        isFocused: focusedField == .timeInForce
                    ) {
                        tradeTicketViewModel.timeInForce = tif
                    }
                }
            }
            .focused($focusedField, equals: .timeInForce)
        }
    }
    
    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Assessment")
                .font(.headline)
                .foregroundColor(.white)
            
            // Risk Warnings
            if !tradeTicketViewModel.riskWarnings.isEmpty {
                ForEach(tradeTicketViewModel.riskWarnings, id: \.self) { warning in
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Buying Power Check
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Buying Power")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(appState.buyingPower.formatted(.currency(code: "USD")))
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Estimated Cost")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(tradeTicketViewModel.estimatedTotal.formatted(.currency(code: "USD")))
                        .font(.caption)
                        .foregroundColor(tradeTicketViewModel.estimatedTotal <= appState.buyingPower ? .green : .red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Preview Button
            FocusableButton("Preview Order", systemImage: "eye.fill") {
                Task {
                    await tradeTicketViewModel.previewOrder()
                }
            }
            .focused($focusedField, equals: .preview)
            .disabled(!tradeTicketViewModel.isOrderValid || tradeTicketViewModel.isLoading)
            
            // Submit Button
            FocusableButton(
                tradeTicketViewModel.isLoading ? "Submitting..." : "Place Order",
                systemImage: "checkmark.circle.fill"
            ) {
                Task {
                    await tradeTicketViewModel.confirmOrder()
                }
            }
            .disabled(!tradeTicketViewModel.isOrderValid || tradeTicketViewModel.isLoading)
            
            // Compliance Disclaimer
            Text("This is not investment advice. Trading involves risk of loss.")
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Market Data Panel
    
    private var marketDataPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 30) {
                // Live Chart
                chartSection
                
                // Market Data
                marketDataSection
                
                // Order Preview
                if tradeTicketViewModel.showingPreview {
                    orderPreviewSection
                }
                
                // Related Videos (if available)
                if let context = videoContext {
                    relatedContentSection(context)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Live Chart")
                .font(.headline)
                .foregroundColor(.white)
            
            if tradeTicketViewModel.isLoadingChart {
                LoadingStateView(message: "Loading chart...")
                    .frame(height: 250)
            } else {
                InteractiveChartView(symbol: tradeTicketViewModel.symbol)
                    .environmentObject(ChartViewModel())
                    .frame(height: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.02))
                    )
            }
        }
    }
    
    private var marketDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Data")
                .font(.headline)
                .foregroundColor(.white)
            
            if let quote = tradeTicketViewModel.currentQuote {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    MarketDataItem(title: "Bid", value: quote.bidPrice.formatted(.currency(code: "USD")))
                    MarketDataItem(title: "Ask", value: quote.askPrice.formatted(.currency(code: "USD")))
                    MarketDataItem(title: "Volume", value: (quote.volume ?? 0).formatted(.number.notation(.compactName)))
                    MarketDataItem(title: "Day High", value: (quote.dailyHigh ?? 0).formatted(.currency(code: "USD")))
                    MarketDataItem(title: "Day Low", value: (quote.dailyLow ?? 0).formatted(.currency(code: "USD")))
                }
            } else {
                LoadingStateView(message: "Loading market data...")
                    .frame(height: 120)
            }
        }
    }
    
    private var orderPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Preview")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                OrderPreviewRow(title: "Symbol", value: tradeTicketViewModel.symbol)
                OrderPreviewRow(title: "Action", value: tradeTicketViewModel.side.rawValue.capitalized)
                OrderPreviewRow(title: "Quantity", value: tradeTicketViewModel.quantity.formatted(.number))
                OrderPreviewRow(title: "Order Type", value: tradeTicketViewModel.orderType.displayName)
                
                if tradeTicketViewModel.orderType != .market {
                    OrderPreviewRow(title: "Est. Total", value: tradeTicketViewModel.estimatedTotal.formatted(.currency(code: "USD")))
                }
                
                OrderPreviewRow(title: "Time in Force", value: tradeTicketViewModel.timeInForce.displayName)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func relatedContentSection(_ context: VideoContext) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Content")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(context.videoTitle)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("by \(context.creatorName)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let insight = context.keyInsight {
                    Text("💡 \(insight)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Views and Components

struct SideButton: View {
    let side: OrderSide
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(buttonForegroundColor)
                
                Text(side.rawValue.uppercased())
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(buttonForegroundColor)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var buttonForegroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return side == .buy ? .green : .red
        } else {
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return side == .buy ? .green : .red
        } else if isSelected {
            return (side == .buy ? Color.green : Color.red).opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isSelected || isFocused {
            return side == .buy ? .green : .red
        } else {
            return .gray
        }
    }
}

struct OrderTypeButton: View {
    let orderType: OrderType
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(orderType.displayName)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(buttonForegroundColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderColor, lineWidth: isSelected || isFocused ? 1 : 0)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
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
        return isFocused ? .green : .blue
    }
}

struct TimeInForceButton: View {
    let timeInForce: OrderTimeInForce
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeInForce.displayName)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .purple : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.purple.opacity(0.2) : Color.white.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct TradeInputFieldStyle: TextFieldStyle {
    let isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.title2)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused ? Color.green : Color.gray, lineWidth: isFocused ? 2 : 1)
                    )
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct MarketDataItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct OrderPreviewRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Supporting Types

struct VideoContext {
    let videoId: String
    let videoTitle: String
    let creatorName: String
    let marketDirection: VideoContent.MarketDirection?
    let keyInsight: String?
    let mentionedSymbols: [String]
    let priceTargets: [PriceTarget]
}

enum TicketOrderType: String, CaseIterable {
    case market
    case limit
    case stop
    case stopLimit
    
    var displayName: String {
        switch self {
        case .market: return "Market"
        case .limit: return "Limit"
        case .stop: return "Stop"
        case .stopLimit: return "Stop Limit"
        }
    }
}

enum TimeInForce: String, CaseIterable, Codable {
    case day
    case gtc
    case ioc
    case fok
    
    var displayName: String {
        switch self {
        case .day: return "Day"
        case .gtc: return "GTC"
        case .ioc: return "IOC"
        case .fok: return "FOK"
        }
    }
}

#Preview {
    TradeTicketModalView(
        symbol: "AAPL",
        videoContext: VideoContext(
            videoId: "test",
            videoTitle: "Tesla Earnings Beat: What This Means for EV Sector",
            creatorName: "MarketMike",
            marketDirection: .bullish,
            keyInsight: "Strong delivery growth suggests continued momentum",
            mentionedSymbols: ["TSLA", "NIO"],
            priceTargets: []
        )
    )
    .environmentObject(AppStateViewModel())
    .preferredColorScheme(.dark)
}