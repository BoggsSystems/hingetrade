//
//  AppServices.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import Foundation
import os.log

// MARK: - Persistence Service

protocol PersistenceService {
    func saveAppState(_ state: PersistedAppState) async throws
    func loadAppState() async throws -> PersistedAppState?
    func saveUserSession(_ session: UserSession) async throws
    func loadUserSession() async throws -> UserSession?
    func getCacheStatus() async throws -> CacheStatus
    func clearNonEssentialCaches() async throws
    func clearAllCaches() async throws
}

class DefaultPersistenceServiceImpl: PersistenceService {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var appStateURL: URL {
        documentsDirectory.appendingPathComponent("app_state.json")
    }
    
    private var userSessionURL: URL {
        documentsDirectory.appendingPathComponent("user_session.json")
    }
    
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    func saveAppState(_ state: PersistedAppState) async throws {
        let data = try encoder.encode(state)
        try data.write(to: appStateURL)
    }
    
    func loadAppState() async throws -> PersistedAppState? {
        guard fileManager.fileExists(atPath: appStateURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: appStateURL)
        return try decoder.decode(PersistedAppState.self, from: data)
    }
    
    func saveUserSession(_ session: UserSession) async throws {
        let data = try encoder.encode(session)
        try data.write(to: userSessionURL)
    }
    
    func loadUserSession() async throws -> UserSession? {
        guard fileManager.fileExists(atPath: userSessionURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: userSessionURL)
        let session = try decoder.decode(UserSession.self, from: data)
        
        // Check if session is expired
        guard !session.isExpired else {
            try? fileManager.removeItem(at: userSessionURL)
            return nil
        }
        
        return session
    }
    
    func getCacheStatus() async throws -> CacheStatus {
        let cacheSize = try await calculateDirectorySize(cacheDirectory)
        let portfolioCache = try await calculateDirectorySize(cacheDirectory.appendingPathComponent("portfolio"))
        let marketDataCache = try await calculateDirectorySize(cacheDirectory.appendingPathComponent("market_data"))
        let imagesCache = try await calculateDirectorySize(cacheDirectory.appendingPathComponent("images"))
        
        let lastCleared = getLastCacheCleanDate()
        
        return CacheStatus(
            totalSizeMB: Double(cacheSize) / (1024 * 1024),
            portfolioCacheMB: Double(portfolioCache) / (1024 * 1024),
            marketDataCacheMB: Double(marketDataCache) / (1024 * 1024),
            imagesCacheMB: Double(imagesCache) / (1024 * 1024),
            lastClearedAt: lastCleared
        )
    }
    
    func clearNonEssentialCaches() async throws {
        // Clear image cache
        let imagesCache = cacheDirectory.appendingPathComponent("images")
        if fileManager.fileExists(atPath: imagesCache.path) {
            try fileManager.removeItem(at: imagesCache)
            try fileManager.createDirectory(at: imagesCache, withIntermediateDirectories: true)
        }
        
        // Clear old market data cache (keep recent)
        let marketDataCache = cacheDirectory.appendingPathComponent("market_data")
        if fileManager.fileExists(atPath: marketDataCache.path) {
            try await clearOldCacheFiles(in: marketDataCache, olderThan: .hours(2))
        }
        
        recordCacheCleanDate()
    }
    
    func clearAllCaches() async throws {
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.removeItem(at: cacheDirectory)
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        recordCacheCleanDate()
    }
    
    // MARK: - Private Methods
    
    private func calculateDirectorySize(_ directory: URL) async throws -> Int64 {
        guard fileManager.fileExists(atPath: directory.path) else {
            return 0
        }
        
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
        
        var totalSize: Int64 = 0
        for fileURL in contents {
            let fileAttributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += Int64(fileAttributes.fileSize ?? 0)
        }
        
        return totalSize
    }
    
