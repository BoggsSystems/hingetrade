//
//  RiskManagementView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct RiskManagementView: View {
    @StateObject private var riskManagementViewModel = RiskManagementViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: RiskManagementSection?
    
    @State private var selectedTab: RiskTab = .overview
    @State private var showingRiskSettings = false
    
    enum RiskManagementSection: Hashable {
        case back
        case tab(RiskTab)
        case riskMetric(String)
        case position(String)
        case settings
        case action(String)
    }
    
    enum RiskTab: String, CaseIterable {
        case overview = "Overview"
        case positions = "Positions"
        case limits = "Risk Limits"
        case analytics = "Analytics"
        
        var systemImage: String {
            switch self {
            case .overview: return "gauge.medium"
            case .positions: return "square.stack.3d.up"
            case .limits: return "shield.fill"
            case .analytics: return "chart.bar.xaxis"
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                riskManagementHeader
                
                // Tabs
                tabsView
                
                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        switch selectedTab {
                        case .overview:
                            riskOverviewContent
                        case .positions:
                            positionsRiskContent
                        case .limits:
                            riskLimitsContent
                        case .analytics:
                            riskAnalyticsContent
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 30)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await riskManagementViewModel.loadRiskData()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(isPresented: $showingRiskSettings) {
            RiskSettingsView()
                .environmentObject(riskManagementViewModel)
        }
    }
    
    // MARK: - Header
    
    private var riskManagementHeader: some View {
        VStack(spacing: 20) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                Text("Risk Management")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                FocusableButton("Settings", systemImage: "gear") {
                    showingRiskSettings = true
                }
                .focused($focusedSection, equals: .settings)
            }
            
            // Overall Risk Status
            if let riskStatus = riskManagementViewModel.overallRiskStatus {
                OverallRiskStatusCard(riskStatus: riskStatus)
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
    
    // MARK: - Tabs
    
    private var tabsView: some View {
        HStack(spacing: 16) {
            ForEach(RiskTab.allCases, id: \.self) { tab in
                RiskTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isFocused: focusedSection == .tab(tab)
                ) {
                    selectedTab = tab
                }
                .focused($focusedSection, equals: .tab(tab))
            }
            
            Spacer()
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Content Sections
    
    private var riskOverviewContent: some View {
        VStack(spacing: 30) {
            // Key Risk Metrics
            keyRiskMetricsSection
            
            // Portfolio Heat Map
            portfolioHeatMapSection
            
            // Risk Alerts
            riskAlertsSection
            
            // Action Items
            actionItemsSection
        }
    }
    
    private var keyRiskMetricsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Key Risk Metrics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                RiskMetricCard(
                    title: "Portfolio Beta",
                    value: riskManagementViewModel.portfolioBeta?.formatted(.number.precision(.fractionLength(2))) ?? "--",
                    subtitle: "vs Market",
                    color: betaRiskColor,
                    isFocused: focusedSection == .riskMetric("beta")
                )
                .focused($focusedSection, equals: .riskMetric("beta"))
                
                RiskMetricCard(
                    title: "Value at Risk",
                    value: riskManagementViewModel.valueAtRisk?.formatted(.currency(code: "USD").precision(.fractionLength(0))) ?? "--",
                    subtitle: "1-day 95% VaR",
                    color: varRiskColor,
                    isFocused: focusedSection == .riskMetric("var")
                )
                .focused($focusedSection, equals: .riskMetric("var"))
                
                RiskMetricCard(
                    title: "Max Drawdown",
                    value: riskManagementViewModel.maxDrawdown?.formatted(.percent.precision(.fractionLength(1))) ?? "--",
                    subtitle: "Historical",
                    color: drawdownRiskColor,
                    isFocused: focusedSection == .riskMetric("drawdown")
                )
                .focused($focusedSection, equals: .riskMetric("drawdown"))
                
                RiskMetricCard(
                    title: "Sharpe Ratio",
                    value: riskManagementViewModel.sharpeRatio?.formatted(.number.precision(.fractionLength(2))) ?? "--",
                    subtitle: "Risk-adjusted return",
                    color: sharpeRiskColor,
                    isFocused: focusedSection == .riskMetric("sharpe")
                )
                .focused($focusedSection, equals: .riskMetric("sharpe"))
                
                RiskMetricCard(
                    title: "Volatility",
                    value: riskManagementViewModel.portfolioVolatility?.formatted(.percent.precision(.fractionLength(1))) ?? "--",
                    subtitle: "30-day annualized",
                    color: volatilityRiskColor,
                    isFocused: focusedSection == .riskMetric("volatility")
                )
                .focused($focusedSection, equals: .riskMetric("volatility"))
                
                RiskMetricCard(
                    title: "Concentration",
                    value: riskManagementViewModel.concentrationRisk?.formatted(.percent.precision(.fractionLength(1))) ?? "--",
                    subtitle: "Top 5 positions",
                    color: concentrationRiskColor,
                    isFocused: focusedSection == .riskMetric("concentration")
                )
                .focused($focusedSection, equals: .riskMetric("concentration"))
            }
        }
    }
    
    private var portfolioHeatMapSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Portfolio Risk Heat Map")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(riskManagementViewModel.positionRisks, id: \.symbol) { position in
                    PositionRiskCell(
                        symbol: position.symbol,
                        riskLevel: position.riskLevel,
                        value: position.portfolioWeight,
                        isFocused: focusedSection == .position(position.symbol)
                    )
                    .focused($focusedSection, equals: .position(position.symbol))
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
    
    private var riskAlertsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Risk Alerts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(riskManagementViewModel.activeAlerts.count) active")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if riskManagementViewModel.activeAlerts.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        
                        Text("All risk metrics within acceptable limits")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(riskManagementViewModel.activeAlerts, id: \.id) { alert in
                        RiskAlertRow(alert: alert)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recommended Actions")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(Array(riskManagementViewModel.recommendedActions.enumerated()), id: \.offset) { index, action in
                    RecommendedActionRow(
                        action: action,
                        isFocused: focusedSection == .action("action-\(index)")
                    )
                    .focused($focusedSection, equals: .action("action-\(index)"))
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
    
    // MARK: - Positions Risk Content
    
    private var positionsRiskContent: some View {
        VStack(spacing: 30) {
            PositionRiskAnalysisView()
                .environmentObject(riskManagementViewModel)
        }
    }
    
    // MARK: - Risk Limits Content
    
    private var riskLimitsContent: some View {
        VStack(spacing: 30) {
            RiskLimitsConfigurationView()
                .environmentObject(riskManagementViewModel)
        }
    }
    
    // MARK: - Risk Analytics Content
    
    private var riskAnalyticsContent: some View {
        VStack(spacing: 30) {
            RiskAnalyticsDashboardView()
                .environmentObject(riskManagementViewModel)
        }
    }
    
    // MARK: - Computed Properties
    
    private var betaRiskColor: Color {
        guard let beta = riskManagementViewModel.portfolioBeta else { return .gray }
        return abs(beta - 1.0) > 0.3 ? .orange : .green
    }
    
    private var varRiskColor: Color {
        guard let var95 = riskManagementViewModel.valueAtRisk else { return .gray }
        return var95 > 5000 ? .red : var95 > 2000 ? .orange : .green
    }
    
    private var drawdownRiskColor: Color {
        guard let drawdown = riskManagementViewModel.maxDrawdown else { return .gray }
        return drawdown > 0.20 ? .red : drawdown > 0.10 ? .orange : .green
    }
    
    private var sharpeRiskColor: Color {
        guard let sharpe = riskManagementViewModel.sharpeRatio else { return .gray }
        return sharpe > 1.5 ? .green : sharpe > 0.5 ? .orange : .red
    }
    
    private var volatilityRiskColor: Color {
        guard let volatility = riskManagementViewModel.portfolioVolatility else { return .gray }
        return volatility > 0.30 ? .red : volatility > 0.20 ? .orange : .green
    }
    
    private var concentrationRiskColor: Color {
        guard let concentration = riskManagementViewModel.concentrationRisk else { return .gray }
        return concentration > 0.50 ? .red : concentration > 0.30 ? .orange : .green
    }
}

// MARK: - Supporting Views

struct OverallRiskStatusCard: View {
    let riskStatus: OverallRiskStatus
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: riskStatus.level.color))
                        .frame(width: 16, height: 16)
                    
                    Text("Portfolio Risk Level")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Text(riskStatus.level.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text("Risk Score")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(riskStatus.score.formatted(.number.precision(.fractionLength(1))))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: riskStatus.level.color))
            }
            
            VStack(alignment: .trailing, spacing: 8) {
                Text("Utilization")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(riskStatus.utilizationPercent.formatted(.percent.precision(.fractionLength(1))))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color(hex: riskStatus.level.color).opacity(0.3), lineWidth: 1)
        )
    }
}

