//
//  AnalyticsService.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import Foundation

// MARK: - Service Implementations

class DefaultAnalyticsService: AnalyticsServiceProtocol {
    
    func analyzePerformance(period: PerformancePeriod, benchmark: String) async throws -> PerformanceAnalysisResult {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Generate mock performance analysis
        let portfolioPerformance = generateMockPortfolioPerformance()
        let benchmarkComparisons = [generateMockBenchmarkComparison(benchmark: benchmark)]
        let sectorAnalysis = generateMockSectorPerformance()
        let topPerformers = portfolioPerformance.positions.sorted { $0.unrealizedGainLossPercent > $1.unrealizedGainLossPercent }.prefix(5).map { $0 }
        let underPerformers = portfolioPerformance.positions.sorted { $0.unrealizedGainLossPercent < $1.unrealizedGainLossPercent }.prefix(3).map { $0 }
        let riskAnalysis = generateMockRiskAnalysis()
        let recommendations = generateMockRecommendations()
        
        return PerformanceAnalysisResult(
            analysisDate: Date(),
            portfolioPerformance: portfolioPerformance,
            benchmarkComparisons: benchmarkComparisons,
            sectorAnalysis: sectorAnalysis,
            topPerformers: Array(topPerformers),
            underPerformers: Array(underPerformers),
            riskAnalysis: riskAnalysis,
            recommendations: recommendations
        )
    }
    
    func getPerformanceRecommendations(analysis: PerformanceAnalysisResult?) async throws -> [PerformanceRecommendation] {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        return generateMockRecommendations()
    }
    
    func implementRecommendation(_ recommendationId: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Simulate recommendation implementation
        if Bool.random() && Bool.random() { // 25% failure rate
            throw AnalyticsError.calculationFailed("Failed to implement recommendation")
        }
    }
    
