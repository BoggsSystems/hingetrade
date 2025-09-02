//
//  SettingsView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: SettingsViewSection?
    
    @State private var selectedSection: SettingsSection = .account
    @State private var showingResetAlert = false
    @State private var showingPasswordChange = false
    @State private var showingDataExport = false
    
    enum SettingsViewSection: Hashable {
        case back
        case section(SettingsSection)
        case setting(String)
        case action(String)
    }
    
    var body: some View {
        TVNavigationView {
            HStack(spacing: 0) {
                // Sidebar
                settingsSidebar
                
                // Content Area
                settingsContent
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await settingsViewModel.loadSettings()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settingsViewModel.resetAllSettings()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .sheet(isPresented: $showingPasswordChange) {
            PasswordChangeView()
                .environmentObject(settingsViewModel)
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
                .environmentObject(settingsViewModel)
        }
    }
    
    // MARK: - Sidebar
    
    private var settingsSidebar: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader
            
            // Navigation Sections
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(SettingsSection.allCases, id: \.self) { section in
                        SettingsSidebarItem(
                            section: section,
                            isSelected: selectedSection == section,
                            isFocused: focusedSection == .section(section)
                        ) {
                            selectedSection = section
                        }
                        .focused($focusedSection, equals: .section(section))
                    }
                }
                .padding(.vertical, 20)
            }
            
            Spacer()
            
            // Footer Actions
            sidebarFooter
        }
        .frame(width: 320)
        .background(Color.white.opacity(0.05))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private var sidebarHeader: some View {
        VStack(spacing: 16) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // User Info Card
            if let user = settingsViewModel.currentUser {
                UserInfoCard(user: user)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    private var sidebarFooter: some View {
        VStack(spacing: 12) {
            FocusableButton("Reset All Settings", systemImage: "arrow.clockwise") {
                showingResetAlert = true
            }
            .focused($focusedSection, equals: .action("reset"))
            
            FocusableButton("Export Data", systemImage: "square.and.arrow.up") {
                showingDataExport = true
            }
            .focused($focusedSection, equals: .action("export"))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Content Area
    
    private var settingsContent: some View {
        VStack(spacing: 0) {
            // Content Header
            contentHeader
            
            // Settings Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
                    switch selectedSection {
                    case .account:
                        AccountSettingsView()
                            .environmentObject(settingsViewModel)
                    case .trading:
                        TradingSettingsView()
                            .environmentObject(settingsViewModel)
                    case .risk:
                        RiskSettingsView()
                            .environmentObject(settingsViewModel)
                    case .display:
                        DisplaySettingsView()
                            .environmentObject(settingsViewModel)
                    case .notifications:
                        NotificationSettingsView()
                            .environmentObject(settingsViewModel)
                    case .privacy:
                        PrivacySettingsView()
                            .environmentObject(settingsViewModel)
                    case .security:
                        SecuritySettingsView()
                            .environmentObject(settingsViewModel)
                    case .accessibility:
                        AccessibilitySettingsView()
                            .environmentObject(settingsViewModel)
                    case .advanced:
                        AdvancedSettingsView()
                            .environmentObject(settingsViewModel)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 30)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var contentHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: selectedSection.systemImage)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(selectedSection.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(getSectionDescription(selectedSection))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if settingsViewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 30)
        .background(Color.white.opacity(0.02))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private func getSectionDescription(_ section: SettingsSection) -> String {
        switch section {
        case .account:
            return "Manage your profile and account information"
        case .trading:
            return "Configure trading preferences and defaults"
        case .risk:
            return "Set risk management rules and limits"
        case .display:
            return "Customize appearance and display options"
        case .notifications:
            return "Control alerts and notification preferences"
        case .privacy:
            return "Manage data usage and privacy settings"
        case .security:
            return "Configure security and authentication options"
        case .accessibility:
            return "Adjust accessibility and usability features"
        case .advanced:
            return "Advanced configuration and developer options"
        }
    }
}

// MARK: - Supporting Views

struct SettingsSidebarItem: View {
    let section: SettingsSection
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.systemImage)
                    .font(.body)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(section.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(textColor)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 20)
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
        .padding(.horizontal, 16)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var iconColor: Color {
        if isFocused {
            return .black
        } else if isSelected {
            return .blue
        } else {
            return .gray
        }
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
            return .blue.opacity(0.2)
        } else {
            return Color.clear
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

struct UserInfoCard: View {
    let user: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if user.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Settings Section Views (Placeholder implementations)

struct AccountSettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsGroup(title: "Profile Information") {
                SettingsTextField(
                    title: "Display Name",
                    text: $settingsViewModel.userSettings.displayName,
                    placeholder: "Enter display name"
                )
                
                SettingsTextField(
                    title: "Email Address",
                    text: $settingsViewModel.userSettings.emailAddress,
                    placeholder: "Enter email address"
                )
                
                SettingsPicker(
                    title: "Account Type",
                    selection: Binding(
                        get: { AccountType(rawValue: settingsViewModel.userSettings.accountType) ?? .individual },
                        set: { settingsViewModel.userSettings.accountType = $0.rawValue }
                    ),
                    options: AccountType.allCases
                )
            }
            
            if let accountInfo = settingsViewModel.accountInfo {
                SettingsGroup(title: "Account Information") {
                    SettingsReadOnlyRow(title: "Account ID", value: accountInfo.accountId)
                    SettingsReadOnlyRow(title: "Account Status", value: accountInfo.accountStatus.rawValue.capitalized)
                    SettingsReadOnlyRow(title: "Trading Level", value: accountInfo.tradingLevel.rawValue.capitalized)
                    SettingsReadOnlyRow(title: "Created", value: accountInfo.createdDate.formatted(.dateTime.month().day().year()))
                }
            }
        }
    }
}

struct TradingSettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsGroup(title: "Order Defaults") {
                SettingsPicker(
                    title: "Default Order Type",
                    selection: Binding(
                        get: { OrderType(rawValue: settingsViewModel.userSettings.defaultOrderType) ?? .market },
                        set: { settingsViewModel.userSettings.defaultOrderType = $0.rawValue }
                    ),
                    options: OrderType.allCases
                )
                
                SettingsPicker(
                    title: "Default Time in Force",
                    selection: Binding(
                        get: { TimeInForce(rawValue: settingsViewModel.userSettings.defaultTimeInForce) ?? .day },
                        set: { settingsViewModel.userSettings.defaultTimeInForce = $0.rawValue }
                    ),
                    options: TimeInForce.allCases
                )
                
                SettingsNumericField(
                    title: "Default Quantity",
                    value: $settingsViewModel.userSettings.defaultQuantity,
                    range: 1...1000
                )
            }
            
            SettingsGroup(title: "Trading Options") {
                SettingsToggle(
                    title: "Auto-confirm Orders",
                    subtitle: "Skip confirmation dialog for orders",
                    isOn: $settingsViewModel.userSettings.autoConfirmOrders
                )
                
                SettingsToggle(
                    title: "Enable Fractional Shares",
                    subtitle: "Allow buying partial shares",
                    isOn: $settingsViewModel.userSettings.enableFractionalShares
                )
                
                SettingsToggle(
                    title: "Extended Hours Trading",
                    subtitle: "Enable pre-market and after-hours trading",
                    isOn: $settingsViewModel.userSettings.enableExtendedHours
                )
            }
        }
    }
}

