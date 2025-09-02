//
//  RiskAnalysisComponents.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

// MARK: - Risk Analysis Card

struct RiskAnalysisCard: View {
    let riskAssessment: RiskAssessment
    
    var body: some View {
        VStack(spacing: 16) {
            // Overall Risk Score
            HStack {
                Text("Risk Score")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 8) {
                    RiskLevelIndicator(level: riskAssessment.overallRisk)
                    
                    Text(riskAssessment.riskScore.formatted(.number.precision(.fractionLength(1))))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("/4.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Risk Breakdown
            VStack(spacing: 8) {
                RiskFactorRow(title: "Position Size", level: riskAssessment.positionSizeRisk)
                RiskFactorRow(title: "Price Risk", level: riskAssessment.priceRisk)
                RiskFactorRow(title: "Liquidity", level: riskAssessment.liquidityRisk)
                RiskFactorRow(title: "Timing", level: riskAssessment.timeRisk)
            }
            
            // Recommendations
            if !riskAssessment.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ForEach(riskAssessment.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .frame(width: 12)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
}

struct RiskLevelIndicator: View {
    let level: RiskLevel
    
    var body: some View {
        Circle()
            .fill(Color(hex: level.color))
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

struct RiskFactorRow: View {
    let title: String
    let level: RiskLevel
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            HStack(spacing: 6) {
                RiskLevelIndicator(level: level)
                
                Text(level.displayName)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Order Preview Card

struct OrderPreviewCard: View {
    let preview: OrderPreview
    let isFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Order Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preview.formattedSummary)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Estimated Value: \(preview.estimatedValue.formatted(.currency(code: "USD")))")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: preview.orderType.systemImage)
                    .font(.title)
                    .foregroundColor(Color(hex: preview.orderType.riskLevel.color))
            }
            
            // Price Parameters
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                if let stopPrice = preview.stopPrice {
                    OrderParameterItem(title: "Stop Price", value: stopPrice.formatted(.currency(code: "USD")), color: .red)
                }
                
                if let limitPrice = preview.limitPrice {
                    OrderParameterItem(title: "Limit Price", value: limitPrice.formatted(.currency(code: "USD")), color: .blue)
                }
                
                if let takeProfitPrice = preview.takeProfitPrice {
                    OrderParameterItem(title: "Take Profit", value: takeProfitPrice.formatted(.currency(code: "USD")), color: .green)
                }
                
                if let stopLossPrice = preview.stopLossPrice {
                    OrderParameterItem(title: "Stop Loss", value: stopLossPrice.formatted(.currency(code: "USD")), color: .red)
                }
                
                if let trailAmount = preview.trailAmount {
                    OrderParameterItem(title: "Trail Amount", value: trailAmount.formatted(.currency(code: "USD")), color: .orange)
                }
                
                if let trailPercent = preview.trailPercent {
                    OrderParameterItem(title: "Trail %", value: "\(trailPercent.formatted(.number.precision(.fractionLength(1))))%", color: .orange)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Financial Summary
            VStack(spacing: 8) {
                HStack {
                    Text("Estimated Fees")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(preview.estimatedFees.formatted(.currency(code: "USD")))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if let riskAmount = preview.riskAmount {
                    HStack {
                        Text("Risk Amount")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(riskAmount.formatted(.currency(code: "USD")))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
                
                if let riskRewardRatio = preview.riskRewardRatio {
                    HStack {
                        Text("Risk/Reward Ratio")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("1:\(riskRewardRatio.formatted(.number.precision(.fractionLength(2))))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(riskRewardRatio >= 2 ? .green : riskRewardRatio >= 1 ? .orange : .red)
                    }
                }
                
                HStack {
                    Text("Total Cost")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text((preview.estimatedValue + preview.estimatedFees).formatted(.currency(code: "USD")))
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 2 : 0)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct OrderParameterItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Risk Analysis Detail View

struct RiskAnalysisDetailView: View {
    let symbol: String
    let orderConfig: AdvancedOrderConfig?
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: RiskDetailSection?
    
    enum RiskDetailSection: Hashable {
        case close
        case riskFactor(String)
        case recommendation(Int)
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                riskAnalysisHeader
                
                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Risk Overview
                        riskOverviewSection
                        
                        // Detailed Risk Factors
                        detailedRiskFactorsSection
                        
                        // Risk Mitigation Strategies
                        riskMitigationSection
                        
                        // Position Sizing Recommendations
                        positionSizingSection
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 30)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            // Auto-focus close button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .close
            }
        }
    }
    
    // MARK: - Header
    
    private var riskAnalysisHeader: some View {
        HStack {
            FocusableButton("Close", systemImage: "xmark") {
                dismiss()
            }
            .focused($focusedSection, equals: .close)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Risk Analysis")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(symbol)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Placeholder for balance
            Color.clear.frame(width: 120)
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
    
    // MARK: - Content Sections
    
    private var riskOverviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Risk Overview")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Comprehensive analysis of potential risks associated with this advanced order.")
                .font(.body)
                .foregroundColor(.gray)
            
            // Mock risk factors for demonstration
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                RiskFactorCard(
                    title: "Market Risk",
                    level: .medium,
                    description: "Stock price volatility",
                    isFocused: focusedSection == .riskFactor("market")
                )
                .focused($focusedSection, equals: .riskFactor("market"))
                
                RiskFactorCard(
                    title: "Liquidity Risk",
                    level: .low,
                    description: "Trading volume sufficient",
                    isFocused: focusedSection == .riskFactor("liquidity")
                )
                .focused($focusedSection, equals: .riskFactor("liquidity"))
                
                RiskFactorCard(
                    title: "Timing Risk",
                    level: .low,
                    description: "Market hours favorable",
                    isFocused: focusedSection == .riskFactor("timing")
                )
                .focused($focusedSection, equals: .riskFactor("timing"))
                
                RiskFactorCard(
                    title: "Execution Risk",
                    level: .medium,
                    description: "Potential slippage",
                    isFocused: focusedSection == .riskFactor("execution")
                )
                .focused($focusedSection, equals: .riskFactor("execution"))
            }
        }
    }
    
    private var detailedRiskFactorsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Detailed Risk Factors")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                RiskFactorDetail(
                    title: "Price Volatility",
                    description: "Based on historical volatility and current market conditions",
                    impact: "Medium",
                    mitigation: "Use stop loss orders to limit downside"
                )
                
                RiskFactorDetail(
                    title: "Order Complexity",
                    description: "Advanced order types may behave unexpectedly in volatile markets",
                    impact: "Low",
                    mitigation: "Monitor order status closely after placement"
                )
                
                RiskFactorDetail(
                    title: "Market Hours",
                    description: "Order execution during or outside regular trading hours",
                    impact: "Low",
                    mitigation: "Consider time-in-force restrictions"
                )
            }
        }
    }
    
    private var riskMitigationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Risk Mitigation Strategies")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                let strategies = [
                    "Use appropriate position sizing based on account balance",
                    "Set stop losses to limit potential losses",
                    "Diversify across multiple positions and sectors",
                    "Monitor market conditions during order execution",
                    "Review and adjust orders based on changing conditions"
                ]
                
                ForEach(Array(strategies.enumerated()), id: \.offset) { index, strategy in
                    RiskMitigationRow(
                        strategy: strategy,
                        isFocused: focusedSection == .recommendation(index)
                    )
                    .focused($focusedSection, equals: .recommendation(index))
                }
            }
        }
    }
    
    private var positionSizingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Position Sizing Recommendation")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Recommended Position Size")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("$25,000")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Maximum Risk Amount")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("$1,250 (5%)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text("Risk/Reward Ratio")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("1:2.5")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Supporting Components

struct RiskFactorCard: View {
    let title: String
    let level: RiskLevel
    let description: String
    let isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RiskLevelIndicator(level: level)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
            
            Text(level.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: level.color))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: level.color).opacity(0.2))
                )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 2 : 0)
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct RiskFactorDetail: View {
    let title: String
    let description: String
    let impact: String
    let mitigation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(description)
                .font(.body)
                .foregroundColor(.gray)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Impact")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(impact)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Mitigation")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(mitigation)
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct RiskMitigationRow: View {
    let strategy: String
    let isFocused: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.body)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(strategy)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
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
}

#Preview {
    let mockAssessment = RiskAssessment(
        overallRisk: .medium,
        positionSizeRisk: .medium,
        priceRisk: .low,
        liquidityRisk: .low,
        timeRisk: .low,
        recommendations: ["Consider reducing position size", "Add stop loss protection"]
    )
    
    return RiskAnalysisCard(riskAssessment: mockAssessment)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}