    func generateReport(analysis: PerformanceAnalysisResult?, period: PerformancePeriod) async throws -> PerformanceReport {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        guard let analysis = analysis else {
            throw AnalyticsError.insufficientData
        }
        
        let summary = PerformanceSummary(
            totalReturn: analysis.portfolioPerformance.returnMetrics.totalReturn,
            annualizedReturn: analysis.portfolioPerformance.returnMetrics.annualizedReturn,
            sharpeRatio: analysis.portfolioPerformance.returnMetrics.sharpeRatio,
            maxDrawdown: analysis.portfolioPerformance.riskMetrics.maximumDrawdown,
            volatility: analysis.portfolioPerformance.riskMetrics.volatility,
            benchmarkOutperformance: analysis.benchmarkComparisons.first?.outperformance ?? 0,
            winRate: 0.65, // 65% win rate
            bestPosition: analysis.topPerformers.first?.symbol ?? "N/A",
            worstPosition: analysis.underPerformers.first?.symbol ?? "N/A"
        )
        
        return PerformanceReport(
            reportId: UUID().uuidString,
            generatedDate: Date(),
            period: period,
            summary: summary,
            detailedAnalysis: generateMockDetailedAnalysis(),
            charts: [],
            recommendations: analysis.recommendations,
            metadata: ReportMetadata(
                portfolioId: "portfolio-1",
                accountId: "account-1",
                baseCurrency: "USD",
                reportingCurrency: "USD",
                dataProvider: "HingeTrade Analytics",
                calculationMethod: "Time-weighted returns",
                disclaimers: [
                    "Past performance does not guarantee future results",
                    "All investments carry risk of loss"
                ]
            )
        )
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockPortfolioPerformance() -> PortfolioPerformance {
        let positions = [
            generateMockPosition("AAPL", quantity: 150, avgCost: 175.0, currentPrice: 182.50, sector: "Technology"),
            generateMockPosition("MSFT", quantity: 75, avgCost: 300.0, currentPrice: 315.20, sector: "Technology"),
            generateMockPosition("TSLA", quantity: 50, avgCost: 250.0, currentPrice: 245.80, sector: "Consumer Discretionary"),
            generateMockPosition("JPM", quantity: 100, avgCost: 135.0, currentPrice: 142.60, sector: "Financial Services"),
            generateMockPosition("JNJ", quantity: 80, avgCost: 150.0, currentPrice: 155.40, sector: "Healthcare")
        ]
        
        let totalValue = positions.reduce(0) { $0 + $1.marketValue }
        let totalCost = positions.reduce(0) { $0 + $1.totalCost }
        let totalGainLoss = totalValue - totalCost
        let totalGainLossPercent = Double(truncating: (totalGainLoss / totalCost) as NSNumber)
        
        return PortfolioPerformance(
            id: UUID().uuidString,
            portfolioId: "main-portfolio",
            date: Date(),
            totalValue: totalValue,
            totalGainLoss: totalGainLoss,
            totalGainLossPercent: totalGainLossPercent,
            dayChange: Decimal(Double.random(in: -2000...3000)),
            dayChangePercent: Double.random(in: -0.03...0.04),
            positions: positions,
            returnMetrics: generateMockReturnMetrics(),
            riskMetrics: generateMockRiskMetricsForAnalytics(),
            benchmarkComparison: generateMockBenchmarkComparison(benchmark: "SPY")
        )
    }
    
    private func generateMockPosition(_ symbol: String, quantity: Int, avgCost: Double, currentPrice: Double, sector: String) -> PositionPerformance {
        let averageCostDecimal = Decimal(avgCost)
        let currentPriceDecimal = Decimal(currentPrice)
        let totalCost = averageCostDecimal * Decimal(quantity)
        let marketValue = currentPriceDecimal * Decimal(quantity)
        let unrealizedGainLoss = marketValue - totalCost
        let unrealizedGainLossPercent = Double(truncating: (unrealizedGainLoss / totalCost) as NSNumber)
        
        return PositionPerformance(
            id: UUID().uuidString,
            symbol: symbol,
            quantity: quantity,
            averageCost: averageCostDecimal,
            currentPrice: currentPriceDecimal,
            marketValue: marketValue,
            totalCost: totalCost,
            unrealizedGainLoss: unrealizedGainLoss,
            unrealizedGainLossPercent: unrealizedGainLossPercent,
            realizedGainLoss: Decimal(Double.random(in: -500...1500)),
            dividendsReceived: Decimal(Double.random(in: 0...300)),
            sector: sector,
            weight: Double.random(in: 0.05...0.25),
            attribution: generateMockPerformanceAttribution(symbol: symbol)
        )
    }
    
    private func generateMockReturnMetrics() -> ReturnMetrics {
        return ReturnMetrics(
            totalReturn: Double.random(in: -0.05...0.15),
            annualizedReturn: Double.random(in: 0.05...0.18),
            cumulativeReturn: Double.random(in: -0.10...0.25),
            timeWeightedReturn: Double.random(in: 0.08...0.16),
            moneyWeightedReturn: Double.random(in: 0.06...0.14),
            dayReturn: Double.random(in: -0.03...0.04),
            weekReturn: Double.random(in: -0.08...0.10),
            monthReturn: Double.random(in: -0.12...0.15),
            quarterReturn: Double.random(in: -0.18...0.22),
            yearReturn: Double.random(in: -0.25...0.30),
            sinceInceptionReturn: Double.random(in: 0.05...0.35),
            sharpeRatio: Double.random(in: 0.3...1.8),
            sortinoRatio: Double.random(in: 0.4...2.2),
            treynorRatio: Double.random(in: 0.05...0.12),
            informationRatio: Double.random(in: -0.3...0.5),
            calmarRatio: Double.random(in: 0.8...2.5),
            returnVolatility: Double.random(in: 0.12...0.35),
            downSideDeviation: Double.random(in: 0.08...0.25),
            trackingError: Double.random(in: 0.02...0.08)
        )
    }
    
    private func generateMockRiskMetricsForAnalytics() -> RiskMetrics {
        return RiskMetrics(
            beta: Double.random(in: 0.7...1.4),
            alpha: Double.random(in: -0.02...0.05),
            correlationToMarket: Double.random(in: 0.6...0.95),
            volatility: Double.random(in: 0.15...0.30),
            downsideVolatility: Double.random(in: 0.10...0.22),
            valueAtRisk95: Decimal(Double.random(in: 1500...5000)),
            valueAtRisk99: Decimal(Double.random(in: 2500...8000)),
            conditionalVaR95: Decimal(Double.random(in: 2000...6500)),
            maximumDrawdown: Double.random(in: 0.05...0.25),
            drawdownDuration: Int.random(in: 10...180),
            upsideCapture: Double.random(in: 0.85...1.15),
            downsideCapture: Double.random(in: 0.75...1.05)
        )
    }
    
    private func generateMockBenchmarkComparison(benchmark: String) -> BenchmarkComparison {
        let benchmarkReturn = Double.random(in: 0.08...0.12)
        let portfolioReturn = Double.random(in: 0.06...0.16)
        
        return BenchmarkComparison(
            benchmarkSymbol: benchmark,
            benchmarkName: getBenchmarkName(benchmark),
            benchmarkReturn: benchmarkReturn,
            relativePerformance: portfolioReturn - benchmarkReturn,
            outperformance: portfolioReturn - benchmarkReturn,
            trackingError: Double.random(in: 0.02...0.08),
            informationRatio: Double.random(in: -0.5...1.2),
            upCapture: Double.random(in: 0.85...1.15),
            downCapture: Double.random(in: 0.75...1.05),
            correlation: Double.random(in: 0.75...0.95),
            beta: Double.random(in: 0.8...1.3),
            alpha: Double.random(in: -0.02...0.04)
        )
    }
    
    private func generateMockSectorPerformance() -> [SectorPerformance] {
        let sectors = [
            "Technology", "Healthcare", "Financial Services", 
            "Consumer Discretionary", "Industrials", "Communication Services"
        ]
        
        return sectors.map { sector in
            let allocation = Double.random(in: 0.05...0.35)
            
            return SectorPerformance(
                id: UUID().uuidString,
                sectorName: sector,
                allocation: allocation,
                marketValue: Decimal(Double.random(in: 5000...35000)),
                totalReturn: Double.random(in: -0.08...0.18),
                contribution: Double.random(in: -0.02...0.05),
                positions: ["AAPL", "MSFT"], // Simplified
                benchmarkWeight: Double.random(in: 0.08...0.25),
                overUnderWeight: allocation - Double.random(in: 0.08...0.25)
            )
        }
    }
    
    private func generateMockPerformanceAttribution(symbol: String) -> PerformanceAttribution {
        return PerformanceAttribution(
            symbol: symbol,
            totalContribution: Double.random(in: -0.02...0.05),
            allocationEffect: Double.random(in: -0.01...0.02),
            selectionEffect: Double.random(in: -0.02...0.04),
            interactionEffect: Double.random(in: -0.005...0.01),
            sectorContribution: Double.random(in: -0.01...0.03),
            securityContribution: Double.random(in: -0.015...0.025),
            currencyEffect: Double.random(in: -0.002...0.003)
        )
    }
    
    private func generateMockRiskAnalysis() -> RiskAnalysisResult {
        return RiskAnalysisResult(
            overallRiskLevel: [RiskLevel.low, .medium, .high][Int.random(in: 0...2)],
            diversificationScore: Double.random(in: 0.6...0.9),
            concentrationRisk: Double.random(in: 0.15...0.45),
            drawdownAnalysis: DrawdownAnalysis(
                currentDrawdown: Double.random(in: 0...0.08),
                maximumDrawdown: Double.random(in: 0.05...0.25),
                averageDrawdown: Double.random(in: 0.03...0.12),
                drawdownFrequency: Int.random(in: 2...8),
                recoveryTime: Int.random(in: 15...120)
            ),
            volatilityAnalysis: VolatilityAnalysis(
                realizedVolatility: Double.random(in: 0.15...0.30),
                impliedVolatility: Double.random(in: 0.18...0.35),
                volatilityTrend: [VolatilityTrend.increasing, .stable, .decreasing][Int.random(in: 0...2)],
                volatilityRank: Double.random(in: 0.2...0.9)
            )
        )
    }
    
    private func generateMockRecommendations() -> [PerformanceRecommendation] {
        return [
            PerformanceRecommendation(
                type: .diversification,
                priority: .medium,
                title: "Increase Sector Diversification",
                description: "Consider reducing technology allocation from 45% to 35% and adding exposure to defensive sectors",
                impact: "Could reduce portfolio volatility by 2-3%",
                actionItems: [
                    "Trim AAPL position by 25%",
                    "Add healthcare ETF exposure",
                    "Consider utilities allocation"
                ],
                expectedBenefit: "Lower correlation risk and improved risk-adjusted returns"
            ),
            PerformanceRecommendation(
                type: .rebalancing,
                priority: .high,
                title: "Portfolio Rebalancing Required",
                description: "Some positions have drifted significantly from target allocations",
                impact: "Restore target risk profile",
                actionItems: [
                    "Reduce Tesla position (currently 15%, target 10%)",
                    "Increase bond allocation to 20%"
                ],
                expectedBenefit: "Maintain consistent risk exposure"
            ),
            PerformanceRecommendation(
                type: .performanceImprovement,
                priority: .low,
                title: "Consider Tax-Loss Harvesting",
                description: "Some positions showing losses could be harvested for tax benefits",
                impact: "Potential tax savings of $1,500-2,000",
                actionItems: [
                    "Review underperforming positions",
                    "Consider selling at loss before year-end",
                    "Reinvest in similar but not substantially identical securities"
                ],
                expectedBenefit: "Tax efficiency improvement without disrupting strategy"
            )
        ]
    }
    
    private func generateMockDetailedAnalysis() -> DetailedAnalysis {
        return DetailedAnalysis(
            returnAnalysis: ReturnAnalysis(
                periodicReturns: [],
                rollingReturns: [],
                returnDistribution: ReturnDistribution(),
                consistencyMetrics: ConsistencyMetrics()
            ),
            riskAnalysis: DetailedRiskAnalysis(),
            attributionAnalysis: AttributionAnalysis(
                sectorAttribution: [],
                securityAttribution: [],
                styleAttribution: nil,
                currencyAttribution: nil
            ),
            benchmarkAnalysis: DetailedBenchmarkAnalysis()
        )
    }
    
    private func getBenchmarkName(_ symbol: String) -> String {
        switch symbol {
        case "SPY": return "SPDR S&P 500 ETF"
        case "QQQ": return "Invesco QQQ Trust"
        case "VTI": return "Vanguard Total Stock Market ETF"
        case "IWM": return "iShares Russell 2000 ETF"
        default: return symbol
        }
    }
}

class DefaultPerformanceService: PerformanceService {
    