struct RiskSettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsGroup(title: "Risk Profile") {
                SettingsPicker(
                    title: "Risk Profile",
                    selection: Binding(
                        get: { RiskProfile(rawValue: settingsViewModel.userSettings.riskProfile) ?? .moderate },
                        set: { settingsViewModel.userSettings.riskProfile = $0.rawValue }
                    ),
                    options: RiskProfile.allCases
                )
            }
            
            SettingsGroup(title: "Position Limits") {
                SettingsSlider(
                    title: "Max Position Size",
                    subtitle: "Maximum percentage of portfolio per position",
                    value: $settingsViewModel.userSettings.maxPositionSize,
                    range: 0.01...0.50,
                    format: .percent
                )
                
                SettingsSlider(
                    title: "Max Daily Loss",
                    subtitle: "Maximum daily loss as percentage of portfolio",
                    value: $settingsViewModel.userSettings.maxDailyLoss,
                    range: 0.01...0.20,
                    format: .percent
                )
            }
            
            SettingsGroup(title: "Stop Loss Settings") {
                SettingsToggle(
                    title: "Enable Stop Losses",
                    subtitle: "Automatically add stop losses to positions",
                    isOn: $settingsViewModel.userSettings.enableStopLosses
                )
                
                if settingsViewModel.userSettings.enableStopLosses {
                    SettingsSlider(
                        title: "Default Stop Loss %",
                        subtitle: "Default stop loss percentage",
                        value: $settingsViewModel.userSettings.defaultStopLossPercent,
                        range: 0.02...0.25,
                        format: .percent
                    )
                }
                
                SettingsToggle(
                    title: "Enable Position Sizing",
                    subtitle: "Use Kelly criterion for position sizing",
                    isOn: $settingsViewModel.userSettings.enablePositionSizing
                )
            }
        }
    }
}

