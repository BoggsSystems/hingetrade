//
//  OptionsTrading View.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct OptionsTradingView: View {
    let symbol: String
    
    @StateObject private var optionsViewModel = OptionsViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: OptionsSection?
    
    @State private var selectedTab: OptionsTab = .chain
    @State private var selectedExpiration: Date = Date()
    @State private var selectedStrategy: OptionsStrategy = .buyCall
    @State private var showingStrategyBuilder = false
    
    enum OptionsSection: Hashable {
        case back
        case tab(OptionsTab)
        case expiration(Date)
        case strategy(OptionsStrategy)
        case contract(String)
        case buildStrategy
    }
    
    enum OptionsTab: String, CaseIterable {
        case chain = "Options Chain"
        case strategies = "Strategies"
        case positions = "Positions"
        case analytics = "Analytics"
        
        var systemImage: String {
            switch self {
            case .chain: return "list.bullet.rectangle"
            case .strategies: return "square.stack.3d.up"
            case .positions: return "briefcase.fill"
            case .analytics: return "chart.bar.xaxis"
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                optionsHeader
                
                // Tabs
                tabsView
                
                // Content
                if optionsViewModel.isLoading {
                    LoadingStateView(message: "Loading options data...")
                        .frame(maxHeight: .infinity)
                } else {
                    contentView
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await optionsViewModel.loadOptionsChain(for: symbol)
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(isPresented: $showingStrategyBuilder) {
            OptionsStrategyBuilderView(symbol: symbol, strategy: selectedStrategy)
                .environmentObject(optionsViewModel)
        }
    }
    
    // MARK: - Header
    
    private var optionsHeader: some View {
        VStack(spacing: 20) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Options Trading")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(symbol)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                FocusableButton("Build Strategy", systemImage: "plus.square.on.square") {
                    showingStrategyBuilder = true
                }
                .focused($focusedSection, equals: .buildStrategy)
            }
            
            // Market Data Summary
            if let optionsChain = optionsViewModel.optionsChain {
                OptionsMarketSummary(optionsChain: optionsChain)
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
            ForEach(OptionsTab.allCases, id: \.self) { tab in
                OptionsTabButton(
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
                case .chain:
                    optionsChainContent
                case .strategies:
                    strategiesContent
                case .positions:
                    positionsContent
                case .analytics:
                    analyticsContent
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    // MARK: - Options Chain Content
    
    private var optionsChainContent: some View {
        VStack(spacing: 30) {
            // Expiration Selector
            expirationSelectorSection
            
            // Options Chain Table
            optionsChainTableSection
        }
    }
    
    private var expirationSelectorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Expiration Dates")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(optionsViewModel.availableExpirations, id: \.self) { expiration in
                        ExpirationButton(
                            date: expiration,
                            isSelected: Calendar.current.isDate(selectedExpiration, inSameDayAs: expiration),
                            isFocused: focusedSection == .expiration(expiration)
                        ) {
                            selectedExpiration = expiration
                            optionsViewModel.setSelectedExpiration(expiration)
                        }
                        .focused($focusedSection, equals: .expiration(expiration))
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var optionsChainTableSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Options Chain")
                .font(.headline)
                .foregroundColor(.white)
            
            if let optionsChain = optionsViewModel.optionsChain {
                OptionsChainTable(
                    optionsChain: optionsChain,
                    selectedExpiration: selectedExpiration,
                    focusedContract: focusedSection
                ) { contract in
                    // Handle contract selection
                    optionsViewModel.selectContract(contract)
                }
            } else {
                Text("No options data available")
                    .font(.body)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    // MARK: - Strategies Content
    
    private var strategiesContent: some View {
        VStack(spacing: 30) {
            // Popular Strategies
            popularStrategiesSection
            
            // Strategy Templates
            strategyTemplatesSection
        }
    }
    
    private var popularStrategiesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Popular Strategies")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(OptionsStrategy.allCases.prefix(6), id: \.self) { strategy in
                    StrategyCard(
                        strategy: strategy,
                        isSelected: selectedStrategy == strategy,
                        isFocused: focusedSection == .strategy(strategy)
                    ) {
                        selectedStrategy = strategy
                        showingStrategyBuilder = true
                    }
                    .focused($focusedSection, equals: .strategy(strategy))
                }
            }
        }
    }
    
    private var strategyTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Strategy Templates")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(optionsViewModel.strategyTemplates, id: \.id) { template in
                    StrategyTemplateRow(template: template)
                }
            }
        }
    }
    
    // MARK: - Positions Content
    
    private var positionsContent: some View {
        VStack(spacing: 30) {
            OptionsPositionsView()
                .environmentObject(optionsViewModel)
        }
    }
    
    // MARK: - Analytics Content
    
    private var analyticsContent: some View {
        VStack(spacing: 30) {
            OptionsAnalyticsView()
                .environmentObject(optionsViewModel)
        }
    }
}