    func getCurrentPerformance() async throws -> PortfolioPerformance {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Use the same mock generation as AnalyticsService
        let analyticsService = DefaultAnalyticsService()
        let analysis = try await analyticsService.analyzePerformance(period: .month1, benchmark: "SPY")
        return analysis.portfolioPerformance
    }
    
    func getPerformanceHistory(period: PerformancePeriod, frequency: PerformanceFrequency) async throws -> PerformanceHistory {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        
        let dataPoints = generateMockPerformanceHistory(period: period, frequency: frequency)
        
        return PerformanceHistory(
            id: UUID().uuidString,
            symbol: nil, // Portfolio-level
            startDate: Calendar.current.date(byAdding: .day, value: -(period.daysBack ?? 365), to: Date()) ?? Date(),
            endDate: Date(),
            frequency: frequency,
            dataPoints: dataPoints
        )
    }
    
    func getPositionPerformance(symbol: String, period: PerformancePeriod) async throws -> PositionPerformance {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        // Generate mock position performance
        return generateMockPositionPerformance(symbol: symbol)
    }
    
    private func generateMockPerformanceHistory(period: PerformancePeriod, frequency: PerformanceFrequency) -> [PerformanceDataPoint] {
        let daysBack = period.daysBack ?? 365
        let pointCount = min(frequency.chartPoints, daysBack)
        let dayInterval = max(1, daysBack / pointCount)
        
        var dataPoints: [PerformanceDataPoint] = []
        var cumulativeReturn = 0.0
        var currentValue = Decimal(100000) // Start at $100k
        
        for i in 0..<pointCount {
            let date = Calendar.current.date(byAdding: .day, value: -(daysBack - (i * dayInterval)), to: Date()) ?? Date()
            let dailyReturn = Double.random(in: -0.03...0.04)
            cumulativeReturn = (1 + cumulativeReturn) * (1 + dailyReturn) - 1
            
            currentValue = currentValue * Decimal(1 + dailyReturn)
            
            let benchmarkReturn = dailyReturn * Double.random(in: 0.8...1.2)
            let benchmarkValue = Decimal(100000) * Decimal(1 + cumulativeReturn * 0.9)
            
            dataPoints.append(PerformanceDataPoint(
                id: UUID().uuidString,
                date: date,
                value: currentValue,
                returnValue: dailyReturn,
                cumulativeReturn: cumulativeReturn,
                benchmarkValue: benchmarkValue,
                benchmarkReturn: benchmarkReturn,
                drawdown: max(0, Double.random(in: -0.15...0)),
                volume: Int.random(in: 1000...50000)
            ))
        }
        
        return dataPoints
    }
    
