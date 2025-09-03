//
//  AppState.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

// MARK: - App State Management

@MainActor
class AppLifecycleViewModel: ObservableObject {
    
    // MARK: - App Lifecycle
    @Published var appPhase: AppPhase = .inactive
    @Published var isFirstLaunch: Bool = true
    @Published var lastLaunchVersion: String?
    @Published var needsOnboarding: Bool = false
    
    // MARK: - Authentication State
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserSession?
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var biometricAuthAvailable: Bool = false
    
    // MARK: - Navigation State
    @Published var currentTab: MainTab = .portfolio
    @Published var navigationHistory: [NavigationState] = []
    @Published var modalStack: [ModalView] = []
    @Published var currentModal: ModalView?
    
    // MARK: - App Performance
    @Published var isPerformanceMonitoringEnabled: Bool = true
    @Published var memoryUsage: MemoryUsage = MemoryUsage()
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var lastPerformanceCheck: Date?
    
    // MARK: - Data State
    @Published var cacheStatus: CacheStatus = CacheStatus()
    @Published var dataLoadingState: DataLoadingState = .idle
    @Published var lastDataRefresh: Date?
    @Published var backgroundRefreshEnabled: Bool = true
    
    // MARK: - Error Handling
    @Published var globalError: AppLifecycleError?
    @Published var showingGlobalError: Bool = false
    @Published var errorHistory: [AppLifecycleError] = []
    
    // MARK: - Feature Flags
    @Published var featureFlags: FeatureFlags = FeatureFlags()
    @Published var betaFeaturesEnabled: Bool = false
    
