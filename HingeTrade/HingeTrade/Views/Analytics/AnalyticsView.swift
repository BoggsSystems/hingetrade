//
//  AnalyticsView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct AnalyticsView: View {
    @StateObject private var analyticsViewModel = AnalyticsViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: AnalyticsSection?
    
    @State private var selectedTab: AnalyticsTab = .overview
    @State private var selectedPeriod: PerformancePeriod = .month1
    @State private var showingSettings = false
    @State private var chartTheme = ChartTheme.dark
    
    enum AnalyticsSection: Hashable {
        case back
        case tab(AnalyticsTab)
        case period(PerformancePeriod)
        case metric(String)
        case chart
        case settings
        case recommendation(String)
    }
    
    enum AnalyticsTab: String, CaseIterable {
        case overview = "Overview"
        case performance = "Performance"
        case allocation = "Allocation" 
        case attribution = "Attribution"
        case reports = "Reports"
        
        var systemImage: String {
            switch self {
            case .overview: return "chart.line.uptrend.xyaxis"
            case .performance: return "chart.bar.xaxis"
            case .allocation: return "chart.pie.fill"
            case .attribution: return "square.stack.3d.up"
            case .reports: return "doc.text.fill"
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                analyticsHeader
                
                // Period Selector
                periodSelector
                
                // Tabs
                tabsView
                
                // Content
                if analyticsViewModel.isLoading {
                    LoadingStateView(message: "Loading analytics...")
                        .frame(maxHeight: .infinity)
                } else {
                    contentView
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await analyticsViewModel.loadAnalyticsData()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(isPresented: $showingSettings) {
            AnalyticsSettingsView()
                .environmentObject(analyticsViewModel)
        }
    }
    
    // MARK: - Header
    
    private var analyticsHeader: some View {
        VStack(spacing: 20) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                Text("Portfolio Analytics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                FocusableButton("Settings", systemImage: "gear") {
                    showingSettings = true
                }
                .focused($focusedSection, equals: .settings)
            }
            
            // Performance Summary
            if let performance = analyticsViewModel.currentPerformance {
                PerformanceSummaryCard(performance: performance)
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
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 12) {
            Text("Period:")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PerformancePeriod.allCases, id: \.self) { period in
                        PeriodButton(
                            period: period,
                            isSelected: selectedPeriod == period,
                            isFocused: focusedSection == .period(period)
                        ) {
                            selectedPeriod = period
                            analyticsViewModel.selectPeriod(period)
                        }
                        .focused($focusedSection, equals: .period(period))
                    }
                }
                .padding(.horizontal, 4)
            }
            
            Spacer()
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Tabs
    
    private var tabsView: some View {
        HStack(spacing: 16) {
            ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                AnalyticsTabButton(
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
    
    // MARK: - Content
    
    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 30) {
                switch selectedTab {
                case .overview:
                    overviewContent
                case .performance:
                    performanceContent
                case .allocation:
                    allocationContent
                case .attribution:
                    attributionContent
                case .reports:
                    reportsContent
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    // MARK: - Overview Content
    
    private var overviewContent: some View {
        VStack(spacing: 30) {
            // Key Metrics
            keyMetricsSection
            
            // Performance Chart
            performanceChartSection
            
            // Top Holdings
            topHoldingsSection
            
            // Recent Activity
            recentActivitySection
        }
    }
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Key Performance Metrics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                if let performance = analyticsViewModel.currentPerformance {
                    AnalyticsMetricCard(
                        title: "Total Return",
                        value: performance.returnMetrics.totalReturn.formatted(.percent.precision(.fractionLength(1))),
                        change: performance.returnMetrics.dayReturn.formatted(.percent.precision(.fractionLength(2))),
                        isPositive: performance.returnMetrics.totalReturn >= 0,
                        isFocused: focusedSection == .metric("totalReturn")
                    )
                    .focused($focusedSection, equals: .metric("totalReturn"))
                    
                    AnalyticsMetricCard(
                        title: "Annualized",
                        value: performance.returnMetrics.annualizedReturn.formatted(.percent.precision(.fractionLength(1))),
                        change: nil,
                        isPositive: performance.returnMetrics.annualizedReturn >= 0,
                        isFocused: focusedSection == .metric("annualized")
                    )
                    .focused($focusedSection, equals: .metric("annualized"))
                    
                    AnalyticsMetricCard(
                        title: "Sharpe Ratio",
                        value: performance.returnMetrics.sharpeRatio.formatted(.number.precision(.fractionLength(2))),
                        change: nil,
                        isPositive: performance.returnMetrics.sharpeRatio > 1.0,
                        isFocused: focusedSection == .metric("sharpe")
                    )
                    .focused($focusedSection, equals: .metric("sharpe"))
                    
                    AnalyticsMetricCard(
                        title: "Max Drawdown",
                        value: performance.riskMetrics.maximumDrawdown.formatted(.percent.precision(.fractionLength(1))),
                        change: nil,
                        isPositive: performance.riskMetrics.maximumDrawdown > -0.10,
                        isFocused: focusedSection == .metric("drawdown")
                    )
                    .focused($focusedSection, equals: .metric("drawdown"))
                }
            }
        }
    }
    
    private var performanceChartSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Portfolio Performance")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Toggle("Benchmark", isOn: $analyticsViewModel.showBenchmark)
                        #if os(tvOS)
                        .toggleStyle(DefaultToggleStyle())
                        #else
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        #endif
                    
                    Toggle("Drawdown", isOn: $analyticsViewModel.showDrawdown)
                        #if os(tvOS)
                        .toggleStyle(DefaultToggleStyle())
                        #else
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        #endif
                }
            }
            
            if let performanceChart = analyticsViewModel.performanceChart {
                ChartContainer(
                    chartData: performanceChart.chartData,
                    theme: chartTheme,
                    interaction: .default,
                    onPointSelected: { point in
                        // Handle point selection
                    }
                )
                .focused($focusedSection, equals: .chart)
            } else {
                PlaceholderChartView(chartType: .area, theme: chartTheme)
            }
        }
    }
    
    private var topHoldingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Top Holdings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(analyticsViewModel.topPerformers.prefix(5), id: \.id) { position in
                    HoldingRow(position: position)
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
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    ActivityRow()
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
    
    // MARK: - Performance Content
    
    private var performanceContent: some View {
        VStack(spacing: 30) {
            PerformanceAnalysisView()
                .environmentObject(analyticsViewModel)
        }
    }
    
    // MARK: - Allocation Content
    
    private var allocationContent: some View {
        VStack(spacing: 30) {
            // Asset Allocation Chart
            if let allocationChart = analyticsViewModel.allocationChart {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Asset Allocation")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    ChartContainer(
                        chartData: allocationChart.chartData,
                        theme: chartTheme,
                        interaction: .default,
                        onPointSelected: nil
                    )
                }
            }
            
            // Sector Allocation
            if let sectorChart = analyticsViewModel.sectorChart {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Sector Allocation")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    ChartContainer(
                        chartData: sectorChart.chartData,
                        theme: chartTheme,
                        interaction: .default,
                        onPointSelected: nil
                    )
                }
            }
            
            // Allocation Details
            AllocationDetailsView()
                .environmentObject(analyticsViewModel)
        }
    }
    
    // MARK: - Attribution Content
    
    private var attributionContent: some View {
        VStack(spacing: 30) {
            AttributionAnalysisView()
                .environmentObject(analyticsViewModel)
        }
    }
    
    // MARK: - Reports Content
    
    private var reportsContent: some View {
        VStack(spacing: 30) {
            ReportsView()
                .environmentObject(analyticsViewModel)
        }
    }
}

