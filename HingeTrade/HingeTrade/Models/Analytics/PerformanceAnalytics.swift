//
//  PerformanceAnalytics.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import Foundation

// MARK: - Portfolio Performance

struct PortfolioPerformance: Identifiable, Codable {
    let id: String
    let portfolioId: String
    let date: Date
    let totalValue: Decimal
    let totalGainLoss: Decimal
    let totalGainLossPercent: Double
    let dayChange: Decimal
    let dayChangePercent: Double
    let positions: [PositionPerformance]
    
    // Performance metrics
    let returnMetrics: ReturnMetrics
    let riskMetrics: RiskMetrics
    let benchmarkComparison: BenchmarkComparison?
    
    var isPositive: Bool {
        return totalGainLoss >= 0
    }
    
    var dayChangeIsPositive: Bool {
        return dayChange >= 0
    }
}

struct PositionPerformance: Identifiable, Codable {
    let id: String
    let symbol: String
    let quantity: Int
    let averageCost: Decimal
    let currentPrice: Decimal
    let marketValue: Decimal
    let totalCost: Decimal
    let unrealizedGainLoss: Decimal
    let unrealizedGainLossPercent: Double
    let realizedGainLoss: Decimal
    let dividendsReceived: Decimal
    let sector: String?
    let weight: Double // Portfolio weight
    
    // Performance attribution
    let attribution: PerformanceAttribution?
    
    var totalReturn: Decimal {
        return unrealizedGainLoss + realizedGainLoss + dividendsReceived
    }
    
    var totalReturnPercent: Double {
        guard totalCost > 0 else { return 0 }
        return Double(truncating: (totalReturn / totalCost) as NSNumber)
    }
}

// MARK: - Return Metrics

struct ReturnMetrics: Codable {
    let totalReturn: Double
    let annualizedReturn: Double
    let cumulativeReturn: Double
    let timeWeightedReturn: Double
    let moneyWeightedReturn: Double
    
    // Period returns
    let dayReturn: Double
    let weekReturn: Double
    let monthReturn: Double
    let quarterReturn: Double
    let yearReturn: Double
    let sinceInceptionReturn: Double
    
    // Risk-adjusted returns
    let sharpeRatio: Double
    let sortinoRatio: Double
    let treynorRatio: Double
    let informationRatio: Double
    let calmarRatio: Double
    
    // Return consistency
    let returnVolatility: Double
    let downSideDeviation: Double
    let trackingError: Double?
}

struct RiskMetrics: Codable {
    let beta: Double
    let alpha: Double
    let correlationToMarket: Double
    let volatility: Double
    let downsideVolatility: Double
    let valueAtRisk95: Decimal
    let valueAtRisk99: Decimal
    let conditionalVaR95: Decimal
    let maximumDrawdown: Double
    let drawdownDuration: Int // Days
    let upsideCapture: Double
    let downsideCapture: Double
}

// MARK: - Benchmark Comparison

struct BenchmarkComparison: Codable {
    let benchmarkSymbol: String
    let benchmarkName: String
    let benchmarkReturn: Double
    let relativePerformance: Double
    let outperformance: Double
    let trackingError: Double
    let informationRatio: Double
    let upCapture: Double
    let downCapture: Double
    let correlation: Double
    let beta: Double
    let alpha: Double
}

// MARK: - Performance Attribution

struct PerformanceAttribution: Codable {
    let symbol: String
    let totalContribution: Double
    let allocationEffect: Double
    let selectionEffect: Double
    let interactionEffect: Double
    let sectorContribution: Double
    let securityContribution: Double
    let currencyEffect: Double?
    
    var netEffect: Double {
        return allocationEffect + selectionEffect + interactionEffect
    }
}

// MARK: - Historical Performance

struct PerformanceHistory: Identifiable, Codable {
    let id: String
    let symbol: String?
    let startDate: Date
    let endDate: Date
    let frequency: PerformanceFrequency
    let dataPoints: [PerformanceDataPoint]
    
    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

struct PerformanceDataPoint: Identifiable, Codable {
    let id: String
    let date: Date
    let value: Decimal
    let return: Double
    let cumulativeReturn: Double
    let benchmarkValue: Decimal?
    let benchmarkReturn: Double?
    let drawdown: Double
    let volume: Int?
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

enum PerformanceFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
    
    var chartPoints: Int {
        switch self {
        case .daily: return 252 // Trading days in a year
        case .weekly: return 52
        case .monthly: return 24 // 2 years
        case .quarterly: return 20 // 5 years
        case .yearly: return 10
        }
    }
}

// MARK: - Sector Analysis

struct SectorPerformance: Identifiable, Codable {
    let id: String
    let sectorName: String
    let allocation: Double
    let marketValue: Decimal
    let totalReturn: Double
    let contribution: Double
    let positions: [String] // Symbol list
    let benchmarkWeight: Double?
    let overUnderWeight: Double?
    
