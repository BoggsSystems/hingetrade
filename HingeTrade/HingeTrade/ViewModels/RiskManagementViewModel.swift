//
//  RiskManagementViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class RiskManagementViewModel: ObservableObject {
    // MARK: - Risk Metrics
    @Published var overallRiskStatus: OverallRiskStatus?
    @Published var portfolioBeta: Double?
    @Published var valueAtRisk: Decimal?
    @Published var maxDrawdown: Double?
    @Published var sharpeRatio: Double?
    @Published var portfolioVolatility: Double?
    @Published var concentrationRisk: Double?
    
    // MARK: - Position Analysis
    @Published var positionRisks: [PositionRisk] = []
    @Published var sectorExposure: [SectorExposure] = []
    @Published var correlationMatrix: [[Double]] = []
    
    // MARK: - Risk Alerts
    @Published var activeAlerts: [RiskAlert] = []
    @Published var alertHistory: [RiskAlert] = []
    
    // MARK: - Recommendations
    @Published var recommendedActions: [RecommendedAction] = []
    
    // MARK: - Settings
    @Published var riskProfile: RiskProfile = .moderate
    @Published var customRiskLimits: RiskLimits = .default
    
    // MARK: - State
    @Published var isLoading = false
    @Published var error: RiskManagementError?
    @Published var showingError = false
    
    // Services
    private let riskAnalysisService: RiskAnalysisService
    private let portfolioService: PortfolioService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        riskAnalysisService: RiskAnalysisService = RiskAnalysisService(),
        portfolioService: PortfolioService = PortfolioService()
    ) {
        self.riskAnalysisService = riskAnalysisService
        self.portfolioService = portfolioService
        
        setupBindings()
    }
    
    // MARK: - Data Loading
    
    func loadRiskData() async {
        isLoading = true
        error = nil
        
        do {
            async let portfolioTask = portfolioService.getPortfolioPositions()
            async let riskMetricsTask = riskAnalysisService.calculateRiskMetrics()
            async let alertsTask = riskAnalysisService.getActiveRiskAlerts()
            
            let (portfolio, riskMetrics, alerts) = try await (portfolioTask, riskMetricsTask, alertsTask)
            
            // Update portfolio positions
            updatePositionRisks(portfolio)
            
            // Update risk metrics
            updateRiskMetrics(riskMetrics)
            
            // Update alerts
            activeAlerts = alerts
            
            // Generate recommendations
            generateRecommendations()
            
            // Calculate overall risk status
            calculateOverallRiskStatus()
            
        } catch {
            self.error = RiskManagementError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    private func updatePositionRisks(_ positions: [PortfolioPosition]) {
        positionRisks = positions.map { position in
            let riskLevel = calculatePositionRisk(position)
            return PositionRisk(
                symbol: position.symbol,
                quantity: position.quantity,
                marketValue: position.marketValue,
                portfolioWeight: position.portfolioWeight,
                beta: position.beta ?? 1.0,
                volatility: position.volatility ?? 0.20,
                riskLevel: riskLevel,
                var95: calculateVaR(position),
                correlation: calculateCorrelationRisk(position)
            )
        }
        
        // Calculate sector exposure
        calculateSectorExposure(positions)
    }
    
    private func updateRiskMetrics(_ metrics: RiskMetrics) {
        portfolioBeta = metrics.beta
        valueAtRisk = metrics.valueAtRisk95
        maxDrawdown = metrics.maxDrawdown
        sharpeRatio = metrics.sharpeRatio
        portfolioVolatility = metrics.volatility
        concentrationRisk = metrics.concentrationRisk
    }
    
    private func calculatePositionRisk(_ position: PortfolioPosition) -> RiskLevel {
        let volatilityRisk = (position.volatility ?? 0.20) > 0.30 ? 2 : 1
        let concentrationRisk = position.portfolioWeight > 0.20 ? 2 : position.portfolioWeight > 0.10 ? 1 : 0
        let betaRisk = abs((position.beta ?? 1.0) - 1.0) > 0.5 ? 1 : 0
        
        let totalRisk = volatilityRisk + concentrationRisk + betaRisk
        
        switch totalRisk {
        case 0...1: return .low
        case 2...3: return .medium
        case 4...5: return .high
        default: return .extreme
        }
    }
    
    private func calculateVaR(_ position: PortfolioPosition) -> Decimal {
        let confidence = 1.96 // 95% confidence level
        let volatility = position.volatility ?? 0.20
        return position.marketValue * Decimal(volatility * confidence / sqrt(252)) // Daily VaR
    }
    
    private func calculateCorrelationRisk(_ position: PortfolioPosition) -> Double {
        // Simplified correlation calculation - would be more sophisticated in real implementation
        return 0.3 + Double.random(in: -0.3...0.3)
    }
    
    private func calculateSectorExposure(_ positions: [PortfolioPosition]) {
        var sectorMap: [String: Double] = [:]
        let totalValue = positions.reduce(0) { $0 + Double(truncating: $1.marketValue as NSNumber) }
        
        for position in positions {
            let sector = position.sector ?? "Unknown"
            let weight = Double(truncating: position.marketValue as NSNumber) / totalValue
            sectorMap[sector, default: 0] += weight
        }
        
        sectorExposure = sectorMap.map { sector, weight in
            let riskLevel: RiskLevel = weight > 0.40 ? .high : weight > 0.25 ? .medium : .low
            return SectorExposure(sector: sector, weight: weight, riskLevel: riskLevel)
        }.sorted { $0.weight > $1.weight }
    }
    
    private func generateRecommendations() {
        var actions: [RecommendedAction] = []
        
        // Check concentration risk
        if let concentration = concentrationRisk, concentration > 0.30 {
            actions.append(RecommendedAction(
                id: "diversify",
                title: "Reduce Concentration Risk",
                description: "Consider reducing position sizes in your largest holdings",
                priority: .high,
                category: .diversification
            ))
        }
        
        // Check volatility
        if let volatility = portfolioVolatility, volatility > 0.25 {
            actions.append(RecommendedAction(
                id: "reduce-volatility",
                title: "Lower Portfolio Volatility",
                description: "Add some defensive positions or reduce high-beta stocks",
                priority: .medium,
                category: .volatility
            ))
        }
        
        // Check drawdown
        if let drawdown = maxDrawdown, drawdown > 0.15 {
            actions.append(RecommendedAction(
                id: "drawdown-protection",
                title: "Implement Downside Protection",
                description: "Consider adding stop losses or protective puts",
                priority: .high,
                category: .protection
            ))
        }
        
        // Check Sharpe ratio
        if let sharpe = sharpeRatio, sharpe < 0.5 {
            actions.append(RecommendedAction(
                id: "improve-efficiency",
                title: "Improve Risk-Adjusted Returns",
                description: "Review underperforming positions and consider rebalancing",
                priority: .medium,
                category: .efficiency
            ))
        }
        
        recommendedActions = actions
    }
    
    private func calculateOverallRiskStatus() {
        guard let concentration = concentrationRisk,
              let volatility = portfolioVolatility,
              let drawdown = maxDrawdown else {
            return
        }
        
        // Calculate risk score (0-4 scale)
        var score = 0.0
        
        // Concentration component (0-1)
        score += min(concentration / 0.40, 1.0)
        
        // Volatility component (0-1)
        score += min(volatility / 0.30, 1.0)
        
        // Drawdown component (0-1)
        score += min(drawdown / 0.20, 1.0)
        
        // VaR component (0-1)
        if let var95 = valueAtRisk {
            let varPercent = Double(truncating: var95 as NSNumber) / 100000 // Assuming $100k portfolio
            score += min(varPercent / 0.05, 1.0) // 5% VaR threshold
        }
        
        let level: RiskLevel
        switch score {
        case 0...1: level = .low
        case 1...2: level = .medium
        case 2...3: level = .high
        default: level = .extreme
        }
        
        // Risk utilization (how much of risk budget is used)
        let utilizationPercent = min(score / 4.0, 1.0)
        
        overallRiskStatus = OverallRiskStatus(
            level: level,
            score: score,
            utilizationPercent: utilizationPercent
        )
    }
    
    // MARK: - Actions
    
    func updateRiskProfile(_ profile: RiskProfile) {
        riskProfile = profile
        customRiskLimits = profile.defaultLimits
        
        // Recalculate with new limits
        Task {
            await loadRiskData()
        }
    }
    
    func acknowledgeRiskAlert(_ alertId: String) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            var alert = activeAlerts[index]
            alert.acknowledgedAt = Date()
            activeAlerts[index] = alert
            
            // Move to history
            alertHistory.append(alert)
        }
    }
    
    func implementRecommendation(_ actionId: String) async {
        // In a real implementation, this would trigger specific actions
        // For now, just mark as implemented
        if let index = recommendedActions.firstIndex(where: { $0.id == actionId }) {
            recommendedActions[index].implementedAt = Date()
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

// MARK: - Models

struct OverallRiskStatus {
    let level: RiskLevel
    let score: Double
    let utilizationPercent: Double
}

struct PositionRisk {
    let symbol: String
    let quantity: Int
    let marketValue: Decimal
    let portfolioWeight: Double
    let beta: Double
    let volatility: Double
    let riskLevel: RiskLevel
    let var95: Decimal
    let correlation: Double
}

struct SectorExposure {
    let sector: String
    let weight: Double
    let riskLevel: RiskLevel
}

struct RiskAlert: Identifiable {
    let id: String
    let type: RiskAlertType
    let severity: RiskLevel
    let title: String
    let message: String
    let triggeredAt: Date
    var acknowledgedAt: Date?
    let recommendedAction: String?
    
    enum RiskAlertType {
        case concentrationLimit
        case volatilitySpike
        case drawdownLimit
        case varExceeded
        case correlationRisk
        case liquidityRisk
    }
}

struct RecommendedAction: Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: Priority
    let category: Category
    var implementedAt: Date?
    
    enum Priority {
        case low, medium, high, critical
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    enum Category {
        case diversification
        case volatility
        case protection
        case efficiency
        case liquidity
        case correlation
    }
}

struct RiskMetrics {
    let beta: Double
    let valueAtRisk95: Decimal
    let maxDrawdown: Double
    let sharpeRatio: Double
    let volatility: Double
    let concentrationRisk: Double
    let correlationRisk: Double
}

struct PortfolioPosition {
    let symbol: String
    let quantity: Int
    let marketValue: Decimal
    let portfolioWeight: Double
    let beta: Double?
    let volatility: Double?
    let sector: String?
}

enum RiskProfile: String, CaseIterable {
    case conservative = "Conservative"
    case moderate = "Moderate"
    case aggressive = "Aggressive"
    case custom = "Custom"
    
    var defaultLimits: RiskLimits {
        switch self {
        case .conservative:
            return RiskLimits(
                maxPositionSize: 0.10,
                maxSectorExposure: 0.25,
                maxVolatility: 0.15,
                maxDrawdown: 0.10,
                maxVaR: 0.02
            )
        case .moderate:
            return RiskLimits(
                maxPositionSize: 0.15,
                maxSectorExposure: 0.35,
                maxVolatility: 0.20,
                maxDrawdown: 0.15,
                maxVaR: 0.03
            )
        case .aggressive:
            return RiskLimits(
                maxPositionSize: 0.25,
                maxSectorExposure: 0.50,
                maxVolatility: 0.30,
                maxDrawdown: 0.25,
                maxVaR: 0.05
            )
        case .custom:
            return .default
        }
    }
}

struct RiskLimits {
    let maxPositionSize: Double // As percentage of portfolio
    let maxSectorExposure: Double
    let maxVolatility: Double
    let maxDrawdown: Double
    let maxVaR: Double // As percentage of portfolio
    
    static let `default` = RiskLimits(
        maxPositionSize: 0.15,
        maxSectorExposure: 0.35,
        maxVolatility: 0.20,
        maxDrawdown: 0.15,
        maxVaR: 0.03
    )
}

// MARK: - Services

protocol RiskAnalysisService {
    func calculateRiskMetrics() async throws -> RiskMetrics
    func getActiveRiskAlerts() async throws -> [RiskAlert]
    func calculatePositionRisk(_ position: PortfolioPosition) async throws -> PositionRisk
}

class RiskAnalysisService: RiskAnalysisService {
    func calculateRiskMetrics() async throws -> RiskMetrics {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return RiskMetrics(
            beta: 1.15,
            valueAtRisk95: 2750, // $2,750 daily VaR at 95% confidence
            maxDrawdown: 0.12, // 12% maximum historical drawdown
            sharpeRatio: 0.85,
            volatility: 0.18, // 18% annualized volatility
            concentrationRisk: 0.32, // 32% in top 5 positions
            correlationRisk: 0.65 // Average correlation between positions
        )
    }
    
    func getActiveRiskAlerts() async throws -> [RiskAlert] {
        try await Task.sleep(nanoseconds: 600_000_000)
        
        return [
            RiskAlert(
                id: "alert-1",
                type: .concentrationLimit,
                severity: .medium,
                title: "High Concentration Risk",
                message: "Top 3 positions represent 45% of portfolio",
                triggeredAt: Date().addingTimeInterval(-3600),
                recommendedAction: "Consider reducing position sizes or adding diversification"
            ),
            RiskAlert(
                id: "alert-2",
                type: .volatilitySpike,
                severity: .high,
                title: "Volatility Spike Detected",
                message: "Portfolio volatility increased to 22% (above 20% limit)",
                triggeredAt: Date().addingTimeInterval(-1800),
                recommendedAction: "Review high-volatility positions and consider hedging"
            )
        ]
    }
    
    func calculatePositionRisk(_ position: PortfolioPosition) async throws -> PositionRisk {
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Mock calculation - would be real risk metrics in production
        let riskLevel: RiskLevel = position.portfolioWeight > 0.15 ? .high : .medium
        let var95 = position.marketValue * Decimal(0.05) // 5% VaR estimate
        
        return PositionRisk(
            symbol: position.symbol,
            quantity: position.quantity,
            marketValue: position.marketValue,
            portfolioWeight: position.portfolioWeight,
            beta: position.beta ?? 1.0,
            volatility: position.volatility ?? 0.20,
            riskLevel: riskLevel,
            var95: var95,
            correlation: 0.3 + Double.random(in: -0.2...0.4)
        )
    }
}

protocol PortfolioService {
    func getPortfolioPositions() async throws -> [PortfolioPosition]
}

class PortfolioService: PortfolioService {
    func getPortfolioPositions() async throws -> [PortfolioPosition] {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        return [
            PortfolioPosition(
                symbol: "AAPL",
                quantity: 150,
                marketValue: 26250,
                portfolioWeight: 0.175,
                beta: 1.2,
                volatility: 0.22,
                sector: "Technology"
            ),
            PortfolioPosition(
                symbol: "MSFT",
                quantity: 75,
                marketValue: 22500,
                portfolioWeight: 0.15,
                beta: 0.9,
                volatility: 0.18,
                sector: "Technology"
            ),
            PortfolioPosition(
                symbol: "TSLA",
                quantity: 50,
                marketValue: 15000,
                portfolioWeight: 0.10,
                beta: 2.1,
                volatility: 0.45,
                sector: "Consumer Discretionary"
            ),
            PortfolioPosition(
                symbol: "JPM",
                quantity: 100,
                marketValue: 13500,
                portfolioWeight: 0.09,
                beta: 1.1,
                volatility: 0.25,
                sector: "Financial Services"
            ),
            PortfolioPosition(
                symbol: "JNJ",
                quantity: 80,
                marketValue: 12000,
                portfolioWeight: 0.08,
                beta: 0.7,
                volatility: 0.12,
                sector: "Healthcare"
            )
        ]
    }
}

// MARK: - Error Types

enum RiskManagementError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case calculationFailed(String)
    case insufficientData
    case configurationError(String)
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .calculationFailed(let message),
             .configurationError(let message):
            return message
        case .insufficientData:
            return "insufficient_data"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load risk data: \(message)"
        case .calculationFailed(let message):
            return "Risk calculation failed: \(message)"
        case .insufficientData:
            return "Insufficient data for risk analysis"
        case .configurationError(let message):
            return "Risk configuration error: \(message)"
        }
    }
}