struct RiskTabButton: View {
    let tab: RiskManagementView.RiskTab
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.systemImage)
                    .font(.body)
                
                Text(tab.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(buttonForegroundColor)
            .padding(.horizontal, 16)
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
            return .blue.opacity(0.2)
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

struct RiskMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            HStack {
                Spacer()
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
        }
        .padding(16)
        .frame(minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.green : color.opacity(0.3), lineWidth: isFocused ? 2 : 1)
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct PositionRiskCell: View {
    let symbol: String
    let riskLevel: RiskLevel
    let value: Double
    let isFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(symbol)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(value.formatted(.percent.precision(.fractionLength(1))))
                .font(.caption)
                .foregroundColor(.gray)
            
            Rectangle()
                .fill(Color(hex: riskLevel.color))
                .frame(height: 4)
                .cornerRadius(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: riskLevel.color).opacity(isFocused ? 0.3 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 2 : 0)
        )
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Placeholder Views

struct PositionRiskAnalysisView: View {
    @EnvironmentObject private var riskManagementViewModel: RiskManagementViewModel
    
    var body: some View {
        Text("Position Risk Analysis View")
            .font(.title2)
            .foregroundColor(.white)
    }
}

struct RiskLimitsConfigurationView: View {
    @EnvironmentObject private var riskManagementViewModel: RiskManagementViewModel
    
    var body: some View {
        Text("Risk Limits Configuration View")
            .font(.title2)
            .foregroundColor(.white)
    }
}

struct RiskAnalyticsDashboardView: View {
    @EnvironmentObject private var riskManagementViewModel: RiskManagementViewModel
    
    var body: some View {
        Text("Risk Analytics Dashboard View")
            .font(.title2)
            .foregroundColor(.white)
    }
}

struct RiskSettingsView: View {
    @EnvironmentObject private var riskManagementViewModel: RiskManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Risk Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
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
    RiskManagementView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}