    var allocationLevel: AllocationLevel {
        switch allocation {
        case 0..<0.05: return .underweight
        case 0.05..<0.15: return .neutral
        case 0.15..<0.30: return .overweight
        default: return .concentrated
        }
    }
}

enum AllocationLevel: String, CaseIterable {
    case underweight = "underweight"
    case neutral = "neutral"
    case overweight = "overweight"
    case concentrated = "concentrated"
    
    var displayName: String {
        switch self {
        case .underweight: return "Underweight"
        case .neutral: return "Neutral"
        case .overweight: return "Overweight"
        case .concentrated: return "Concentrated"
        }
    }
    
    var color: String {
        switch self {
        case .underweight: return "FF8000"
        case .neutral: return "00FF00"
        case .overweight: return "FFFF00"
        case .concentrated: return "FF0000"
        }
    }
}

// MARK: - Performance Periods

enum PerformancePeriod: String, CaseIterable {
    case day1 = "1D"
    case week1 = "1W"
    case month1 = "1M"
    case month3 = "3M"
    case month6 = "6M"
    case year1 = "1Y"
    case year3 = "3Y"
    case year5 = "5Y"
    case inception = "Inception"
    
    var displayName: String {
        switch self {
        case .day1: return "1 Day"
        case .week1: return "1 Week"
        case .month1: return "1 Month"
        case .month3: return "3 Months"
        case .month6: return "6 Months"
        case .year1: return "1 Year"
        case .year3: return "3 Years"
        case .year5: return "5 Years"
        case .inception: return "Since Inception"
        }
    }
    
    var daysBack: Int? {
        switch self {
        case .day1: return 1
        case .week1: return 7
        case .month1: return 30
        case .month3: return 90
        case .month6: return 180
        case .year1: return 365
        case .year3: return 1095
        case .year5: return 1825
        case .inception: return nil
        }
    }
}

// MARK: - Performance Analysis Results

struct PerformanceAnalysisResult: Identifiable {
    let id = UUID().uuidString
    let analysisDate: Date
    let portfolioPerformance: PortfolioPerformance
    let benchmarkComparisons: [BenchmarkComparison]
    let sectorAnalysis: [SectorPerformance]
    let topPerformers: [PositionPerformance]
    let underPerformers: [PositionPerformance]
    let riskAnalysis: RiskAnalysisResult
    let recommendations: [PerformanceRecommendation]
    
    var overallRating: PerformanceRating {
        let returnScore = portfolioPerformance.returnMetrics.annualizedReturn > 0.10 ? 2 : 1
        let riskScore = portfolioPerformance.riskMetrics.sharpeRatio > 1.0 ? 2 : 1
        let benchmarkScore = benchmarkComparisons.first?.outperformance ?? 0 > 0 ? 1 : 0
        
        let totalScore = returnScore + riskScore + benchmarkScore
        
        switch totalScore {
        case 0...1: return .poor
        case 2...3: return .fair
        case 4...5: return .good
        default: return .excellent
        }
    }
}

struct RiskAnalysisResult {
    let overallRiskLevel: RiskLevel
    let diversificationScore: Double
    let concentrationRisk: Double
    let drawdownAnalysis: DrawdownAnalysis
    let volatilityAnalysis: VolatilityAnalysis
}

struct DrawdownAnalysis {
    let currentDrawdown: Double
    let maximumDrawdown: Double
    let averageDrawdown: Double
    let drawdownFrequency: Int
    let recoveryTime: Int? // Days to recover from current drawdown
}

struct VolatilityAnalysis {
    let realizedVolatility: Double
    let impliedVolatility: Double?
    let volatilityTrend: VolatilityTrend
    let volatilityRank: Double // Percentile vs historical
}

enum VolatilityTrend: String, CaseIterable {
    case increasing = "increasing"
    case stable = "stable"
    case decreasing = "decreasing"
    
    var displayName: String { rawValue.capitalized }
    var color: String {
        switch self {
        case .increasing: return "FF0000"
        case .stable: return "FFFF00"
        case .decreasing: return "00FF00"
        }
    }
}

struct PerformanceRecommendation: Identifiable {
    let id = UUID().uuidString
    let type: RecommendationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let impact: String
    let actionItems: [String]
    let expectedBenefit: String?
    
    enum RecommendationType {
        case rebalancing
        case riskReduction
        case diversification
        case costOptimization
        case taxOptimization
        case performanceImprovement
    }
    
    enum RecommendationPriority: String {
        case low = "Low"
        case medium = "Medium" 
        case high = "High"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .low: return "00FF00"
            case .medium: return "FFFF00"
            case .high: return "FF8000"
            case .critical: return "FF0000"
            }
        }
    }
}

enum PerformanceRating: String, CaseIterable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
    
    var color: String {
        switch self {
        case .poor: return "FF0000"
        case .fair: return "FF8000"
        case .good: return "FFFF00"
        case .excellent: return "00FF00"
        }
    }
    
    var systemImage: String {
        switch self {
        case .poor: return "arrow.down.circle.fill"
        case .fair: return "minus.circle.fill"
        case .good: return "arrow.up.circle.fill"
        case .excellent: return "star.circle.fill"
        }
    }
}