// MARK: - Supporting Views

struct PerformanceSummaryCard: View {
    let performance: PortfolioPerformance
    
    var body: some View {
        HStack(spacing: 40) {
            SummaryItem(
                title: "Total Value",
                value: performance.totalValue.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                color: .white
            )
            
            SummaryItem(
                title: "Total Gain/Loss",
                value: performance.totalGainLoss.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                color: performance.isPositive ? .green : .red
            )
            
            SummaryItem(
                title: "Total %",
                value: performance.totalGainLossPercent.formatted(.percent.precision(.fractionLength(1))),
                color: performance.isPositive ? .green : .red
            )
            
            SummaryItem(
                title: "Day Change",
                value: performance.dayChange.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                color: performance.dayChangeIsPositive ? .green : .red
            )
            
            SummaryItem(
                title: "Day %",
                value: performance.dayChangePercent.formatted(.percent.precision(.fractionLength(2))),
                color: performance.dayChangeIsPositive ? .green : .red
            )
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SummaryItem: View {
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
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct PeriodButton: View {
    let period: PerformancePeriod
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(period.rawValue)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(buttonForegroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var buttonForegroundColor: Color {
        if isFocused {
            return .black
        } else if isSelected {
            return .white
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return .blue
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
            return .gray.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0.5
    }
}

struct AnalyticsTabButton: View {
    let tab: AnalyticsView.AnalyticsTab
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

struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let change: String?
    let isPositive: Bool
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
            
            if let change = change {
                Text(change)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
            }
            
            Spacer()
        }
        .padding(16)
        .frame(minHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.green : (isPositive ? Color.green : Color.red).opacity(0.3), lineWidth: isFocused ? 2 : 1)
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct HoldingRow: View {
    let position: PositionPerformance
    
    var body: some View {
        HStack(spacing: 12) {
            Text(position.symbol)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(position.quantity) shares")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Avg: \(position.averageCost.formatted(.currency(code: "USD")))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(position.marketValue.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("(\(position.weight.formatted(.percent.precision(.fractionLength(1)))))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(position.unrealizedGainLoss.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(position.unrealizedGainLoss >= 0 ? .green : .red)
                
                Text(position.unrealizedGainLossPercent.formatted(.percent.precision(.fractionLength(1))))
                    .font(.caption)
                    .foregroundColor(position.unrealizedGainLoss >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ActivityRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Portfolio Rebalanced")
                    .font(.body)
                    .foregroundColor(.white)
                
                Text("2 hours ago")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Placeholder Views

struct PerformanceAnalysisView: View {
    @EnvironmentObject private var analyticsViewModel: AnalyticsViewModel
    
    var body: some View {
        Text("Performance Analysis View - Detailed performance metrics and analysis")
            .font(.title2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

struct AllocationDetailsView: View {
    @EnvironmentObject private var analyticsViewModel: AnalyticsViewModel
    
    var body: some View {
        Text("Allocation Details View - Breakdown of portfolio allocations")
            .font(.title2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }
}

struct AttributionAnalysisView: View {
    @EnvironmentObject private var analyticsViewModel: AnalyticsViewModel
    
    var body: some View {
        Text("Attribution Analysis View - Performance attribution breakdown")
            .font(.title2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
    }
}

struct ReportsView: View {
    @EnvironmentObject private var analyticsViewModel: AnalyticsViewModel
    
    var body: some View {
        Text("Reports View - Generate and export performance reports")
            .font(.title2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
    }
}

struct AnalyticsSettingsView: View {
    @EnvironmentObject private var analyticsViewModel: AnalyticsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Analytics Settings")
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
    AnalyticsView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}