    // MARK: - Services
    private let persistenceService: DefaultPersistenceServiceImpl
    private let performanceMonitor: PerformanceMonitor
    private let errorLogger: ErrorLogger
    private let featureFlagService: FeatureFlagService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        persistenceService: DefaultPersistenceServiceImpl = DefaultPersistenceServiceImpl(),
        performanceMonitor: PerformanceMonitor = DefaultPerformanceMonitor(),
        errorLogger: ErrorLogger = DefaultErrorLogger(),
        featureFlagService: FeatureFlagService = DefaultFeatureFlagService()
    ) {
        self.persistenceService = persistenceService
        self.performanceMonitor = performanceMonitor
        self.errorLogger = errorLogger
        self.featureFlagService = featureFlagService
        
        setupBindings()
        loadPersistedState()
    }
    
    // MARK: - App Lifecycle Management
    
    func applicationDidFinishLaunching() {
        appPhase = .active
        
        Task {
            await initializeApp()
        }
    }
    
    func applicationWillResignActive() {
        appPhase = .inactive
        persistAppState()
    }
    
    func applicationDidEnterBackground() {
        appPhase = .background
        
        Task {
            await handleBackgroundTransition()
        }
    }
    
    func applicationWillEnterForeground() {
        Task {
            await handleForegroundTransition()
        }
    }
    
    func applicationDidBecomeActive() {
        appPhase = .active
        
        Task {
            await refreshAppState()
        }
    }
    
    private func initializeApp() async {
        do {
            // Load feature flags
            featureFlags = try await featureFlagService.loadFeatureFlags()
            
            // Check authentication state
            await checkAuthenticationState()
            
            // Initialize performance monitoring
            if isPerformanceMonitoringEnabled {
                performanceMonitor.startMonitoring()
            }
            
            // Load cached data
            await loadCachedData()
            
            // Check for app updates
            await checkForAppUpdates()
            
        } catch {
            handleGlobalError(AppLifecycleError.initializationFailed(error.localizedDescription))
        }
    }
    
    private func checkAuthenticationState() async {
        do {
            if let session = try await persistenceService.loadUserSession() {
                currentUser = session
                isAuthenticated = !session.isExpired
                authenticationState = session.isExpired ? .expired : .authenticated
            } else {
                authenticationState = .unauthenticated
            }
        } catch {
            authenticationState = .unauthenticated
            errorLogger.log("Authentication failed: \(error.localizedDescription)", level: AppLogLevel.error)
        }
    }
    
    // MARK: - Navigation Management
    
    func navigate(to tab: MainTab) {
        let previousTab = currentTab
        currentTab = tab
        
        // Record navigation history
        let navigationState = NavigationState(
            tab: previousTab,
            timestamp: Date(),
            context: "tab_change"
        )
        navigationHistory.append(navigationState)
        
        // Limit history size
        if navigationHistory.count > 50 {
            navigationHistory.removeFirst(navigationHistory.count - 50)
        }
    }
    
    func presentModal(_ modal: ModalView) {
        modalStack.append(modal)
        currentModal = modal
    }
    
    func dismissModal() {
        if !modalStack.isEmpty {
            modalStack.removeLast()
        }
        currentModal = modalStack.last
    }
    
    func dismissAllModals() {
        modalStack.removeAll()
        currentModal = nil
    }
    
    // MARK: - Data Management
    
    func refreshAllData() async {
        dataLoadingState = .loading
        
        do {
            // Refresh core data
            async let portfolioRefresh = refreshPortfolioData()
            async let watchlistRefresh = refreshWatchlistData()
            async let marketRefresh = refreshMarketData()
            
            try await portfolioRefresh
            try await watchlistRefresh
            try await marketRefresh
            
            lastDataRefresh = Date()
            dataLoadingState = .loaded
            
        } catch {
            dataLoadingState = .error(error.localizedDescription)
            handleGlobalError(AppLifecycleError.dataRefreshFailed(error.localizedDescription))
        }
    }
    
    private func refreshPortfolioData() async throws {
        // Implement portfolio data refresh
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func refreshWatchlistData() async throws {
        // Implement watchlist data refresh  
        try await Task.sleep(nanoseconds: 800_000_000)
    }
    
    private func refreshMarketData() async throws {
        // Implement market data refresh
        try await Task.sleep(nanoseconds: 1_200_000_000)
    }
    
    private func loadCachedData() async {
        do {
            cacheStatus = try await persistenceService.getCacheStatus()
        } catch {
            errorLogger.log("Cache loading failed: \(error.localizedDescription)", level: AppLogLevel.error)
        }
    }
    
    // MARK: - Performance Monitoring
    
    func startPerformanceMonitoring() {
        guard isPerformanceMonitoringEnabled else { return }
        
        performanceMonitor.startMonitoring()
        
        // Monitor memory usage
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateMemoryUsage()
                }
            }
            .store(in: &cancellables)
    }
    
    func stopPerformanceMonitoring() {
        performanceMonitor.stopMonitoring()
    }
    
    private func updateMemoryUsage() {
        memoryUsage = performanceMonitor.getCurrentMemoryUsage()
        lastPerformanceCheck = Date()
        
        // Check for memory warnings
        if memoryUsage.percentageUsed > 0.8 {
            handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        // Clear unnecessary caches
        Task {
            await clearNonEssentialCaches()
        }
        
        // Log memory warning
        errorLogger.log("High memory usage: \(memoryUsage.percentageUsed * 100)%", level: AppLogLevel.warning)
    }
    
    // MARK: - Error Handling
    
    func handleGlobalError(_ error: AppLifecycleError) {
        globalError = error
        showingGlobalError = true
        errorHistory.append(error)
        
        // Log error
        errorLogger.log("App lifecycle error: \(error.localizedDescription)", level: AppLogLevel.error)
        
        // Limit error history
        if errorHistory.count > 100 {
            errorHistory.removeFirst(errorHistory.count - 100)
        }
    }
    
    func dismissGlobalError() {
        globalError = nil
        showingGlobalError = false
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    // MARK: - State Persistence
    
    func persistAppState() {
        let appState = PersistedAppState(
            currentTab: currentTab,
            isAuthenticated: isAuthenticated,
            lastLaunchVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            lastDataRefresh: lastDataRefresh,
            featureFlags: featureFlags
        )
        
        Task {
            try? await persistenceService.saveAppState(appState)
        }
    }
    
    private func loadPersistedState() {
        Task {
            do {
                if let state = try await persistenceService.loadAppState() {
                    await MainActor.run {
                        currentTab = state.currentTab
                        isAuthenticated = state.isAuthenticated
                        lastLaunchVersion = state.lastLaunchVersion
                        lastDataRefresh = state.lastDataRefresh
                        featureFlags = state.featureFlags
                        
                        // Check if this is first launch
                        isFirstLaunch = lastLaunchVersion == nil
                        needsOnboarding = isFirstLaunch || !isAuthenticated
                    }
                } else {
                    await MainActor.run {
                        isFirstLaunch = true
                        needsOnboarding = true
                    }
                }
            } catch {
                errorLogger.log("Persistence loading failed: \(error.localizedDescription)", level: AppLogLevel.error)
            }
        }
    }
    
    // MARK: - Background/Foreground Handling
    
    private func handleBackgroundTransition() async {
        // Save app state
        persistAppState()
        
        // Pause non-essential services
        stopPerformanceMonitoring()
        
        // Clean up resources
        await clearNonEssentialCaches()
    }
    
    private func handleForegroundTransition() async {
        appPhase = .active
        
        // Resume services
        if isPerformanceMonitoringEnabled {
            startPerformanceMonitoring()
        }
        
        // Refresh data if needed
        if shouldRefreshData() {
            await refreshAllData()
        }
        
        // Check authentication state
        await checkAuthenticationState()
    }
    
    private func refreshAppState() async {
        // Update network status
        networkStatus = await checkNetworkStatus()
        
        // Refresh feature flags
        do {
            featureFlags = try await featureFlagService.loadFeatureFlags()
        } catch {
            errorLogger.log("Feature flag loading failed: \(error.localizedDescription)", level: AppLogLevel.error)
        }
    }
    
    private func shouldRefreshData() -> Bool {
        guard let lastRefresh = lastDataRefresh else { return true }
        return Date().timeIntervalSince(lastRefresh) > 300 // 5 minutes
    }
    
    private func checkNetworkStatus() async -> NetworkStatus {
        // Mock network status check
        return .connected
    }
    
    private func clearNonEssentialCaches() async {
        try? await persistenceService.clearNonEssentialCaches()
        await loadCachedData()
    }
    
    private func checkForAppUpdates() async {
        // Mock app update check
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    // MARK: - Helper Methods
    
    private func setupBindings() {
        $globalError
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingGlobalError = true
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
        // Note: persistAppState() is called during app lifecycle events, not in deinit
    }
}

// MARK: - Supporting Models

enum AppPhase {
    case inactive
    case active
    case background
}

enum MainTab: String, CaseIterable, Codable {
    case portfolio = "Portfolio"
    case watchlist = "Watchlist"
    case trading = "Trading"
    case analytics = "Analytics"
    case discover = "Discover"
    case settings = "Settings"
    
    var systemImage: String {
        switch self {
        case .portfolio: return "briefcase.fill"
        case .watchlist: return "star.fill"
        case .trading: return "chart.line.uptrend.xyaxis"
        case .analytics: return "chart.bar.fill"
        case .discover: return "play.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

enum AuthenticationState {
    case unauthenticated
    case authenticated
    case expired
    case locked
}

enum DataLoadingState {
    case idle
    case loading
    case loaded
    case error(String)
}

enum NetworkStatus {
    case unknown
    case notConnected
    case connected
    case slow
}

struct UserSession: Codable {
    let userId: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let lastActivityAt: Date
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
}

struct NavigationState: Codable {
    let tab: MainTab
    let timestamp: Date
    let context: String
}

struct ModalView: Identifiable, Hashable {
    let id = UUID()
    let type: ModalType
    let context: [String: String]?
    
    enum ModalType: String, CaseIterable {
        case onboarding = "onboarding"
        case authentication = "authentication"
        case orderEntry = "order_entry"
        case settings = "settings"
        case help = "help"
        case error = "error"
    }
}

struct MemoryUsage {
    let usedMemoryMB: Double
    let availableMemoryMB: Double
    let totalMemoryMB: Double
    
    var percentageUsed: Double {
        return usedMemoryMB / totalMemoryMB
    }
    
    init() {
        // Mock values
        self.totalMemoryMB = 1024
        self.usedMemoryMB = Double.random(in: 200...800)
        self.availableMemoryMB = totalMemoryMB - usedMemoryMB
    }
}

struct CacheStatus {
    let totalSizeMB: Double
    let portfolioCacheMB: Double
    let marketDataCacheMB: Double
    let imagesCacheMB: Double
    let lastClearedAt: Date?
    
    init() {
        self.totalSizeMB = Double.random(in: 50...200)
        self.portfolioCacheMB = Double.random(in: 10...50)
        self.marketDataCacheMB = Double.random(in: 20...80)
        self.imagesCacheMB = Double.random(in: 5...30)
        self.lastClearedAt = Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...7), to: Date())
    }
    
    init(totalSizeMB: Double, portfolioCacheMB: Double, marketDataCacheMB: Double, imagesCacheMB: Double, lastClearedAt: Date?) {
        self.totalSizeMB = totalSizeMB
        self.portfolioCacheMB = portfolioCacheMB
        self.marketDataCacheMB = marketDataCacheMB
        self.imagesCacheMB = imagesCacheMB
        self.lastClearedAt = lastClearedAt
    }
}

struct FeatureFlags: Codable {
    let advancedCharting: Bool
    let optionsTrading: Bool
    let cryptoSupport: Bool
    let socialFeatures: Bool
    let betaAnalytics: Bool
    let darkMode: Bool
    
    init() {
        self.advancedCharting = true
        self.optionsTrading = true
        self.cryptoSupport = false
        self.socialFeatures = false
        self.betaAnalytics = true
        self.darkMode = true
    }
}

struct PersistedAppState: Codable {
    let currentTab: MainTab
    let isAuthenticated: Bool
    let lastLaunchVersion: String?
    let lastDataRefresh: Date?
    let featureFlags: FeatureFlags
}

// MARK: - Error Types

enum AppLifecycleError: LocalizedError, Identifiable {
    case initializationFailed(String)
    case authenticationFailed(String)
    case dataRefreshFailed(String)
    case networkError(String)
    case cacheLoadFailed(String)
    case persistenceLoadFailed(String)
    case persistenceSaveFailed(String)
    case featureFlagLoadFailed(String)
    case memoryWarning(String)
    case unexpectedError(String)
    
    var id: String {
        switch self {
        case .initializationFailed(let message),
             .authenticationFailed(let message),
             .dataRefreshFailed(let message),
             .networkError(let message),
             .cacheLoadFailed(let message),
             .persistenceLoadFailed(let message),
             .persistenceSaveFailed(let message),
             .featureFlagLoadFailed(let message),
             .memoryWarning(let message),
             .unexpectedError(let message):
            return message
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "App initialization failed: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .dataRefreshFailed(let message):
            return "Data refresh failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .cacheLoadFailed(let message):
            return "Cache load failed: \(message)"
        case .persistenceLoadFailed(let message):
            return "Failed to load saved data: \(message)"
        case .persistenceSaveFailed(let message):
            return "Failed to save data: \(message)"
        case .featureFlagLoadFailed(let message):
            return "Feature flag load failed: \(message)"
        case .memoryWarning(let message):
            return "Memory warning: \(message)"
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .memoryWarning, .networkError:
            return .warning
        case .cacheLoadFailed, .featureFlagLoadFailed:
            return .minor
        case .dataRefreshFailed, .persistenceLoadFailed:
            return .moderate
        case .initializationFailed, .authenticationFailed:
            return .critical
        case .persistenceSaveFailed, .unexpectedError:
            return .severe
        }
    }
}

enum ErrorSeverity: String {
    case minor = "minor"
    case warning = "warning"
    case moderate = "moderate"
    case severe = "severe"
    case critical = "critical"
    
    var color: String {
        switch self {
        case .minor: return "00FF00"
        case .warning: return "FFFF00"
        case .moderate: return "FF8000"
        case .severe: return "FF0000"
        case .critical: return "8B0000"
        }
    }
}