struct DisplaySettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsGroup(title: "Appearance") {
                SettingsPicker(
                    title: "Theme",
                    selection: Binding(
                        get: { AppTheme(rawValue: settingsViewModel.userSettings.theme) ?? .dark },
                        set: { settingsViewModel.userSettings.theme = $0.rawValue }
                    ),
                    options: AppTheme.allCases
                )
                
                SettingsPicker(
                    title: "Color Scheme",
                    selection: Binding(
                        get: { ColorScheme(rawValue: settingsViewModel.userSettings.colorScheme) ?? .blue },
                        set: { settingsViewModel.userSettings.colorScheme = $0.rawValue }
                    ),
                    options: ColorScheme.allCases
                )
            }
            
            SettingsGroup(title: "Market Data") {
                SettingsToggle(
                    title: "Show After Hours",
                    subtitle: "Display after-hours price changes",
                    isOn: $settingsViewModel.userSettings.showAfterHours
                )
                
                SettingsToggle(
                    title: "Extended Quotes",
                    subtitle: "Show bid/ask and other extended quote data",
                    isOn: $settingsViewModel.userSettings.showExtendedQuotes
                )
            }
            
            SettingsGroup(title: "Formatting") {
                SettingsPicker(
                    title: "Price Format",
                    selection: Binding(
                        get: { PriceFormat(rawValue: settingsViewModel.userSettings.priceFormat) ?? .currency },
                        set: { settingsViewModel.userSettings.priceFormat = $0.rawValue }
                    ),
                    options: PriceFormat.allCases
                )
                
                SettingsPicker(
                    title: "Percent Format",
                    selection: Binding(
                        get: { PercentFormat(rawValue: settingsViewModel.userSettings.percentFormat) ?? .decimal },
                        set: { settingsViewModel.userSettings.percentFormat = $0.rawValue }
                    ),
                    options: PercentFormat.allCases
                )
            }
        }
    }
}

struct NotificationSettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsGroup(title: "General") {
                SettingsToggle(
                    title: "Enable Notifications",
                    subtitle: "Allow HingeTrade to send notifications",
                    isOn: $settingsViewModel.userSettings.notificationsEnabled
                )
                
