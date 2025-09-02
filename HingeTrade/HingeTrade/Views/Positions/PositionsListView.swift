//
//  PositionsListView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct PositionsListView: View {
    @StateObject private var positionsViewModel = PositionsViewModel()
    @State private var selectedPosition: Position?
    @State private var sortOption: SortOption = .symbol
    @State private var filterOption: FilterOption = .all
    @FocusState private var focusedPosition: String?
    
    enum SortOption: String, CaseIterable {
        case symbol = "Symbol"
        case unrealizedPL = "P&L"
        case marketValue = "Value"
        case quantity = "Quantity"
        
        var systemImage: String {
            switch self {
            case .symbol: return "textformat.abc"
            case .unrealizedPL: return "chart.line.uptrend.xyaxis"
            case .marketValue: return "dollarsign.circle"
            case .quantity: return "number"
            }
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case profitable = "Profitable"
        case losing = "Losing"
        case longPositions = "Long"
        case shortPositions = "Short"
        
        var systemImage: String {
            switch self {
            case .all: return "line.3.horizontal.decrease"
            case .profitable: return "arrow.up.circle"
            case .losing: return "arrow.down.circle"
            case .longPositions: return "plus.circle"
            case .shortPositions: return "minus.circle"
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header with Controls
                PositionsHeaderView(
                    sortOption: $sortOption,
                    filterOption: $filterOption,
                    totalPositions: positionsViewModel.filteredPositions.count,
                    totalValue: positionsViewModel.totalMarketValue,
                    totalPL: positionsViewModel.totalUnrealizedPL
                )
                
                // Positions Grid
                if positionsViewModel.isLoading {
                    LoadingStateView(message: "Loading positions...")
                } else if positionsViewModel.filteredPositions.isEmpty {
                    EmptyPositionsView(filterOption: filterOption)
                } else {
                    PositionsGridView(
                        positions: positionsViewModel.filteredPositions,
                        selectedPosition: $selectedPosition,
                        focusedPosition: $focusedPosition
                    )
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(item: $selectedPosition) { position in
            PositionDetailView(position: position)
        }
        .onAppear {
            Task {
                await positionsViewModel.loadPositions()
            }
        }
        .onChange(of: sortOption) { _, newValue in
            positionsViewModel.setSortOption(newValue)
        }
        .onChange(of: filterOption) { _, newValue in
            positionsViewModel.setFilterOption(newValue)
        }
        .refreshable {
            await positionsViewModel.refreshPositions()
        }
    }
}

// MARK: - PositionsHeaderView

struct PositionsHeaderView: View {
    @Binding var sortOption: PositionsListView.SortOption
    @Binding var filterOption: PositionsListView.FilterOption
    let totalPositions: Int
    let totalValue: Decimal
    let totalPL: Decimal
    
    @FocusState private var focusedControl: HeaderControl?
    
    enum HeaderControl: Hashable {
        case sort
        case filter
        case refresh
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Summary Stats
            HStack(spacing: 60) {
                StatColumn(
                    title: "Total Positions",
                    value: "\(totalPositions)",
                    subtitle: "Open positions"
                )
                
                StatColumn(
                    title: "Market Value",
                    value: totalValue.formatted(.currency(code: "USD")),
                    subtitle: "Current value"
                )
                
                StatColumn(
                    title: "Unrealized P&L",
                    value: totalPL.formatted(.currency(code: "USD")),
                    subtitle: totalPL >= 0 ? "Profit" : "Loss",
                    valueColor: totalPL >= 0 ? .green : .red
                )
                
                Spacer()
                
                // Controls
                HStack(spacing: 20) {
                    ControlButton(
                        title: "Sort: \(sortOption.rawValue)",
                        systemImage: sortOption.systemImage,
                        isFocused: focusedControl == .sort
                    ) {
                        cycleSortOption()
                    }
                    .focused($focusedControl, equals: .sort)
                    
                    ControlButton(
                        title: "Filter: \(filterOption.rawValue)",
                        systemImage: filterOption.systemImage,
                        isFocused: focusedControl == .filter
                    ) {
                        cycleFilterOption()
                    }
                    .focused($focusedControl, equals: .filter)
                }
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
    
    private func cycleSortOption() {
        let allOptions = PositionsListView.SortOption.allCases
        let currentIndex = allOptions.firstIndex(of: sortOption) ?? 0
        let nextIndex = (currentIndex + 1) % allOptions.count
        sortOption = allOptions[nextIndex]
    }
    
    private func cycleFilterOption() {
        let allOptions = PositionsListView.FilterOption.allCases
        let currentIndex = allOptions.firstIndex(of: filterOption) ?? 0
        let nextIndex = (currentIndex + 1) % allOptions.count
        filterOption = allOptions[nextIndex]
    }
}

// MARK: - StatColumn

struct StatColumn: View {
    let title: String
    let value: String
    let subtitle: String
    let valueColor: Color
    
    init(title: String, value: String, subtitle: String, valueColor: Color = .white) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.valueColor = valueColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(valueColor)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - ControlButton

struct ControlButton: View {
    let title: String
    let systemImage: String
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.body)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(isFocused ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFocused ? .white : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green, lineWidth: isFocused ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - PositionsGridView

struct PositionsGridView: View {
    let positions: [Position]
    @Binding var selectedPosition: Position?
    @Binding var focusedPosition: String?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: gridColumns, spacing: 20) {
                ForEach(positions, id: \.symbol) { position in
                    PositionCard(
                        position: position,
                        isFocused: focusedPosition == position.symbol
                    ) {
                        selectedPosition = position
                    }
                    .focused($focusedPosition, equals: position.symbol)
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ]
    }
}

// MARK: - PositionCard

struct PositionCard: View {
    let position: Position
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Symbol and Side
                HStack {
                    Text(position.symbol)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(position.side.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(position.side == .long ? .blue : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(position.side == .long ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        )
                }
                
                // Quantity and Price
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quantity")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(position.quantity.formatted(.number.precision(.fractionLength(0))))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Avg Cost")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(position.avgEntryPrice.formatted(.currency(code: "USD")))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                
                // Current Value and P&L
                VStack(spacing: 8) {
                    HStack {
                        Text("Market Value")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(position.marketValue.formatted(.currency(code: "USD")))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Unrealized P&L")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(position.unrealizedPL.formatted(.currency(code: "USD")))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(position.unrealizedPL >= 0 ? .green : .red)
                            
                            Text("(\(position.unrealizedPLPercent.formatted(.percent.precision(.fractionLength(2)))))")
                                .font(.caption)
                                .foregroundColor(position.unrealizedPL >= 0 ? .green : .red)
                        }
                    }
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
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - EmptyPositionsView

struct EmptyPositionsView: View {
    let filterOption: PositionsListView.FilterOption
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text(emptyTitle)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text(emptyMessage)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            FocusableButton("Start Trading", systemImage: "plus.circle.fill") {
                // TODO: Navigate to trading interface
            }
        }
        .padding(60)
    }
    
    private var emptyTitle: String {
        switch filterOption {
        case .all: return "No Positions"
        case .profitable: return "No Profitable Positions"
        case .losing: return "No Losing Positions"
        case .longPositions: return "No Long Positions"
        case .shortPositions: return "No Short Positions"
        }
    }
    
    private var emptyMessage: String {
        switch filterOption {
        case .all: return "You don't have any open positions yet. Start trading to see them here."
        case .profitable: return "No positions are currently profitable. Keep monitoring the market."
        case .losing: return "Great! No positions are currently losing money."
        case .longPositions: return "You don't have any long positions at the moment."
        case .shortPositions: return "You don't have any short positions at the moment."
        }
    }
}

#Preview {
    PositionsListView()
        .preferredColorScheme(.dark)
}