    private func generateMockPositionPerformance(symbol: String) -> PositionPerformance {
        let quantity = Int.random(in: 25...200)
        let avgCost = Decimal(Double.random(in: 50...300))
        let currentPrice = avgCost * Decimal(Double.random(in: 0.8...1.3))
        let totalCost = avgCost * Decimal(quantity)
        let marketValue = currentPrice * Decimal(quantity)
        
        return PositionPerformance(
            id: UUID().uuidString,
            symbol: symbol,
            quantity: quantity,
            averageCost: avgCost,
            currentPrice: currentPrice,
            marketValue: marketValue,
            totalCost: totalCost,
            unrealizedGainLoss: marketValue - totalCost,
            unrealizedGainLossPercent: Double(truncating: ((marketValue - totalCost) / totalCost) as NSNumber),
            realizedGainLoss: Decimal(Double.random(in: -1000...2000)),
            dividendsReceived: Decimal(Double.random(in: 0...500)),
            sector: ["Technology", "Healthcare", "Financial Services"].randomElement(),
            weight: Double.random(in: 0.05...0.25),
            attribution: nil
        )
    }
}

class DefaultChartService: ChartService {
    
    func createPerformanceChart(history: PerformanceHistory, benchmark: String, showBenchmark: Bool, showDrawdown: Bool) async throws -> PerformanceChart {
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Create portfolio series
        let portfolioDataPoints = history.dataPoints.map { dataPoint in
            ChartDataPoint(
                date: dataPoint.date,
                value: dataPoint.cumulativeReturn * 100, // Convert to percentage
                volume: dataPoint.volume.map(Double.init),
                metadata: nil
            )
        }
        
        let portfolioSeries = ChartSeries(
            name: "Portfolio",
            color: "007AFF",
            lineWidth: 2.0,
            dataPoints: portfolioDataPoints,
            seriesType: .portfolio,
            isPrimary: true,
            isVisible: true,
            fillGradient: ChartGradient(
                startColor: "007AFF",
                endColor: "007AFF",
                opacity: 0.3,
                direction: .vertical
            )
        )
        
        // Create benchmark series if needed
        var benchmarkSeries: ChartSeries?
        if showBenchmark {
            let benchmarkDataPoints = history.dataPoints.compactMap { dataPoint -> ChartDataPoint? in
                guard let benchmarkReturn = dataPoint.benchmarkReturn else { return nil }
                return ChartDataPoint(
                    date: dataPoint.date,
                    value: benchmarkReturn * 100,
                    volume: nil,
                    metadata: ["benchmark": benchmark]
                )
            }
            
            benchmarkSeries = ChartSeries(
                name: benchmark,
                color: "FF9500",
                lineWidth: 1.5,
                dataPoints: benchmarkDataPoints,
                seriesType: .benchmark,
                isPrimary: false,
                isVisible: true,
                fillGradient: nil
            )
        }
        
        // Create drawdown series if needed
        var drawdownSeries: ChartSeries?
        if showDrawdown {
            let drawdownDataPoints = history.dataPoints.map { dataPoint in
                ChartDataPoint(
                    date: dataPoint.date,
                    value: -dataPoint.drawdown * 100, // Negative for drawdown
                    volume: nil,
                    metadata: nil
                )
            }
            
            drawdownSeries = ChartSeries(
                name: "Drawdown",
                color: "FF3B30",
                lineWidth: 1.0,
                dataPoints: drawdownDataPoints,
                seriesType: .indicator,
                isPrimary: false,
                isVisible: true,
                fillGradient: ChartGradient(
                    startColor: "FF3B30",
                    endColor: "FF3B30",
                    opacity: 0.2,
                    direction: .vertical
                )
            )
        }
        
        return PerformanceChart(
            portfolioSeries: portfolioSeries,
            benchmarkSeries: benchmarkSeries,
            drawdownSeries: drawdownSeries,
            timeRange: .month1, // Would be dynamic
            showBenchmark: showBenchmark,
            showDrawdown: showDrawdown,
            annotations: []
        )
    }
    
