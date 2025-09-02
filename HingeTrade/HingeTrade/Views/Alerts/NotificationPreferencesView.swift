//
//  NotificationPreferencesView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var preferencesViewModel = NotificationPreferencesViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: PreferencesSection?
    
    @State private var selectedTab: PreferencesTab = .general
    
    enum PreferencesSection: Hashable {
        case back
        case tab(PreferencesTab)
        case toggle(String)
        case option(String)
        case timeSlider
        case testNotification
        case reset
    }
    
    enum PreferencesTab: String, CaseIterable {
        case general = "General"
        case priceAlerts = "Price Alerts"
        case orders = "Orders"
        case creators = "Creators"
        case news = "Market News"
        case schedule = "Schedule"
        
        var systemImage: String {
            switch self {
            case .general: return "bell.fill"
            case .priceAlerts: return "chart.line.uptrend.xyaxis"
            case .orders: return "checkmark.circle.fill"
            case .creators: return "tv.fill"
            case .news: return "newspaper.fill"
            case .schedule: return "clock.fill"
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                preferencesHeader
                
                // Tabs
                tabsView
                
                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        switch selectedTab {
                        case .general:
                            generalPreferencesSection
                        case .priceAlerts:
                            priceAlertsPreferencesSection
                        case .orders:
                            ordersPreferencesSection
                        case .creators:
                            creatorsPreferencesSection
                        case .news:
                            newsPreferencesSection
                        case .schedule:
                            schedulePreferencesSection
                        }
                        
                        // Action buttons
                        actionButtonsSection
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 30)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await preferencesViewModel.loadPreferences()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
    }
    
    // MARK: - Header
    
    private var preferencesHeader: some View {
        HStack {
            FocusableButton("Back", systemImage: "chevron.left") {
                dismiss()
            }
            .focused($focusedSection, equals: .back)
            
            Spacer()
            
            Text("Notification Preferences")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(preferencesViewModel.notificationsEnabled ? .green : .red)
                    .frame(width: 12, height: 12)
                
                Text(preferencesViewModel.notificationsEnabled ? "Enabled" : "Disabled")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
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
    
    // MARK: - Tabs
    
    private var tabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(PreferencesTab.allCases, id: \.self) { tab in
                    PreferencesTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        isFocused: focusedSection == .tab(tab)
                    ) {
                        selectedTab = tab
                    }
                    .focused($focusedSection, equals: .tab(tab))
                }
            }
            .padding(.horizontal, 60)
        }
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - General Preferences
    
    private var generalPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("General Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            PreferenceCard(
                title: "Push Notifications",
                description: "Enable or disable all push notifications"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.notificationsEnabled,
                    isFocused: focusedSection == .toggle("notifications")
                )
                .focused($focusedSection, equals: .toggle("notifications"))
            }
            
            PreferenceCard(
                title: "Sound",
                description: "Play sound with notifications"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.soundEnabled,
                    isFocused: focusedSection == .toggle("sound")
                )
                .focused($focusedSection, equals: .toggle("sound"))
                .disabled(!preferencesViewModel.notificationsEnabled)
            }
            
            PreferenceCard(
                title: "Badge Count",
                description: "Show unread count on app icon"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.badgeEnabled,
                    isFocused: focusedSection == .toggle("badge")
                )
                .focused($focusedSection, equals: .toggle("badge"))
                .disabled(!preferencesViewModel.notificationsEnabled)
            }
            
            PreferenceCard(
                title: "Notification Style",
                description: "How notifications appear on screen"
            ) {
                PreferenceSelector(
                    options: ["Banner", "Alert", "None"],
                    selectedIndex: preferencesViewModel.notificationStyle.rawValue,
                    isFocused: focusedSection == .option("style")
                ) { index in
                    preferencesViewModel.notificationStyle = NotificationStyle(rawValue: index) ?? .banner
                }
                .focused($focusedSection, equals: .option("style"))
                .disabled(!preferencesViewModel.notificationsEnabled)
            }
        }
    }
    
    // MARK: - Price Alerts Preferences
    
    private var priceAlertsPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Price Alert Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            PreferenceCard(
                title: "Price Alerts",
                description: "Receive notifications when price targets are hit"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.priceAlertsEnabled,
                    isFocused: focusedSection == .toggle("priceAlerts")
                )
                .focused($focusedSection, equals: .toggle("priceAlerts"))
            }
            
            PreferenceCard(
                title: "Alert Types",
                description: "Which types of price alerts to receive"
            ) {
                VStack(spacing: 12) {
                    ForEach(["Price Above Target", "Price Below Target", "Percent Change", "Volume Spike"], id: \.self) { alertType in
                        HStack {
                            Text(alertType)
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            PreferenceToggle(
                                isOn: .constant(true), // Would bind to specific alert type preferences
                                isFocused: focusedSection == .toggle(alertType)
                            )
                            .focused($focusedSection, equals: .toggle(alertType))
                            .disabled(!preferencesViewModel.priceAlertsEnabled)
                        }
                    }
                }
            }
            
            PreferenceCard(
                title: "Alert Frequency",
                description: "How often to check for price changes"
            ) {
                PreferenceSelector(
                    options: ["Real-time", "Every 5 minutes", "Every 15 minutes", "Every hour"],
                    selectedIndex: preferencesViewModel.priceCheckFrequency,
                    isFocused: focusedSection == .option("frequency")
                ) { index in
                    preferencesViewModel.priceCheckFrequency = index
                }
                .focused($focusedSection, equals: .option("frequency"))
                .disabled(!preferencesViewModel.priceAlertsEnabled)
            }
        }
    }
    
    // MARK: - Orders Preferences
    
    private var ordersPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Order Notification Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            PreferenceCard(
                title: "Order Fills",
                description: "Notify when orders are executed"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.orderFillsEnabled,
                    isFocused: focusedSection == .toggle("orderFills")
                )
                .focused($focusedSection, equals: .toggle("orderFills"))
            }
            
            PreferenceCard(
                title: "Partial Fills",
                description: "Notify for partially filled orders"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.partialFillsEnabled,
                    isFocused: focusedSection == .toggle("partialFills")
                )
                .focused($focusedSection, equals: .toggle("partialFills"))
                .disabled(!preferencesViewModel.orderFillsEnabled)
            }
            
            PreferenceCard(
                title: "Order Rejections",
                description: "Notify when orders are rejected"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.orderRejectionsEnabled,
                    isFocused: focusedSection == .toggle("orderRejections")
                )
                .focused($focusedSection, equals: .toggle("orderRejections"))
            }
            
            PreferenceCard(
                title: "Minimum Order Value",
                description: "Only notify for orders above this value"
            ) {
                HStack {
                    Text("$")
                        .foregroundColor(.gray)
                    
                    Text(preferencesViewModel.minimumOrderValue.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    PreferenceSlider(
                        value: Binding(
                            get: { Double(truncating: preferencesViewModel.minimumOrderValue as NSNumber) },
                            set: { preferencesViewModel.minimumOrderValue = Decimal($0) }
                        ),
                        range: 0...10000,
                        isFocused: focusedSection == .option("minOrderValue")
                    )
                    .focused($focusedSection, equals: .option("minOrderValue"))
                    .disabled(!preferencesViewModel.orderFillsEnabled)
                }
            }
        }
    }
    
    // MARK: - Creators Preferences
    
    private var creatorsPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Creator Content Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            PreferenceCard(
                title: "Creator Content",
                description: "Notify when followed creators post new content"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.creatorContentEnabled,
                    isFocused: focusedSection == .toggle("creatorContent")
                )
                .focused($focusedSection, equals: .toggle("creatorContent"))
            }
            
            PreferenceCard(
                title: "Live Streams",
                description: "Special notifications for live content"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.liveStreamsEnabled,
                    isFocused: focusedSection == .toggle("liveStreams")
                )
                .focused($focusedSection, equals: .toggle("liveStreams"))
                .disabled(!preferencesViewModel.creatorContentEnabled)
            }
            
            PreferenceCard(
                title: "Content Types",
                description: "Which types of content to get notified about"
            ) {
                VStack(spacing: 12) {
                    ForEach(["Trading Videos", "Market Analysis", "Educational Content", "Live Trading"], id: \.self) { contentType in
                        HStack {
                            Text(contentType)
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            PreferenceToggle(
                                isOn: .constant(true), // Would bind to specific content type preferences
                                isFocused: focusedSection == .toggle(contentType)
                            )
                            .focused($focusedSection, equals: .toggle(contentType))
                            .disabled(!preferencesViewModel.creatorContentEnabled)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - News Preferences
    
    private var newsPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Market News Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            PreferenceCard(
                title: "Market News",
                description: "Receive breaking market news and updates"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.marketNewsEnabled,
                    isFocused: focusedSection == .toggle("marketNews")
                )
                .focused($focusedSection, equals: .toggle("marketNews"))
            }
            
            PreferenceCard(
                title: "Breaking News Only",
                description: "Only notify for high-importance news"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.breakingNewsOnly,
                    isFocused: focusedSection == .toggle("breakingNews")
                )
                .focused($focusedSection, equals: .toggle("breakingNews"))
                .disabled(!preferencesViewModel.marketNewsEnabled)
            }
            
            PreferenceCard(
                title: "News Categories",
                description: "Which categories of news to receive"
            ) {
                VStack(spacing: 12) {
                    ForEach(["Earnings", "Economic Data", "Company News", "Market Movers", "Regulatory"], id: \.self) { category in
                        HStack {
                            Text(category)
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            PreferenceToggle(
                                isOn: .constant(true), // Would bind to specific category preferences
                                isFocused: focusedSection == .toggle(category)
                            )
                            .focused($focusedSection, equals: .toggle(category))
                            .disabled(!preferencesViewModel.marketNewsEnabled)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Schedule Preferences
    
    private var schedulePreferencesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Notification Schedule")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            PreferenceCard(
                title: "Do Not Disturb",
                description: "Disable notifications during certain hours"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.doNotDisturbEnabled,
                    isFocused: focusedSection == .toggle("doNotDisturb")
                )
                .focused($focusedSection, equals: .toggle("doNotDisturb"))
            }
            
            if preferencesViewModel.doNotDisturbEnabled {
                PreferenceCard(
                    title: "Quiet Hours",
                    description: "No notifications during these hours"
                ) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("From:")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(preferencesViewModel.quietHoursStart.formatted(date: .omitted, time: .shortened))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("To:")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(preferencesViewModel.quietHoursEnd.formatted(date: .omitted, time: .shortened))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                PreferenceCard(
                    title: "Weekend Notifications",
                    description: "Receive notifications on weekends"
                ) {
                    PreferenceToggle(
                        isOn: $preferencesViewModel.weekendNotificationsEnabled,
                        isFocused: focusedSection == .toggle("weekendNotifications")
                    )
                    .focused($focusedSection, equals: .toggle("weekendNotifications"))
                }
            }
            
            PreferenceCard(
                title: "Trading Hours Only",
                description: "Only send notifications during market hours"
            ) {
                PreferenceToggle(
                    isOn: $preferencesViewModel.tradingHoursOnly,
                    isFocused: focusedSection == .toggle("tradingHours")
                )
                .focused($focusedSection, equals: .toggle("tradingHours"))
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                FocusableButton("Test Notification", systemImage: "bell.badge") {
                    Task {
                        await preferencesViewModel.sendTestNotification()
                    }
                }
                .focused($focusedSection, equals: .testNotification)
                .disabled(!preferencesViewModel.notificationsEnabled)
                
                FocusableButton("Reset to Defaults", systemImage: "arrow.counterclockwise") {
                    preferencesViewModel.resetToDefaults()
                }
                .focused($focusedSection, equals: .reset)
                .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Supporting Views

struct PreferencesTabButton: View {
    let tab: NotificationPreferencesView.PreferencesTab
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

struct PreferenceCard<Content: View>: View {
    let title: String
    let description: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PreferenceToggle: View {
    @Binding var isOn: Bool
    let isFocused: Bool
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isOn ? .green : .gray)
                
                Text(isOn ? "Enabled" : "Disabled")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isOn ? .green : .gray)
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PreferenceSelector: View {
    let options: [String]
    let selectedIndex: Int
    let isFocused: Bool
    let onSelectionChange: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: { onSelectionChange(index) }) {
                    Text(options[index])
                        .font(.caption)
                        .fontWeight(selectedIndex == index ? .semibold : .regular)
                        .foregroundColor(selectedIndex == index ? .white : .gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedIndex == index ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct PreferenceSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let isFocused: Bool
    
    var body: some View {
        Slider(value: $value, in: range)
            .tint(.blue)
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    NotificationPreferencesView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}