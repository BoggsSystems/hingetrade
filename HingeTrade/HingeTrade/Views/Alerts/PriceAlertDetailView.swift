//
//  PriceAlertDetailView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct PriceAlertDetailView: View {
    let alert: PriceAlert
    
    @EnvironmentObject private var alertsViewModel: PriceAlertsViewModel
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: AlertDetailSection?
    
    @State private var showingEditAlert = false
    @State private var isUpdating = false
    @State private var currentPrice: Decimal = 0
    @State private var priceHistory: [PricePoint] = []
    
    enum AlertDetailSection: Hashable {
        case back
        case toggle
        case edit
        case delete
        case viewChart
    }
    
    struct PricePoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let price: Decimal
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                alertDetailHeader
                
                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Alert Status Card
                        alertStatusCard
                        
                        // Price Information
                        priceInformationSection
                        
                        // Alert Configuration
                        alertConfigurationSection
                        
                        // Performance Section
                        performanceSection
                        
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
            loadPriceData()
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(isPresented: $showingEditAlert) {
            EditPriceAlertView(alert: alert)
                .environmentObject(alertsViewModel)
        }
    }
    
    // MARK: - Header
    
    private var alertDetailHeader: some View {
        HStack {
            FocusableButton("Back", systemImage: "chevron.left") {
                dismiss()
            }
            .focused($focusedSection, equals: .back)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Price Alert")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text(alert.symbol)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(statusColor.opacity(0.2))
            )
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
    
    // MARK: - Alert Status Card
    
    private var alertStatusCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alert Type")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(alert.alertType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Created")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(alert.createdAt.formatted(.relative(presentation: .named)))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
            
            if let triggeredAt = alert.triggeredAt {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alert Triggered")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text(triggeredAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            
            if let expiresAt = alert.expiresAt {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                HStack {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expires")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        Text(expiresAt.formatted(.dateTime.month().day().hour().minute()))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if Date() > expiresAt {
                        Text("EXPIRED")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red.opacity(0.2))
                            )
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Price Information
    
    private var priceInformationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Price Information")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                // Current Price
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Price")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(currentPrice.formatted(.currency(code: "USD")))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Price change (simulated)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                        Text("+1.2%")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                }
                
                Spacer()
                
                // Target Price
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Target Price")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(alert.targetPrice.formatted(.currency(code: "USD")))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    // Distance to target
                    if currentPrice > 0 {
                        let difference = alert.targetPrice - currentPrice
                        let percentDiff = (difference / currentPrice) * 100
                        
                        HStack(spacing: 4) {
                            Image(systemName: difference > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                            Text("\(abs(percentDiff).formatted(.number.precision(.fractionLength(1))))% away")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(difference > 0 ? .red : .green)
                    }
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
    
    // MARK: - Configuration
    
    private var alertConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configuration")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                configurationRow(
                    title: "Alert Type",
                    value: alert.alertType.displayName,
                    icon: alertTypeIcon
                )
                
                switch alert.alertType {
                case .priceAbove, .priceBelow:
                    configurationRow(
                        title: "Target Price",
                        value: alert.targetPrice.formatted(.currency(code: "USD")),
                        icon: "target"
                    )
                case .percentChange:
                    if let percentChange = alert.percentChange {
                        configurationRow(
                            title: "Percent Change",
                            value: "\(percentChange.formatted(.number.precision(.fractionLength(1))))%",
                            icon: "percent"
                        )
                    }
                case .volumeSpike:
                    configurationRow(
                        title: "Volume Threshold",
                        value: "2x Average",
                        icon: "chart.bar.fill"
                    )
                }
                
                configurationRow(
                    title: "Status",
                    value: alert.isActive ? "Active" : "Inactive",
                    icon: alert.isActive ? "bell.fill" : "bell.slash.fill"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func configurationRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.gray)
                .frame(width: 20)
            
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
    
    // MARK: - Performance
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Performance")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                FocusableButton("View Chart", systemImage: "chart.line.uptrend.xyaxis") {
                    // Navigate to detailed chart view
                }
                .focused($focusedSection, equals: .viewChart)
            }
            
            // Mini chart placeholder
            VStack(spacing: 12) {
                HStack {
                    Text("24H Price Movement")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Last updated: just now")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Simulated mini chart
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
                    .frame(height: 80)
                    .overlay(
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            Text("Chart view would show here")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Toggle Button
                FocusableButton(
                    alert.isActive ? "Pause Alert" : "Activate Alert",
                    systemImage: alert.isActive ? "pause.circle" : "play.circle"
                ) {
                    Task {
                        await toggleAlert()
                    }
                }
                .focused($focusedSection, equals: .toggle)
                .disabled(isUpdating)
                
                // Edit Button
                FocusableButton("Edit Alert", systemImage: "pencil") {
                    showingEditAlert = true
                }
                .focused($focusedSection, equals: .edit)
                .disabled(isUpdating)
            }
            
            // Delete Button
            FocusableButton("Delete Alert", systemImage: "trash") {
                Task {
                    await deleteAlert()
                }
            }
            .focused($focusedSection, equals: .delete)
            .disabled(isUpdating)
            .foregroundColor(.red)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        if !alert.isActive {
            return .gray
        } else if alert.triggeredAt != nil {
            return .green
        } else {
            return .orange
        }
    }
    
    private var statusText: String {
        if !alert.isActive {
            return "Inactive"
        } else if alert.triggeredAt != nil {
            return "Triggered"
        } else {
            return "Active"
        }
    }
    
    private var alertTypeIcon: String {
        switch alert.alertType {
        case .priceAbove: return "arrow.up.circle.fill"
        case .priceBelow: return "arrow.down.circle.fill"
        case .percentChange: return "percent"
        case .volumeSpike: return "chart.bar.fill"
        }
    }
    
    // MARK: - Actions
    
    private func loadPriceData() {
        // Simulate loading current price and price history
        currentPrice = Decimal(Double.random(in: 150...200))
        
        // Generate sample price history
        priceHistory = (0..<24).map { hour in
            PricePoint(
                timestamp: Date().addingTimeInterval(-Double(hour) * 3600),
                price: currentPrice + Decimal(Double.random(in: -10...10))
            )
        }.reversed()
    }
    
    private func toggleAlert() async {
        isUpdating = true
        await alertsViewModel.toggleAlert(alert)
        isUpdating = false
    }
    
    private func deleteAlert() async {
        isUpdating = true
        await alertsViewModel.deleteAlert(alert)
        dismiss()
    }
}

// MARK: - Edit Alert View (Placeholder)

struct EditPriceAlertView: View {
    let alert: PriceAlert
    
    @EnvironmentObject private var alertsViewModel: PriceAlertsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Edit Price Alert")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Edit functionality would go here")
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
    let sampleAlert = PriceAlert(
        id: "alert-1",
        symbol: "AAPL",
        alertType: .priceAbove,
        targetPrice: 180.00,
        percentChange: nil,
        createdAt: Date().addingTimeInterval(-86400),
        isActive: true,
        triggeredAt: nil,
        expiresAt: Date().addingTimeInterval(86400 * 7)
    )
    
    return PriceAlertDetailView(alert: sampleAlert)
        .environmentObject(PriceAlertsViewModel())
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}