    private func clearOldCacheFiles(in directory: URL, olderThan timeInterval: TimeInterval) async throws {
        let cutoffDate = Date().addingTimeInterval(-timeInterval)
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
        
        for fileURL in contents {
            let fileAttributes = try fileURL.resourceValues(forKeys: [.creationDateKey])
            if let creationDate = fileAttributes.creationDate, creationDate < cutoffDate {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    private func getLastCacheCleanDate() -> Date? {
        return UserDefaults.standard.object(forKey: "last_cache_clean_date") as? Date
    }
    
    private func recordCacheCleanDate() {
        UserDefaults.standard.set(Date(), forKey: "last_cache_clean_date")
    }
}

// MARK: - Performance Monitor

protocol PerformanceMonitor {
    func startMonitoring()
    func stopMonitoring()
    func getCurrentMemoryUsage() -> MemoryUsage
    func logPerformanceMetric(_ metric: PerformanceMetric)
    func getPerformanceReport() -> AppPerformanceReport
}

class DefaultPerformanceMonitor: PerformanceMonitor {
    private var isMonitoring = false
    private var performanceMetrics: [PerformanceMetric] = []
    private let logger = Logger(subsystem: "com.hingetrade.app", category: "performance")
    
    func startMonitoring() {
        isMonitoring = true
        logger.info("Performance monitoring started")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        logger.info("Performance monitoring stopped")
    }
    
    func getCurrentMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / (1024 * 1024)
            let totalMB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024)
            return MemoryUsage(
                usedMemoryMB: usedMB,
                availableMemoryMB: totalMB - usedMB,
                totalMemoryMB: totalMB
            )
        } else {
            return MemoryUsage()
        }
    }
    
    func logPerformanceMetric(_ metric: PerformanceMetric) {
        guard isMonitoring else { return }
        
        performanceMetrics.append(metric)
        
        // Limit stored metrics
        if performanceMetrics.count > 1000 {
            performanceMetrics.removeFirst(performanceMetrics.count - 1000)
        }
        
        logger.info("Performance metric: \(metric.name) - \(metric.value) \(metric.unit)")
    }
    
    func getPerformanceReport() -> AppPerformanceReport {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        let recentMetrics = performanceMetrics.filter { $0.timestamp >= oneHourAgo }
        
        return AppPerformanceReport(
            generatedAt: now,
            totalMetrics: performanceMetrics.count,
            recentMetrics: recentMetrics.count,
            averageMemoryUsage: calculateAverageMemoryUsage(recentMetrics),
            peakMemoryUsage: findPeakMemoryUsage(recentMetrics),
            recommendations: generatePerformanceRecommendations(recentMetrics)
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateAverageMemoryUsage(_ metrics: [PerformanceMetric]) -> Double {
        let memoryMetrics = metrics.filter { $0.name == "memory_usage" }
        guard !memoryMetrics.isEmpty else { return 0 }
        
        let sum = memoryMetrics.reduce(0) { $0 + $1.value }
        return sum / Double(memoryMetrics.count)
    }
    
    private func findPeakMemoryUsage(_ metrics: [PerformanceMetric]) -> Double {
        let memoryMetrics = metrics.filter { $0.name == "memory_usage" }
        return memoryMetrics.max(by: { $0.value < $1.value })?.value ?? 0
    }
    
    private func generatePerformanceRecommendations(_ metrics: [PerformanceMetric]) -> [String] {
        var recommendations: [String] = []
        
        let avgMemory = calculateAverageMemoryUsage(metrics)
        let peakMemory = findPeakMemoryUsage(metrics)
        
        if avgMemory > 500 { // 500 MB
            recommendations.append("Consider clearing image cache to reduce memory usage")
        }
        
        if peakMemory > 800 { // 800 MB
            recommendations.append("High peak memory usage detected - review data loading strategies")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Performance is optimal")
        }
        
        return recommendations
    }
}

// MARK: - Error Logger

protocol ErrorLogger {
    func log(_ error: AppError)
    func log(_ message: String, level: AppLogLevel)
    func getErrorHistory() -> [LogEntry]
    func clearLogs()
    func exportLogs() -> URL?
}

class DefaultErrorLogger: ErrorLogger {
    private let logger = Logger(subsystem: "com.hingetrade.app", category: "errors")
    private var logEntries: [LogEntry] = []
    private let maxLogEntries = 1000
    
    func log(_ error: AppError) {
        let entry = LogEntry(
            timestamp: Date(),
            level: mapErrorSeverityToAppLogLevel(error.severity),
            message: error.localizedDescription,
            context: error.id
        )
        
        logEntries.append(entry)
        limitLogEntries()
        
        // Log to system
        switch error.severity {
        case .critical:
            logger.critical("\(error.localizedDescription)")
        case .severe:
            logger.error("\(error.localizedDescription)")
        case .moderate:
            logger.notice("\(error.localizedDescription)")
        case .warning:
            logger.info("\(error.localizedDescription)")
        case .minor:
            logger.debug("\(error.localizedDescription)")
        }
    }
    
    func log(_ message: String, level: AppLogLevel) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            context: nil
        )
        
        logEntries.append(entry)
        limitLogEntries()
        
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.notice("\(message)")
        case .error:
            logger.error("\(message)")
        }
    }
    
    func getErrorHistory() -> [LogEntry] {
        return logEntries
    }
    
    func clearLogs() {
        logEntries.removeAll()
        logger.info("Log history cleared")
    }
    
    func exportLogs() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let filename = "hingetrade_logs_\(timestamp).txt"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = documentsPath.appendingPathComponent(filename)
        
        do {
            let logContent = logEntries.map { entry in
                "[\(entry.timestamp)] \(entry.level.rawValue.uppercased()): \(entry.message)"
            }.joined(separator: "\n")
            
            try logContent.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            logger.error("Failed to export logs: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func limitLogEntries() {
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst(logEntries.count - maxLogEntries)
        }
    }
    
    private func mapErrorSeverityToAppLogLevel(_ severity: ErrorSeverity) -> AppLogLevel {
        switch severity {
        case .minor:
            return .debug
        case .warning:
            return .warning
        case .moderate:
            return .info
        case .severe, .critical:
            return .error
        }
    }
}

