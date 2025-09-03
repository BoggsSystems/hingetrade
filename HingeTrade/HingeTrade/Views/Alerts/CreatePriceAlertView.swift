//
//  CreatePriceAlertView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct CreatePriceAlertView: View {
    let symbol: String?
    
    @EnvironmentObject private var alertsViewModel: PriceAlertsViewModel
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: CreateAlertField?
    
    @State private var selectedSymbol = ""
    @State private var alertType: AlertCondition = .above
    @State private var targetPrice = ""
    @State private var percentChange = ""
    @State private var expiresIn: ExpirationOption = .never
    @State private var notes = ""
    @State private var isCreating = false
    @State private var showingSymbolSearch = false
    @State private var currentPrice: Decimal = 0
    
    enum CreateAlertField: Hashable, Equatable {
        case cancel
        case symbol
        case targetPrice
        case percentChange
        case notes
        case create
        case alertType(AlertCondition)
        case expiration(ExpirationOption)
    }
    
    enum ExpirationOption: String, CaseIterable {
        case never = "Never"
        case oneDay = "1 Day"
        case oneWeek = "1 Week"
        case oneMonth = "1 Month"
        case threeMonths = "3 Months"
        
        var timeInterval: TimeInterval? {
            switch self {
            case .never: return nil
            case .oneDay: return 86400
            case .oneWeek: return 86400 * 7
            case .oneMonth: return 86400 * 30
            case .threeMonths: return 86400 * 90
            }
        }
    }
    
    init(symbol: String? = nil) {
        self.symbol = symbol
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 30) {
                // Header
                createAlertHeader
                
                // Form Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Symbol Selection
                        symbolSelectionSection
                        
                        // Alert Type Selection
                        alertTypeSection
                        
                        // Alert Configuration
                        alertConfigurationSection
                        
                        // Expiration Settings
                        expirationSection
                        
                        // Notes Section
                        notesSection
                        
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
            if let symbol = symbol {
                selectedSymbol = symbol
                loadCurrentPrice()
            }
            
            // Auto-focus symbol field or price field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = selectedSymbol.isEmpty ? .symbol : .targetPrice
            }
        }
        .sheet(isPresented: $showingSymbolSearch) {
            SymbolSearchView { symbol in
                selectedSymbol = symbol
                showingSymbolSearch = false
                loadCurrentPrice()
            }
        }
    }
    
    // MARK: - Header
    
    private var createAlertHeader: some View {
        HStack {
            FocusableButton("Cancel", systemImage: "xmark") {
                dismiss()
            }
            .focused($focusedField, equals: .cancel)
            
            Spacer()
            
            Text("Create Price Alert")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear.frame(width: 120)
        }
        .padding(.horizontal, 60)
        .padding(.top, 40)
    }
    
    // MARK: - Symbol Selection
    
    private var symbolSelectionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Symbol")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Symbol Input
                HStack {
                    TextField("Enter symbol", text: $selectedSymbol)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.title3)
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .symbol)
                        .onChange(of: selectedSymbol) { _ in
                            loadCurrentPrice()
                        }
                    
                    Button(action: { showingSymbolSearch = true }) {
                        Image(systemName: "magnifyingglass")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(focusedField == .symbol ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Current Price Display
                if currentPrice > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Current Price")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(currentPrice.formatted(.currency(code: "USD")))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Alert Type
    
    private var alertTypeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Alert Type")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach([AlertCondition.above, .below, .crossesAbove, .crossesBelow], id: \.self) { type in
                    AlertTypeButton(
                        type: type,
                        isSelected: alertType == type,
                        isFocused: focusedField == .alertType(type)
                    ) {
                        alertType = type
                    }
                    .focused($focusedField, equals: .alertType(type))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Alert Configuration
    
    private var alertConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Alert Configuration")
                .font(.headline)
                .foregroundColor(.white)
            
            switch alertType {
            case .above, .below:
                priceTargetConfiguration
            case .crossesAbove, .crossesBelow:
                crossingConfiguration
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var priceTargetConfiguration: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Target Price")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Text("$")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                TextField("0.00", text: $targetPrice)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.title3)
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .targetPrice)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .stroke(focusedField == .targetPrice ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            if currentPrice > 0 && !targetPrice.isEmpty,
               let target = Decimal(string: targetPrice) {
                let difference = target - currentPrice
                let percentDiff = (difference / currentPrice) * 100
                
                HStack {
                    Image(systemName: difference > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(difference > 0 ? .green : .red)
                    
                    Text("\(abs(percentDiff).formatted(.number.precision(.fractionLength(2))))% \(difference > 0 ? "above" : "below") current")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var crossingConfiguration: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Crossing Price Alert")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Text("$")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                TextField("0.00", text: $targetPrice)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.title3)
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .targetPrice)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .stroke(focusedField == .targetPrice ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            Text("Alert when price crosses the target and sustains for a period")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Expiration
    
    private var expirationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Expiration")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(ExpirationOption.allCases, id: \.self) { option in
                    ExpirationButton(
                        option: option,
                        isSelected: expiresIn == option,
                        isFocused: focusedField == .expiration(option)
                    ) {
                        expiresIn = option
                    }
                    .focused($focusedField, equals: .expiration(option))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Notes
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes (Optional)")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("Add any notes about this alert...", text: $notes)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .foregroundColor(.white)
                .focused($focusedField, equals: .notes)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(focusedField == .notes ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            FocusableButton(
                isCreating ? "Creating..." : "Create Alert",
                systemImage: "bell.badge.fill"
            ) {
                Task {
                    await createAlert()
                }
            }
            .focused($focusedField, equals: .create)
            .disabled(!canCreateAlert || isCreating)
            
            if !canCreateAlert {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Validation
    
    private var canCreateAlert: Bool {
        guard !selectedSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        
        switch alertType {
        case .above, .below:
            return Decimal(string: targetPrice) != nil
        case .crossesAbove, .crossesBelow:
            return Decimal(string: targetPrice) != nil
        }
    }
    
    private var validationMessage: String {
        if selectedSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter a symbol"
        }
        
        switch alertType {
        case .above, .below, .crossesAbove, .crossesBelow:
            if targetPrice.isEmpty {
                return "Please enter a target price"
            } else if Decimal(string: targetPrice) == nil {
                return "Please enter a valid price"
            }
        }
        
        return ""
    }
    
    // MARK: - Actions
    
    private func loadCurrentPrice() {
        // In a real app, this would fetch the current price
        // For now, simulate with a random price
        if !selectedSymbol.isEmpty {
            currentPrice = Decimal(Double.random(in: 50...500))
        } else {
            currentPrice = 0
        }
    }
    
    private func createAlert() async {
        isCreating = true
        
        let alert = PriceAlert(
            id: UUID().uuidString,
            userId: "current-user", // TODO: Get from auth service
            symbol: selectedSymbol.uppercased(),
            price: Double(targetPrice) ?? 0.0,
            condition: alertType,
            message: notes.isEmpty ? nil : notes,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            triggeredAt: nil
        )
        
        await alertsViewModel.createAlert(alert)
        
        isCreating = false
        dismiss()
    }
}

// MARK: - Supporting Views

struct AlertTypeButton: View {
    let type: AlertCondition
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text(type.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
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
    
    private var icon: String {
        switch type {
        case .above: return "arrow.up.circle.fill"
        case .below: return "arrow.down.circle.fill"
        case .crossesAbove: return "arrow.up.right.circle.fill"
        case .crossesBelow: return "arrow.down.right.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .above: return .green
        case .below: return .red
        case .crossesAbove: return .blue
        case .crossesBelow: return .orange
        }
    }
    
    private var description: String {
        switch type {
        case .above: return "Alert when price goes above target"
        case .below: return "Alert when price drops below target"
        case .crossesAbove: return "Alert when price crosses above and stays"
        case .crossesBelow: return "Alert when price crosses below and stays"
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return Color.white.opacity(0.1)
        } else if isSelected {
            return iconColor.opacity(0.2)
        } else {
            return Color.white.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return iconColor
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

struct ExpirationButton: View {
    let option: CreatePriceAlertView.ExpirationOption
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(option.rawValue)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
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
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return .purple.opacity(0.3)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return .purple
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

// MARK: - Symbol Search View (Placeholder)

struct SymbolSearchView: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Symbol Search")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // This would be a full search implementation
                Text("Search functionality would go here")
                    .foregroundColor(.gray)
                
                Button("Cancel") {
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
    CreatePriceAlertView(symbol: "AAPL")
        .environmentObject(PriceAlertsViewModel())
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}