// MARK: - Supporting Views

struct OptionsMarketSummary: View {
    let optionsChain: OptionsChain
    
    var body: some View {
        HStack(spacing: 40) {
            MarketSummaryItem(
                title: "Underlying Price",
                value: optionsChain.underlyingPrice.formatted(.currency(code: "USD")),
                color: .white
            )
            
            MarketSummaryItem(
                title: "IV Rank",
                value: optionsChain.impliedVolatilityRank.formatted(.percent.precision(.fractionLength(0))),
                color: ivRankColor
            )
            
            MarketSummaryItem(
                title: "IV Percentile",
                value: optionsChain.impliedVolatilityPercentile.formatted(.percent.precision(.fractionLength(0))),
                color: ivPercentileColor
            )
            
            MarketSummaryItem(
                title: "Expirations",
                value: "\(optionsChain.expirations.count)",
                color: .blue
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
    
    private var ivRankColor: Color {
        let rank = optionsChain.impliedVolatilityRank
        return rank > 0.75 ? .red : rank > 0.50 ? .orange : rank > 0.25 ? .yellow : .green
    }
    
    private var ivPercentileColor: Color {
        let percentile = optionsChain.impliedVolatilityPercentile
        return percentile > 0.80 ? .red : percentile > 0.60 ? .orange : percentile > 0.40 ? .yellow : .green
    }
}

struct MarketSummaryItem: View {
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

struct OptionsTabButton: View {
    let tab: OptionsTradingView.OptionsTab
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

struct ExpirationButton: View {
    let date: Date
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.body)
                    .fontWeight(isSelected ? .bold : .regular)
                
                Text(daysToExpiration)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .foregroundColor(textColor)
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
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var daysToExpiration: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return "\(days)d"
    }
    
    private var textColor: Color {
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
        isFocused || isSelected ? 1 : 0.5
    }
}

struct StrategyCard: View {
    let strategy: OptionsStrategy
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: strategy.systemImage)
                    .font(.title2)
                    .foregroundColor(Color(hex: strategy.complexity.color))
                
                Text(strategy.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(strategy.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: strategy.complexity.color))
                        .frame(width: 8, height: 8)
                    
                    Text(strategy.complexity.displayName)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 140)
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
    
    private var backgroundColor: Color {
        if isFocused {
            return Color.white.opacity(0.1)
        } else if isSelected {
            return Color(hex: strategy.complexity.color).opacity(0.2)
        } else {
            return Color.white.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return Color(hex: strategy.complexity.color)
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

// MARK: - Placeholder Views

struct OptionsChainTable: View {
    let optionsChain: OptionsChain
    let selectedExpiration: Date
    let focusedContract: OptionsTradingView.OptionsSection?
    let onContractSelected: (OptionsContract) -> Void
    
    var body: some View {
        Text("Options Chain Table - Implementation would show call/put options in a table format")
            .font(.body)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 60)
    }
}

struct StrategyTemplateRow: View {
    let template: StrategyTemplate
    
    var body: some View {
        Text("Strategy Template: \(template.name)")
            .font(.body)
            .foregroundColor(.white)
    }
}

struct OptionsPositionsView: View {
    @EnvironmentObject private var optionsViewModel: OptionsViewModel
    
    var body: some View {
        Text("Options Positions View")
            .font(.title2)
            .foregroundColor(.white)
    }
}

struct OptionsAnalyticsView: View {
    @EnvironmentObject private var optionsViewModel: OptionsViewModel
    
    var body: some View {
        Text("Options Analytics View")
            .font(.title2)
            .foregroundColor(.white)
    }
}

struct OptionsStrategyBuilderView: View {
    let symbol: String
    let strategy: OptionsStrategy
    
    @EnvironmentObject private var optionsViewModel: OptionsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Strategy Builder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Building \(strategy.displayName) for \(symbol)")
                    .font(.body)
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

// MARK: - Supporting Models

struct StrategyTemplate: Identifiable {
    let id: String
    let name: String
    let strategy: OptionsStrategy
    let description: String
    let legs: [OptionsOrderLeg]
}

#Preview {
    OptionsTradingView(symbol: "AAPL")
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}