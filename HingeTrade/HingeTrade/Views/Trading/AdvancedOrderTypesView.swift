//
//  AdvancedOrderTypesView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct AdvancedOrderTypesView: View {
    let symbol: String
    let currentPrice: Decimal
    
    @StateObject private var advancedOrderViewModel = AdvancedOrderViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: AdvancedOrderSection?
    
    @State private var selectedOrderType: AdvancedOrderType = .stopLoss
    @State private var quantity: String = "100"
    @State private var side: OrderSide = .buy
    @State private var showingRiskAnalysis = false
    
    enum AdvancedOrderSection: Hashable {
        case back
        case orderType(AdvancedOrderType)
        case quantity
        case side
        case parameter(String)
        case riskAnalysis
        case preview
        case submit
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                advancedOrderHeader
                
                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Order Type Selection
                        orderTypeSelectionSection
                        
                        // Basic Order Parameters
                        basicParametersSection
                        
                        // Advanced Parameters (based on selected order type)
                        advancedParametersSection
                        
                        // Risk Analysis
                        riskAnalysisSection
                        
                        // Order Preview
                        orderPreviewSection
                        
                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 30)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            advancedOrderViewModel.initialize(symbol: symbol, currentPrice: currentPrice)
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(isPresented: $showingRiskAnalysis) {
            RiskAnalysisDetailView(
                symbol: symbol,
                orderConfig: advancedOrderViewModel.currentConfig
            )
        }
    }
    
    // MARK: - Header
    
    private var advancedOrderHeader: some View {
        VStack(spacing: 20) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Advanced Orders")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(symbol)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Current price display
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Current Price")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(currentPrice.formatted(.currency(code: "USD")))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Risk indicator
            if let riskLevel = advancedOrderViewModel.currentRiskLevel {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: riskLevel.color))
                        .frame(width: 12, height: 12)
                    
                    Text(riskLevel.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let positionValue = advancedOrderViewModel.estimatedPositionValue {
                        Text("Position: \(positionValue.formatted(.currency(code: "USD")))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
            }
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
    
    // MARK: - Order Type Selection
    
    private var orderTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Order Type")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(AdvancedOrderType.allCases, id: \.self) { orderType in
                    AdvancedOrderTypeButton(
                        orderType: orderType,
                        isSelected: selectedOrderType == orderType,
                        isFocused: focusedSection == .orderType(orderType)
                    ) {
                        selectedOrderType = orderType
                        advancedOrderViewModel.setOrderType(orderType)
                    }
                    .focused($focusedSection, equals: .orderType(orderType))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Basic Parameters
    
    private var basicParametersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Order Parameters")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                // Quantity
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quantity")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextField("100", text: $quantity)
                        .textFieldStyle(AdvancedOrderFieldStyle(isFocused: focusedSection == .quantity))
                        .focused($focusedSection, equals: .quantity)
                        .keyboardType(.numberPad)
                        .onChange(of: quantity) { _ in
                            advancedOrderViewModel.updateQuantity(Int(quantity) ?? 0)
                        }
                }
                
                // Side
                VStack(alignment: .leading, spacing: 8) {
                    Text("Side")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    OrderSideSelector(
                        selectedSide: $side,
                        isFocused: focusedSection == .side
                    ) {
                        advancedOrderViewModel.updateSide(side)
                    }
                    .focused($focusedSection, equals: .side)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Advanced Parameters
    
    private var advancedParametersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            switch selectedOrderType {
            case .stopLoss, .takeProfit:
                stopLossTakeProfitParameters
            case .trailingStop:
                trailingStopParameters
            case .bracketOrder:
                bracketOrderParameters
            case .stopLimit:
                stopLimitParameters
            default:
                basicAdvancedParameters
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var stopLossTakeProfitParameters: some View {
        VStack(spacing: 16) {
            AdvancedOrderParameterField(
                title: selectedOrderType == .stopLoss ? "Stop Price" : "Target Price",
                value: $advancedOrderViewModel.stopPrice,
                isFocused: focusedSection == .parameter("stopPrice"),
                placeholder: currentPrice.formatted(.currency(code: "USD"))
            )
            .focused($focusedSection, equals: .parameter("stopPrice"))
            
            if selectedOrderType == .stopLoss {
                HStack {
                    Text("Risk Amount:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let riskAmount = advancedOrderViewModel.estimatedRiskAmount {
                        Text(riskAmount.formatted(.currency(code: "USD")))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private var trailingStopParameters: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                AdvancedOrderParameterField(
                    title: "Trail Amount ($)",
                    value: $advancedOrderViewModel.trailAmount,
                    isFocused: focusedSection == .parameter("trailAmount"),
                    placeholder: "5.00"
                )
                .focused($focusedSection, equals: .parameter("trailAmount"))
                
                Text("OR")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                AdvancedOrderParameterField(
                    title: "Trail Percent (%)",
                    value: $advancedOrderViewModel.trailPercent,
                    isFocused: focusedSection == .parameter("trailPercent"),
                    placeholder: "5.0"
                )
                .focused($focusedSection, equals: .parameter("trailPercent"))
            }
            
            Text("Trailing stop will adjust automatically as price moves in your favor")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private var bracketOrderParameters: some View {
        VStack(spacing: 16) {
            AdvancedOrderParameterField(
                title: "Take Profit Price",
                value: $advancedOrderViewModel.takeProfitPrice,
                isFocused: focusedSection == .parameter("takeProfitPrice"),
                placeholder: (currentPrice * 1.1).formatted(.currency(code: "USD"))
            )
            .focused($focusedSection, equals: .parameter("takeProfitPrice"))
            
            AdvancedOrderParameterField(
                title: "Stop Loss Price",
                value: $advancedOrderViewModel.stopLossPrice,
                isFocused: focusedSection == .parameter("stopLossPrice"),
                placeholder: (currentPrice * 0.95).formatted(.currency(code: "USD"))
            )
            .focused($focusedSection, equals: .parameter("stopLossPrice"))
            
            if let riskReward = advancedOrderViewModel.riskRewardRatio {
                HStack {
                    Text("Risk/Reward Ratio:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("1:\(riskReward.formatted(.number.precision(.fractionLength(2))))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(riskReward >= 2 ? .green : .orange)
                }
            }
        }
    }
    
    private var stopLimitParameters: some View {
        VStack(spacing: 16) {
            AdvancedOrderParameterField(
                title: "Stop Price",
                value: $advancedOrderViewModel.stopPrice,
                isFocused: focusedSection == .parameter("stopPrice"),
                placeholder: currentPrice.formatted(.currency(code: "USD"))
            )
            .focused($focusedSection, equals: .parameter("stopPrice"))
            
            AdvancedOrderParameterField(
                title: "Limit Price",
                value: $advancedOrderViewModel.limitPrice,
                isFocused: focusedSection == .parameter("limitPrice"),
                placeholder: currentPrice.formatted(.currency(code: "USD"))
            )
            .focused($focusedSection, equals: .parameter("limitPrice"))
        }
    }
    
    private var basicAdvancedParameters: some View {
        VStack(spacing: 16) {
            Text("Additional parameters for \(selectedOrderType.displayName)")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text(selectedOrderType.description)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Risk Analysis
    
    private var riskAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Risk Analysis")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                FocusableButton("Details", systemImage: "chart.bar.xaxis") {
                    showingRiskAnalysis = true
                }
                .focused($focusedSection, equals: .riskAnalysis)
            }
            
            if let riskAssessment = advancedOrderViewModel.riskAssessment {
                RiskAnalysisCard(riskAssessment: riskAssessment)
            } else {
                Text("Enter order parameters to see risk analysis")
                    .font(.body)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Order Preview
    
    private var orderPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Preview")
                .font(.headline)
                .foregroundColor(.white)
            
            if let preview = advancedOrderViewModel.orderPreview {
                OrderPreviewCard(
                    preview: preview,
                    isFocused: focusedSection == .preview
                )
                .focused($focusedSection, equals: .preview)
            } else {
                Text("Complete order parameters to see preview")
                    .font(.body)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            FocusableButton(
                advancedOrderViewModel.isSubmitting ? "Placing Order..." : "Place Advanced Order",
                systemImage: "bolt.circle.fill"
            ) {
                Task {
                    await submitAdvancedOrder()
                }
            }
            .focused($focusedSection, equals: .submit)
            .disabled(!advancedOrderViewModel.canSubmitOrder || advancedOrderViewModel.isSubmitting)
            
            if !advancedOrderViewModel.canSubmitOrder {
                Text(advancedOrderViewModel.validationMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Actions
    
    private func submitAdvancedOrder() async {
        await advancedOrderViewModel.submitOrder()
        
        // Show success and dismiss
        if !advancedOrderViewModel.hasError {
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct AdvancedOrderTypeButton: View {
    let orderType: AdvancedOrderType
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: orderType.systemImage)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text(orderType.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(orderType.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var iconColor: Color {
        Color(hex: orderType.riskLevel.color)
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return Color.white.opacity(0.1)
        } else if isSelected {
            return Color(hex: orderType.riskLevel.color).opacity(0.2)
        } else {
            return Color.white.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return Color(hex: orderType.riskLevel.color)
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

struct AdvancedOrderFieldStyle: TextFieldStyle {
    let isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .stroke(isFocused ? Color.green : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct AdvancedOrderParameterField: View {
    let title: String
    @Binding var value: String
    let isFocused: Bool
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $value)
                .textFieldStyle(AdvancedOrderFieldStyle(isFocused: isFocused))
                .keyboardType(.decimalPad)
        }
    }
}

struct OrderSideSelector: View {
    @Binding var selectedSide: OrderSide
    let isFocused: Bool
    let onChange: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: { 
                selectedSide = .buy
                onChange()
            }) {
                Text("BUY")
                    .font(.body)
                    .fontWeight(selectedSide == .buy ? .bold : .regular)
                    .foregroundColor(selectedSide == .buy ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedSide == .buy ? Color.green : Color.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { 
                selectedSide = .sell
                onChange()
            }) {
                Text("SELL")
                    .font(.body)
                    .fontWeight(selectedSide == .sell ? .bold : .regular)
                    .foregroundColor(selectedSide == .sell ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedSide == .sell ? Color.red : Color.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .stroke(isFocused ? Color.green : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    AdvancedOrderTypesView(symbol: "AAPL", currentPrice: 175.50)
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}