    func createAllocationChart(positions: [PositionPerformance], chartType: ChartType) async throws -> AllocationChart {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let totalValue = positions.reduce(0) { $0 + $1.marketValue }
        let colors = ["007AFF", "FF9500", "34C759", "FF3B30", "AF52DE", "FF2D92", "5AC8FA", "FFCC00"]
        
        let allocations = positions.enumerated().map { index, position in
            AllocationSlice(
                name: position.symbol,
                value: position.marketValue,
                percentage: Double(truncating: (position.marketValue / totalValue * 100) as NSNumber),
                color: colors[index % colors.count]
            )
        }
        
        return AllocationChart(
            allocations: allocations,
            chartType: chartType,
            showLabels: true,
            showPercentages: true
        )
    }
    
    func createSectorChart(sectorPerformance: [SectorPerformance], chartType: ChartType) async throws -> AllocationChart {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let colors = ["34C759", "007AFF", "FF9500", "AF52DE", "FF3B30", "5AC8FA"]
        
        let allocations = sectorPerformance.enumerated().map { index, sector in
            AllocationSlice(
                name: sector.sectorName,
                value: sector.marketValue,
                percentage: sector.allocation * 100,
                color: colors[index % colors.count]
            )
        }
        
        return AllocationChart(
            allocations: allocations,
            chartType: chartType,
            showLabels: true,
            showPercentages: true
        )
    }
    
