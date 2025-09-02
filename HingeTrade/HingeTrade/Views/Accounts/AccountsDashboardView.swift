//
//  AccountsDashboardView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct AccountsDashboardView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var accountsViewModel = AccountsViewModel()
    @FocusState private var focusedCard: AccountCard?
    
    enum AccountCard: Hashable {
        case overview
        case positions
        case performance
        case funding
        case settings
    }
    
    var body: some View {
        TVNavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 30) {
                    // Account Header
                    AccountHeaderView()
                        .environmentObject(accountsViewModel)
                    
                    // Main Content Grid
                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        // Account Overview Card
                        AccountOverviewCard()
                            .environmentObject(accountsViewModel)
                            .focused($focusedCard, equals: .overview)
                        
                        // Positions Summary Card
                        PositionsSummaryCard()
                            .environmentObject(accountsViewModel)
                            .focused($focusedCard, equals: .positions)
                        
                        // Performance Card
                        PerformanceCard()
                            .environmentObject(accountsViewModel)
                            .focused($focusedCard, equals: .performance)
                        
                        // Funding Card
                        FundingCard()
                            .environmentObject(accountsViewModel)
                            .focused($focusedCard, equals: .funding)
                    }
                    
                    // Recent Activity Section
                    RecentActivitySection()
                        .environmentObject(accountsViewModel)
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await accountsViewModel.loadAccountData()
            }
            
            // Auto-focus first card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedCard = .overview
            }
        }
        .refreshable {
            await accountsViewModel.refreshData()
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ]
    }
}

// MARK: - AccountHeaderView

struct AccountHeaderView: View {
    @EnvironmentObject private var accountsViewModel: AccountsViewModel
    
    var body: some View {
        HStack(spacing: 40) {
            // Account Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Portfolio Value")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                Text(accountsViewModel.totalEquity.formatted(.currency(code: "USD")))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: accountsViewModel.todaysPLChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(accountsViewModel.todaysPLChange >= 0 ? .green : .red)
                    
                    Text(accountsViewModel.todaysPL.formatted(.currency(code: "USD")))
                        .font(.title2)
                        .foregroundColor(accountsViewModel.todaysPLChange >= 0 ? .green : .red)
                    
                    Text("(\(accountsViewModel.todaysPLPercentage.formatted(.percent.precision(.fractionLength(2)))))")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Quick Stats
            HStack(spacing: 60) {
                StatItem(
                    title: "Buying Power",
                    value: accountsViewModel.buyingPower.formatted(.currency(code: "USD")),
                    subtitle: "Available to trade"
                )
                
                StatItem(
                    title: "Day Trades",
                    value: "\(accountsViewModel.dayTradesUsed)/\(accountsViewModel.dayTradesLimit)",
                    subtitle: "Used this week"
                )
                
                StatItem(
                    title: "Account Type",
                    value: accountsViewModel.accountType.displayName,
                    subtitle: accountsViewModel.marginEnabled ? "Margin enabled" : "Cash account"
                )
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - StatItem

struct StatItem: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - AccountOverviewCard

struct AccountOverviewCard: View {
    @EnvironmentObject private var accountsViewModel: AccountsViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        FocusableCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text("Account Overview")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if accountsViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.green)
                    }
                }
                
                VStack(spacing: 12) {
                    OverviewRow(
                        title: "Cash Balance",
                        value: accountsViewModel.cashBalance.formatted(.currency(code: "USD"))
                    )
                    
                    OverviewRow(
                        title: "Long Market Value",
                        value: accountsViewModel.longMarketValue.formatted(.currency(code: "USD"))
                    )
                    
                    OverviewRow(
                        title: "Short Market Value",
                        value: accountsViewModel.shortMarketValue.formatted(.currency(code: "USD"))
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    OverviewRow(
                        title: "Total Equity",
                        value: accountsViewModel.totalEquity.formatted(.currency(code: "USD")),
                        isHighlighted: true
                    )
                }
            }
        }
        .focused($isFocused)
        .frame(height: 280)
    }
}

// MARK: - OverviewRow

struct OverviewRow: View {
    let title: String
    let value: String
    let isHighlighted: Bool
    
    init(title: String, value: String, isHighlighted: Bool = false) {
        self.title = title
        self.value = value
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(isHighlighted ? .white : .gray)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundColor(isHighlighted ? .green : .white)
        }
    }
}

// MARK: - PositionsSummaryCard

struct PositionsSummaryCard: View {
    @EnvironmentObject private var accountsViewModel: AccountsViewModel
    
    var body: some View {
        FocusableCard(action: {
            // Navigate to full positions view
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet.rectangle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    Text("Positions")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(accountsViewModel.openPositionsCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Biggest Winner")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if let winner = accountsViewModel.biggestWinner {
                            Text("\(winner.symbol) +\(winner.unrealizedPLPercent.formatted(.percent))")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack {
                        Text("Biggest Loser")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if let loser = accountsViewModel.biggestLoser {
                            Text("\(loser.symbol) \(loser.unrealizedPLPercent.formatted(.percent))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    Text("View All Positions")
                        .font(.body)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(height: 280)
    }
}

// MARK: - PerformanceCard & FundingCard (Placeholder implementations)

struct PerformanceCard: View {
    var body: some View {
        FocusableCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.purple)
                    
                    Text("Performance")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Text("Coming soon...")
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .frame(height: 280)
    }
}

struct FundingCard: View {
    var body: some View {
        FocusableCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text("Funding")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Text("Coming soon...")
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .frame(height: 280)
    }
}

struct RecentActivitySection: View {
    @EnvironmentObject private var accountsViewModel: AccountsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent Activity")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Coming soon...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 40)
    }
}

#Preview {
    AccountsDashboardView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}