                if settingsViewModel.userSettings.notificationsEnabled {
                    SettingsToggle(
                        title: "Notification Sounds",
                        subtitle: "Play sounds with notifications",
                        isOn: $settingsViewModel.userSettings.notificationSounds
                    )
                }
            }
            
            if settingsViewModel.userSettings.notificationsEnabled {
                SettingsGroup(title: "Notification Types") {
                    SettingsToggle(
                        title: "Price Alerts",
                        subtitle: "Notify when stocks reach target prices",
                        isOn: $settingsViewModel.userSettings.priceAlertsEnabled
                    )
                    
                    SettingsToggle(
                        title: "Order Updates",
                        subtitle: "Notify on order fills and cancellations",
                        isOn: $settingsViewModel.userSettings.orderUpdatesEnabled
                    )
                    
                    SettingsToggle(
                        title: "Portfolio Updates",
                        subtitle: "Daily portfolio performance summaries",
                        isOn: $settingsViewModel.userSettings.portfolioUpdatesEnabled
                    )
                    
                    SettingsToggle(
                        title: "Market News",
                        subtitle: "Breaking news and market updates",
                        isOn: $settingsViewModel.userSettings.marketNewsEnabled
                    )
                    
                    SettingsToggle(
                        title: "Research Reports",
                        subtitle: "Analyst reports and recommendations",
                        isOn: $settingsViewModel.userSettings.researchReportsEnabled
                    )
                }
            }
        }
    }
}

struct PrivacySettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsGroup(title: "Data Collection") {
                SettingsToggle(
                    title: "Analytics",
                    subtitle: "Help improve the app with usage analytics",
                    isOn: $settingsViewModel.userSettings.analyticsEnabled
                )
                
                SettingsToggle(
                    title: "Crash Reporting",
                    subtitle: "Automatically report app crashes",
                    isOn: $settingsViewModel.userSettings.crashReporting
                )
                
                SettingsToggle(
                    title: "Usage Statistics",
                    subtitle: "Share anonymous usage statistics",
                    isOn: $settingsViewModel.userSettings.usageStatistics
                )
                
                SettingsToggle(
                    title: "Personalization",
                    subtitle: "Use data to personalize your experience",
                    isOn: $settingsViewModel.userSettings.personalizationEnabled
                )
            }
            
            SettingsGroup(title: "Market Data") {
                SettingsToggle(
                    title: "Real-time Quotes",
                    subtitle: "Receive real-time market data",
                    isOn: $settingsViewModel.userSettings.realTimeQuotes
                )
            }
        }
    }
}