// MARK: - Supporting Views for Alerts and Actions

struct RiskAlertRow: View {
    let alert: RiskAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alertIcon)
                .font(.body)
                .foregroundColor(Color(hex: alert.severity.color))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                if let recommendedAction = alert.recommendedAction {
                    Text(recommendedAction)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(alert.triggeredAt.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: alert.severity.color).opacity(0.1))
        )
    }
    
    private var alertIcon: String {
        switch alert.type {
        case .concentrationLimit: return "target"
        case .volatilitySpike: return "waveform.path.ecg"
        case .drawdownLimit: return "arrow.down.circle"
        case .varExceeded: return "exclamationmark.triangle"
        case .correlationRisk: return "link"
        case .liquidityRisk: return "drop"
        }
    }
}

struct RecommendedActionRow: View {
    let action: RecommendedAction
    let isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: actionIcon)
                .font(.body)
                .foregroundColor(action.priority.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if action.implementedAt != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundColor(.green)
            } else {
                Text(priorityText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(action.priority.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(action.priority.color.opacity(0.2))
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 1 : 0)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var actionIcon: String {
        switch action.category {
        case .diversification: return "chart.pie"
        case .volatility: return "waveform"
        case .protection: return "shield"
        case .efficiency: return "speedometer"
        case .liquidity: return "drop"
        case .correlation: return "link"
        }
    }
    
    private var priorityText: String {
        switch action.priority {
        case .low: return "LOW"
        case .medium: return "MED"
        case .high: return "HIGH"
        case .critical: return "CRITICAL"
        }
    }
}