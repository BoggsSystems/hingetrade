//
//  AnalyticsViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    // MARK: - Portfolio Performance
    @Published var currentPerformance: PortfolioPerformance?
    @Published var performanceHistory: PerformanceHistory?
    @Published var selectedPeriod: PerformancePeriod = .month1
    
    // MARK: - Charts
    @Published var performanceChart: PerformanceChart?
    @Published var allocationChart: AllocationChart?
    @Published var sectorChart: AllocationChart?
    @Published var selectedChartType: ChartType = .area
    @Published var showBenchmark = true
    @Published var showDrawdown = false
    
    // MARK: - Analytics Data
    @Published var performanceAnalysis: PerformanceAnalysisResult?
    @Published var sectorPerformance: [SectorPerformance] = []
    @Published var topPerformers: [PositionPerformance] = []
    @Published var underPerformers: [PositionPerformance] = []
    @Published var benchmarkComparisons: [BenchmarkComparison] = []
    
    // MARK: - Recommendations
    @Published var recommendations: [PerformanceRecommendation] = []
    @Published var implementedRecommendations: Set<String> = []
    
    // MARK: - Settings
    @Published var selectedBenchmark: String = "SPY"
    @Published var availableBenchmarks: [String] = ["SPY", "QQQ", "VTI", "IWM"]
    @Published var analysisFrequency: PerformanceFrequency = .daily
    
    // MARK: - State
    @Published var isLoading = false
    @Published var error: AnalyticsError?
    @Published var showingError = false
    @Published var lastUpdated: Date?
    
    // Services
    private let analyticsService: AnalyticsService
    private let performanceService: PerformanceService
    private let chartService: ChartService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        analyticsService: AnalyticsService = AnalyticsService(),
        performanceService: PerformanceService = PerformanceService(),
        chartService: ChartService = ChartService()
    ) {
        self.analyticsService = analyticsService
        self.performanceService = performanceService
        self.chartService = chartService
        
        setupBindings()
    }
    
    // MARK: - Data Loading
    
    func loadAnalyticsData() async {
        isLoading = true
        error = nil
        
        do {
            // Load performance data
            async let performanceTask = loadPerformanceData()
            async let analysisTask = loadPerformanceAnalysis()
            async let chartsTask = loadChartData()
            async let recommendationsTask = loadRecommendations()
            
            await performanceTask
            await analysisTask
            await chartsTask  
            await recommendationsTask
            
            lastUpdated = Date()
            
        } catch {
            self.error = AnalyticsError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    private func loadPerformanceData() async {
        do {
            let performance = try await performanceService.getCurrentPerformance()
            currentPerformance = performance
            
            let history = try await performanceService.getPerformanceHistory(
                period: selectedPeriod,
                frequency: analysisFrequency
            )
            performanceHistory = history
            
        } catch {
            print("Failed to load performance data: \(error)")
        }
    }
    
    private func loadPerformanceAnalysis() async {
        do {
            let analysis = try await analyticsService.analyzePerformance(
                period: selectedPeriod,
                benchmark: selectedBenchmark
            )
            performanceAnalysis = analysis
            
            // Update related data
            sectorPerformance = analysis.sectorAnalysis
            topPerformers = analysis.topPerformers
            underPerformers = analysis.underPerformers
            benchmarkComparisons = analysis.benchmarkComparisons
            
        } catch {
            print("Failed to load performance analysis: \(error)")
        }
    }
    
    private func loadChartData() async {
        do {
            // Performance Chart
            if let history = performanceHistory {
                performanceChart = try await chartService.createPerformanceChart(
                    history: history,
                    benchmark: selectedBenchmark,
                    showBenchmark: showBenchmark,
                    showDrawdown: showDrawdown
                )
            }
            
            // Allocation Charts
            if let performance = currentPerformance {
                allocationChart = try await chartService.createAllocationChart(
                    positions: performance.positions,
                    chartType: .pie
                )
                
                sectorChart = try await chartService.createSectorChart(
                    sectorPerformance: sectorPerformance,
                    chartType: .donut
                )
            }
            
        } catch {
            print("Failed to load chart data: \(error)")
        }
    }
    
    private func loadRecommendations() async {
        do {
            let recs = try await analyticsService.getPerformanceRecommendations(
                analysis: performanceAnalysis
            )
            recommendations = recs
            
        } catch {
            print("Failed to load recommendations: \(error)")
        }
    }
    
    // MARK: - Period Selection
    
    func selectPeriod(_ period: PerformancePeriod) {
        selectedPeriod = period
        Task {
            await refreshDataForPeriod()
        }
    }
    
    private func refreshDataForPeriod() async {
        // Reload data for new period
        await loadPerformanceData()
        await loadPerformanceAnalysis()
        await loadChartData()
    }
    
    // MARK: - Chart Configuration
    
    func updateChartSettings(
        showBenchmark: Bool? = nil,
        showDrawdown: Bool? = nil,
        chartType: ChartType? = nil
    ) {
        if let showBenchmark = showBenchmark {
            self.showBenchmark = showBenchmark
        }
        
        if let showDrawdown = showDrawdown {
            self.showDrawdown = showDrawdown
        }
        
        if let chartType = chartType {
            self.selectedChartType = chartType
        }
        
        Task {
            await loadChartData()
        }
    }
    
    // MARK: - Benchmark Management
    
    func selectBenchmark(_ benchmark: String) {
        selectedBenchmark = benchmark
        Task {
            await refreshBenchmarkData()
        }
    }
    
    private func refreshBenchmarkData() async {
        await loadPerformanceAnalysis()
        await loadChartData()
    }
    
    // MARK: - Recommendations
    
    func implementRecommendation(_ recommendationId: String) async {
        implementedRecommendations.insert(recommendationId)
        
        // In a real implementation, this would trigger specific actions
        do {
            try await analyticsService.implementRecommendation(recommendationId)
        } catch {
            print("Failed to implement recommendation: \(error)")
            implementedRecommendations.remove(recommendationId)
        }
    }
    
    func dismissRecommendation(_ recommendationId: String) {
        recommendations.removeAll { $0.id == recommendationId }
    }
    
    // MARK: - Position Analysis
    
    func analyzePosition(_ symbol: String) async -> PositionPerformance? {
        do {
            return try await performanceService.getPositionPerformance(
                symbol: symbol,
                period: selectedPeriod
            )
        } catch {
            print("Failed to analyze position \(symbol): \(error)")
            return nil
        }
    }
    
    // MARK: - Export & Reporting
    
    func generatePerformanceReport() async -> PerformanceReport? {
        do {
            return try await analyticsService.generateReport(
                analysis: performanceAnalysis,
                period: selectedPeriod
            )
        } catch {
            print("Failed to generate performance report: \(error)")
            return nil
        }
    }
    
    func exportChartData(_ chartType: ChartType) async -> ChartExportData? {
        do {
            return try await chartService.exportChart(
                chartType: chartType,
                period: selectedPeriod
            )
        } catch {
            print("Failed to export chart data: \(error)")
            return nil
        }
    }
    
    // MARK: - Real-time Updates
    
    func startRealTimeUpdates() {
        // Would implement real-time data updates
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshCurrentPerformance()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshCurrentPerformance() async {
        do {
            let performance = try await performanceService.getCurrentPerformance()
            currentPerformance = performance
        } catch {
            print("Failed to refresh current performance: \(error)")
        }
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
            }
            .store(in: &cancellables)
    }
    
    func dismissError() {
        error = nil
        showingError = false
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Supporting Models

struct PerformanceReport {
    let reportId: String
    let generatedDate: Date
    let period: PerformancePeriod
    let summary: PerformanceSummary
    let detailedAnalysis: DetailedAnalysis
    let charts: [ChartData]
    let recommendations: [PerformanceRecommendation]
    let metadata: ReportMetadata
}

struct PerformanceSummary {
    let totalReturn: Double
    let annualizedReturn: Double
    let sharpeRatio: Double
    let maxDrawdown: Double
    let volatility: Double
    let benchmarkOutperformance: Double
    let winRate: Double
    let bestPosition: String
    let worstPosition: String
}

struct DetailedAnalysis {
    let returnAnalysis: ReturnAnalysis
    let riskAnalysis: DetailedRiskAnalysis
    let attributionAnalysis: AttributionAnalysis
    let benchmarkAnalysis: DetailedBenchmarkAnalysis
}

struct ReturnAnalysis {
    let periodicReturns: [PeriodReturn]
    let rollingReturns: [RollingReturn]
    let returnDistribution: ReturnDistribution
    let consistencyMetrics: ConsistencyMetrics
}

struct RiskAnalysis {
    let volatilityAnalysis: VolatilityAnalysis
    let drawdownAnalysis: DrawdownAnalysis
    let varAnalysis: VaRAnalysis
    let stressTestResults: [StressTestResult]
}

struct AttributionAnalysis {
    let sectorAttribution: [SectorAttribution]
    let securityAttribution: [SecurityAttribution]
    let styleAttribution: StyleAttribution?
    let currencyAttribution: CurrencyAttribution?
}

struct ChartExportData {
    let chartType: ChartType
    let data: Data
    let format: ExportFormat
    let filename: String
    let metadata: [String: Any]
    
    enum ExportFormat {
        case csv
        case json
        case png
        case pdf
    }
}

struct ReportMetadata {
    let portfolioId: String
    let accountId: String
    let baseCurrency: String
    let reportingCurrency: String
    let dataProvider: String
    let calculationMethod: String
    let disclaimers: [String]
}

// Additional supporting models would be defined here...

// MARK: - Services

protocol AnalyticsService {
    func analyzePerformance(period: PerformancePeriod, benchmark: String) async throws -> PerformanceAnalysisResult
    func getPerformanceRecommendations(analysis: PerformanceAnalysisResult?) async throws -> [PerformanceRecommendation]
    func implementRecommendation(_ recommendationId: String) async throws
    func generateReport(analysis: PerformanceAnalysisResult?, period: PerformancePeriod) async throws -> PerformanceReport
}

protocol PerformanceService {
    func getCurrentPerformance() async throws -> PortfolioPerformance
    func getPerformanceHistory(period: PerformancePeriod, frequency: PerformanceFrequency) async throws -> PerformanceHistory
    func getPositionPerformance(symbol: String, period: PerformancePeriod) async throws -> PositionPerformance
}

protocol ChartService {
    func createPerformanceChart(history: PerformanceHistory, benchmark: String, showBenchmark: Bool, showDrawdown: Bool) async throws -> PerformanceChart
    func createAllocationChart(positions: [PositionPerformance], chartType: ChartType) async throws -> AllocationChart
    func createSectorChart(sectorPerformance: [SectorPerformance], chartType: ChartType) async throws -> AllocationChart
    func exportChart(chartType: ChartType, period: PerformancePeriod) async throws -> ChartExportData
}

// MARK: - Error Types

enum AnalyticsError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case calculationFailed(String)
    case insufficientData
    case benchmarkNotFound(String)
    case exportFailed(String)
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .calculationFailed(let message),
             .benchmarkNotFound(let message),
             .exportFailed(let message):
            return message
        case .insufficientData:
            return "insufficient_data"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load analytics data: \(message)"
        case .calculationFailed(let message):
            return "Analytics calculation failed: \(message)"
        case .insufficientData:
            return "Insufficient data for analytics"
        case .benchmarkNotFound(let benchmark):
            return "Benchmark '\(benchmark)' not found"
        case .exportFailed(let message):
            return "Failed to export data: \(message)"
        }
    }
}