struct SecuritySettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @State private var showingPasswordChange = false
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsGroup(title: "Authentication") {
                if settingsViewModel.biometricAvailable {
                    SettingsToggle(
                        title: settingsViewModel.biometricType.displayName,
                        subtitle: "Use \(settingsViewModel.biometricType.displayName.lowercased()) to unlock the app",
                        isOn: $settingsViewModel.userSettings.biometricAuthEnabled
                    )
                }
                
                SettingsToggle(
                    title: "Two-Factor Authentication",
                    subtitle: "Add an extra layer of security",
                    isOn: $settingsViewModel.userSettings.twoFactorEnabled
                )
                
                SettingsButton(
                    title: "Change Password",
                    subtitle: "Update your account password",
                    systemImage: "key.fill"
                ) {
                    showingPasswordChange = true
                }
            }
            
            SettingsGroup(title: "Session Management") {
                SettingsSlider(
                    title: "Auto-logout Time",
                    subtitle: "Automatically log out after inactivity",
                    value: Binding(
                        get: { Double(settingsViewModel.userSettings.autoLogoutMinutes) },
                        set: { settingsViewModel.userSettings.autoLogoutMinutes = Int($0) }
                    ),
                    range: 5...480,
                    format: .minutes
                )
                
                SettingsToggle(
                    title: "Require Auth for Trades",
                    subtitle: "Require authentication before placing trades",
                    isOn: $settingsViewModel.userSettings.requireAuthForTrades
                )
                
                SettingsToggle(
                    title: "Mask Sensitive Data",
                    subtitle: "Hide account balances and positions",
                    isOn: $settingsViewModel.userSettings.maskSensitiveData
                )
            }
            
            if let lastLogin = settingsViewModel.lastLoginDate {
                SettingsGroup(title: "Security Status") {
                    SettingsReadOnlyRow(
                        title: "Last Login",
                        value: lastLogin.formatted(.dateTime.month().day().hour().minute())
                    )
                    
                    if settingsViewModel.loginAttempts > 0 {
                        SettingsReadOnlyRow(
                            title: "Failed Login Attempts",
                            value: "\(settingsViewModel.loginAttempts)"
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingPasswordChange) {
            PasswordChangeView()
                .environmentObject(settingsViewModel)
        }
    }
}

struct AccessibilitySettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsGroup(title: "Visual") {
                SettingsToggle(
                    title: "Large Text",
                    subtitle: "Increase text size throughout the app",
                    isOn: $settingsViewModel.userSettings.largeText
                )
                
                SettingsToggle(
                    title: "High Contrast",
                    subtitle: "Increase contrast for better visibility",
                    isOn: $settingsViewModel.userSettings.highContrast
                )
                
                SettingsToggle(
                    title: "Reduce Motion",
                    subtitle: "Minimize animations and transitions",
                    isOn: $settingsViewModel.userSettings.reduceMotion
                )
            }
            
            SettingsGroup(title: "Interaction") {
                SettingsToggle(
                    title: "VoiceOver",
                    subtitle: "Enable screen reader support",
                    isOn: $settingsViewModel.userSettings.voiceOverEnabled
                )
                
                SettingsToggle(
                    title: "Haptic Feedback",
                    subtitle: "Provide tactile feedback for interactions",
                    isOn: $settingsViewModel.userSettings.hapticFeedback
                )
            }
        }
    }
}

struct AdvancedSettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsGroup(title: "Developer Options") {
                SettingsToggle(
                    title: "Debug Mode",
                    subtitle: "Enable debug logging and diagnostics",
                    isOn: $settingsViewModel.userSettings.debugMode
                )
                
                SettingsToggle(
                    title: "Beta Features",
                    subtitle: "Enable experimental features",
                    isOn: $settingsViewModel.userSettings.betaFeatures
                )
                
                SettingsPicker(
                    title: "API Environment",
                    selection: Binding(
                        get: { APIEnvironment(rawValue: settingsViewModel.userSettings.apiEnvironment) ?? .production },
                        set: { settingsViewModel.userSettings.apiEnvironment = $0.rawValue }
                    ),
                    options: APIEnvironment.allCases
                )
                
                SettingsPicker(
                    title: "Log Level",
                    selection: Binding(
                        get: { LogLevel(rawValue: settingsViewModel.userSettings.logLevel) ?? .info },
                        set: { settingsViewModel.userSettings.logLevel = $0.rawValue }
                    ),
                    options: LogLevel.allCases
                )
            }
            
            SettingsGroup(title: "Performance") {
                SettingsSlider(
                    title: "Cache Size",
                    subtitle: "Maximum cache size in MB",
                    value: Binding(
                        get: { Double(settingsViewModel.userSettings.cacheSizeMB) },
                        set: { settingsViewModel.userSettings.cacheSizeMB = Int($0) }
                    ),
                    range: 50...500,
                    format: .megabytes
                )
            }
            
            SettingsGroup(title: "Data Management") {
                SettingsButton(
                    title: "Clear Cache",
                    subtitle: "Free up storage space",
                    systemImage: "trash.fill"
                ) {
                    Task {
                        await settingsViewModel.clearCache()
                    }
                }
                
                if settingsViewModel.cacheSize > 0 {
                    SettingsReadOnlyRow(
                        title: "Current Cache Size",
                        value: "\(settingsViewModel.cacheSize) MB"
                    )
                }
            }
        }
    }
}

// MARK: - Placeholder Views

struct PasswordChangeView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Change Password")
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

struct DataExportView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Export Data")
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
    SettingsView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}