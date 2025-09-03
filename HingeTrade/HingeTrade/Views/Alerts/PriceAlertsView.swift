//
//  PriceAlertsView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct PriceAlertsView: View {
    @StateObject private var alertsViewModel = PriceAlertsViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: AlertsSection?
    @State private var showingCreateAlert = false
    @State private var selectedAlert: PriceAlert?
    @State private var selectedFilter: AlertFilter = .all
    
    enum AlertsSection: Hashable {
        case back
        case createNew
        case filter(AlertFilter)
        case alert(String)
        case searchField
    }
    
    enum AlertFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case triggered = "Triggered"
        case expired = "Expired"
        
        var systemImage: String {
            switch self {
            case .all: return "bell.fill"
            case .active: return "bell.badge.fill"
            case .triggered: return "bell.and.waveform.fill"
            case .expired: return "bell.slash.fill"
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                alertsHeader
                
                // Filters
                filtersView
                
                // Content
                if alertsViewModel.isLoading {
                    LoadingStateView(message: "Loading alerts...")
                        .frame(maxHeight: .infinity)
                } else if alertsViewModel.filteredAlerts.isEmpty {
                    emptyStateView
                } else {
                    alertsListView
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await alertsViewModel.loadAlerts()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(isPresented: $showingCreateAlert) {
            CreatePriceAlertView()
                .environmentObject(alertsViewModel)
        }
        .sheet(item: $selectedAlert) { alert in
            PriceAlertDetailView(alert: alert)
                .environmentObject(alertsViewModel)
        }
    }
    
    // MARK: - Header
    
    private var alertsHeader: some View {
        VStack(spacing: 20) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                Text("Price Alerts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                FocusableButton("New Alert", systemImage: "plus.circle.fill") {
                    showingCreateAlert = true
                }
                .focused($focusedSection, equals: .createNew)
            }
            
            // Stats Row
            alertsStatsView
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
    
    private var alertsStatsView: some View {
        HStack(spacing: 40) {
            AlertStatCard(
                title: "Active",
                value: alertsViewModel.activeAlertsCount.formatted(.number),
                color: .green
            )
            
            AlertStatCard(
                title: "Triggered Today",
                value: alertsViewModel.triggeredTodayCount.formatted(.number),
                color: .orange
            )
            
            AlertStatCard(
                title: "Total Alerts",
                value: alertsViewModel.totalAlertsCount.formatted(.number),
                color: .blue
            )
            
            AlertStatCard(
                title: "Success Rate",
                value: alertsViewModel.successRate.formatted(.percent.precision(.fractionLength(0))),
                color: alertsViewModel.successRate > 0.5 ? .green : .red
            )
            
            Spacer()
        }
    }
    
    // MARK: - Filters
    
    private var filtersView: some View {
        HStack(spacing: 16) {
            ForEach(AlertFilter.allCases, id: \.self) { filter in
                AlertFilterButton(
                    filter: filter,
                    isSelected: selectedFilter == filter,
                    isFocused: focusedSection == .filter(filter),
                    count: alertsViewModel.getCount(for: filter)
                ) {
                    selectedFilter = filter
                    alertsViewModel.setFilter(filter)
                }
                .focused($focusedSection, equals: .filter(filter))
            }
            
            Spacer()
            
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search symbols...", text: $alertsViewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .focused($focusedSection, equals: .searchField)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .stroke(focusedSection == .searchField ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .frame(width: 200)
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Content
    
    private var alertsListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(alertsViewModel.filteredAlerts, id: \.id) { alert in
                    PriceAlertRow(
                        alert: alert,
                        isFocused: focusedSection == .alert(alert.id)
                    ) {
                        selectedAlert = alert
                    } onToggle: {
                        Task {
                            await alertsViewModel.toggleAlert(alert)
                        }
                    } onDelete: {
                        Task {
                            await alertsViewModel.deleteAlert(alert)
                        }
                    }
                    .focused($focusedSection, equals: .alert(alert.id))
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            title: emptyStateTitle,
            message: emptyStateMessage,
            systemImage: "bell.slash",
            actionTitle: "Create Alert",
            action: {
                showingCreateAlert = true
            }
        )
        .frame(maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return "No Price Alerts"
        case .active:
            return "No Active Alerts"
        case .triggered:
            return "No Triggered Alerts"
        case .expired:
            return "No Expired Alerts"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "Create your first price alert to get notified when stocks hit your target prices"
        case .active:
            return "You don't have any active price alerts at the moment"
        case .triggered:
            return "None of your alerts have been triggered recently"
        case .expired:
            return "You don't have any expired alerts"
        }
    }
}

// MARK: - Supporting Views

struct AlertStatCard: View {
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct AlertFilterButton: View {
    let filter: PriceAlertsView.AlertFilter
    let isSelected: Bool
    let isFocused: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.systemImage)
                    .font(.body)
                
                Text(filter.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .foregroundColor(buttonForegroundColor)
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
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var buttonForegroundColor: Color {
        if isFocused {
            return .black
        } else if isSelected {
            return .orange
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return Color.orange.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return .orange
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

struct PriceAlertRow: View {
    let alert: PriceAlert
    let isFocused: Bool
    let onTap: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            contentView
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var contentView: some View {
        HStack(spacing: 16) {
            statusIndicator
            alertInfoView
            actionButtonsView
        }
        .padding(16)
        .background(backgroundView)
        .overlay(overlayView)
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
    }
    
    private var alertInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            detailsRow
        }
    }
    
    private var headerRow: some View {
        HStack {
            Text(alert.symbol)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("•")
                .foregroundColor(.gray)
            
            Text(String(describing: alert.condition))
                .font(.body)
                .foregroundColor(.gray)
            
            Spacer()
            
            currentPriceView
        }
    }
    
    private var currentPriceView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("$175.50")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("+1.2%")
                .font(.caption)
                .foregroundColor(.green)
        }
    }
    
    private var detailsRow: some View {
        HStack {
            targetInfoView
            
            Text("•")
                .foregroundColor(.gray)
            
            Text("5.2% away")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(alert.createdAt.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var targetInfoView: some View {
        HStack(spacing: 4) {
            Text("Target:")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(String(format: "$%.2f", alert.price))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        if alert.isActive {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: "pause.circle")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else if alert.triggeredAt != nil {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
    }
    
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(borderColor, lineWidth: isFocused ? 2 : 0)
    }
    
    private var statusColor: Color {
        if !alert.isActive {
            return .gray
        } else if alert.triggeredAt != nil {
            return .green
        } else {
            return .orange
        }
    }
    
    private var borderColor: Color {
        if alert.triggeredAt != nil {
            return .green
        } else {
            return .orange
        }
    }
}

#Preview {
    PriceAlertsView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}