    func exportChart(chartType: ChartType, period: PerformancePeriod) async throws -> ChartExportData {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock export data
        let mockData = "Date,Value,Return\n2024-01-01,100000,0.0\n2024-01-02,101000,0.01".data(using: .utf8) ?? Data()
        
        return ChartExportData(
            chartType: chartType,
            data: mockData,
            format: .csv,
            filename: "portfolio_performance_\(period.rawValue).csv",
            metadata: [
                "generated": Date(),
                "period": period.rawValue,
                "chartType": chartType.rawValue
            ]
        )
    }
}

// MARK: - Supporting Mock Models

struct ReturnDistribution {
    let mean: Double = Double.random(in: 0.08...0.12)
    let standardDeviation: Double = Double.random(in: 0.15...0.25)
    let skewness: Double = Double.random(in: -0.5...0.5)
    let kurtosis: Double = Double.random(in: 2.5...4.0)
}

struct ConsistencyMetrics {
    let hitRate: Double = Double.random(in: 0.55...0.75)
    let consistency: Double = Double.random(in: 0.6...0.9)
    let reliability: Double = Double.random(in: 0.65...0.85)
}

struct DetailedRiskAnalysis {
    let var95: Decimal = Decimal(Double.random(in: 2000...5000))
    let var99: Decimal = Decimal(Double.random(in: 3000...7500))
    let expectedShortfall: Decimal = Decimal(Double.random(in: 2500...6000))
}

struct SectorAttribution {
    let sector: String = "Technology"
    let allocation: Double = Double.random(in: 0.15...0.35)
    let contribution: Double = Double.random(in: -0.02...0.05)
}

struct SecurityAttribution {
    let symbol: String = "AAPL"
    let contribution: Double = Double.random(in: -0.01...0.03)
}

struct StyleAttribution {
    let growthContribution: Double = Double.random(in: -0.01...0.03)
    let valueContribution: Double = Double.random(in: -0.02...0.02)
    let momentumContribution: Double = Double.random(in: -0.015...0.025)
}

struct CurrencyAttribution {
    let totalEffect: Double = Double.random(in: -0.005...0.01)
}

struct DetailedBenchmarkAnalysis {
    let correlation: Double = Double.random(in: 0.75...0.95)
    let beta: Double = Double.random(in: 0.8...1.3)
    let alpha: Double = Double.random(in: -0.02...0.04)
}

struct PeriodReturn {
    let period: String
    let returnValue: Double
    let benchmark: Double
    let outperformance: Double
}

struct RollingReturn {
    let period: String
    let returnValue: Double
    let volatility: Double
    let sharpe: Double
}

struct VaRAnalysis {
    let var95Daily: Decimal
    let var99Daily: Decimal
    let conditionalVaR: Decimal
    let expectedShortfall: Decimal
}

struct StressTestResult {
    let scenario: String
    let impact: Double
    let recovery: Int // days
}