// MARK: - Feature Flag Service

protocol FeatureFlagService {
    func loadFeatureFlags() async throws -> FeatureFlags
    func isFeatureEnabled(_ feature: String) -> Bool
    func enableFeature(_ feature: String)
    func disableFeature(_ feature: String)
}

class DefaultFeatureFlagService: FeatureFlagService {
    private var currentFlags: FeatureFlags?
    
    func loadFeatureFlags() async throws -> FeatureFlags {
        // Simulate API call to fetch feature flags
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // In a real implementation, this would fetch from a remote service
        let flags = FeatureFlags(
            advancedCharting: true,
            optionsTrading: true,
            cryptoSupport: false,
            socialFeatures: false,
            betaAnalytics: true,
            darkMode: true
        )
        
        currentFlags = flags
        return flags
    }
    
    func isFeatureEnabled(_ feature: String) -> Bool {
        guard let flags = currentFlags else { return false }
        
        switch feature {
        case "advanced_charting": return flags.advancedCharting
        case "options_trading": return flags.optionsTrading
        case "crypto_support": return flags.cryptoSupport
        case "social_features": return flags.socialFeatures
        case "beta_analytics": return flags.betaAnalytics
        case "dark_mode": return flags.darkMode
        default: return false
        }
    }
    
    func enableFeature(_ feature: String) {
        // In a real implementation, this would update the remote service
        print("Feature enabled: \(feature)")
    }
    
    func disableFeature(_ feature: String) {
        // In a real implementation, this would update the remote service
        print("Feature disabled: \(feature)")
    }
}

// MARK: - Supporting Models

struct PerformanceMetric {
    let name: String
    let value: Double
    let unit: String
    let timestamp: Date
    
    init(name: String, value: Double, unit: String) {
        self.name = name
        self.value = value
        self.unit = unit
        self.timestamp = Date()
    }
}

struct AppPerformanceReport {
    let generatedAt: Date
    let totalMetrics: Int
    let recentMetrics: Int
    let averageMemoryUsage: Double
    let peakMemoryUsage: Double
    let recommendations: [String]
}

struct LogEntry {
    let timestamp: Date
    let level: AppLogLevel
    let message: String
    let context: String?
}

enum AppLogLevel: String {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
}

// MARK: - Extensions

extension TimeInterval {
    static func hours(_ hours: Double) -> TimeInterval {
        return hours * 3600
    }
    
    static func minutes(_ minutes: Double) -> TimeInterval {
        return minutes * 60
    }
}