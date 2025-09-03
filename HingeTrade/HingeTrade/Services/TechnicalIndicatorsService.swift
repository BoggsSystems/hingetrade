//
//  TechnicalIndicatorsService.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import Foundation
import SwiftUI

class TechnicalIndicatorsService {
    
    // MARK: - RSI (Relative Strength Index)
    
    func calculateRSI(prices: [Decimal], period: Int = 14) -> [RSIDataPoint] {
        guard prices.count >= period + 1 else { return [] }
        
        var rsiData: [RSIDataPoint] = []
        var gains: [Decimal] = []
        var losses: [Decimal] = []
        
        // Calculate price changes
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        guard gains.count >= period else { return [] }
        
        // Calculate initial average gain and loss
        var avgGain = gains.prefix(period).reduce(0, +) / Decimal(period)
        var avgLoss = losses.prefix(period).reduce(0, +) / Decimal(period)
        
        // Calculate RSI for each point
        for i in period..<gains.count {
            if i > period {
                // Use smoothed averages (Wilder's smoothing)
                avgGain = (avgGain * Decimal(period - 1) + gains[i]) / Decimal(period)
                avgLoss = (avgLoss * Decimal(period - 1) + losses[i]) / Decimal(period)
            }
            
            let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
            let rsi = 100 - (100 / (1 + rs))
            
            rsiData.append(RSIDataPoint(
                index: i,
                value: rsi,
                isOverbought: rsi > 70,
                isOversold: rsi < 30
            ))
        }
        
        return rsiData
    }
    
    // MARK: - MACD (Moving Average Convergence Divergence)
    
    func calculateMACD(prices: [Decimal], fastPeriod: Int = 12, slowPeriod: Int = 26, signalPeriod: Int = 9) -> [MACDDataPoint] {
        guard prices.count >= slowPeriod else { return [] }
        
        let fastEMA = calculateEMA(prices: prices, period: fastPeriod)
        let slowEMA = calculateEMA(prices: prices, period: slowPeriod)
        
        guard fastEMA.count >= slowPeriod && slowEMA.count >= slowPeriod else { return [] }
        
        // Calculate MACD line
        var macdLine: [Decimal] = []
        let startIndex = slowPeriod - 1
        
        for i in startIndex..<min(fastEMA.count, slowEMA.count) {
            macdLine.append(fastEMA[i] - slowEMA[i])
        }
        
        // Calculate signal line (EMA of MACD line)
        let signalLine = calculateEMA(prices: macdLine, period: signalPeriod)
        
        // Calculate histogram
        var macdData: [MACDDataPoint] = []
        let signalStartIndex = signalPeriod - 1
        
        for i in signalStartIndex..<min(macdLine.count, signalLine.count) {
            let histogram = macdLine[i] - signalLine[i]
            
            macdData.append(MACDDataPoint(
                index: i + startIndex,
                macdLine: macdLine[i],
                signalLine: signalLine[i],
                histogram: histogram,
                isBullish: histogram > 0
            ))
        }
        
        return macdData
    }
    
    // MARK: - Bollinger Bands
    
    func calculateBollingerBands(prices: [Decimal], period: Int = 20, standardDeviations: Decimal = 2) -> [BollingerBandDataPoint] {
        guard prices.count >= period else { return [] }
        
        var bandsData: [BollingerBandDataPoint] = []
        
        for i in (period - 1)..<prices.count {
            let subset = Array(prices[(i - period + 1)...i])
            let sma = subset.reduce(0, +) / Decimal(Double(period))
            
            // Calculate standard deviation
            let variance = subset.map { pow(Double(truncating: ($0 - sma) as NSDecimalNumber), 2) }.reduce(0, +) / Double(period)
            let stdDev = Decimal(sqrt(variance))
            
            let upperBand = sma + (standardDeviations * stdDev)
            let lowerBand = sma - (standardDeviations * stdDev)
            
            bandsData.append(BollingerBandDataPoint(
                index: i,
                upperBand: upperBand,
                middleBand: sma,
                lowerBand: lowerBand,
                currentPrice: prices[i],
                bandwidth: ((upperBand - lowerBand) / sma) * 100
            ))
        }
        
        return bandsData
    }
    
    // MARK: - Moving Averages
    
    func calculateSMA(prices: [Decimal], period: Int) -> [Decimal] {
        guard prices.count >= period else { return [] }
        
        var smaValues: [Decimal] = []
        
        for i in (period - 1)..<prices.count {
            let sum = Array(prices[(i - period + 1)...i]).reduce(0, +)
            smaValues.append(sum / Decimal(period))
        }
        
        return smaValues
    }
    
    func calculateEMA(prices: [Decimal], period: Int) -> [Decimal] {
        guard prices.count >= period else { return [] }
        
        var emaValues: [Decimal] = []
        let multiplier = 2.0 / Double(period + 1)
        
        // First EMA is SMA
        let firstSMA = Array(prices.prefix(period)).reduce(0, +) / Decimal(period)
        emaValues.append(firstSMA)
        
        // Calculate subsequent EMAs
        for i in period..<prices.count {
            let currentPrice = prices[i]
            let previousEMA = emaValues.last!
            let ema = (currentPrice * Decimal(multiplier)) + (previousEMA * Decimal(1 - multiplier))
            emaValues.append(ema)
        }
        
        return emaValues
    }
    
    // MARK: - Support and Resistance
    
    func findSupportResistanceLevels(prices: [Decimal], window: Int = 10) -> SupportResistanceLevels {
        guard prices.count >= window * 2 else {
            return SupportResistanceLevels(supportLevels: [], resistanceLevels: [])
        }
        
        var supportLevels: [Decimal] = []
        var resistanceLevels: [Decimal] = []
        
        // Find local minima (support) and maxima (resistance)
        for i in window..<(prices.count - window) {
            let currentPrice = prices[i]
            let leftPrices = Array(prices[(i - window)..<i])
            let rightPrices = Array(prices[(i + 1)...(i + window)])
            
            // Check for local minimum (support)
            if leftPrices.allSatisfy({ $0 >= currentPrice }) && 
               rightPrices.allSatisfy({ $0 >= currentPrice }) {
                supportLevels.append(currentPrice)
            }
            
            // Check for local maximum (resistance)
            if leftPrices.allSatisfy({ $0 <= currentPrice }) && 
               rightPrices.allSatisfy({ $0 <= currentPrice }) {
                resistanceLevels.append(currentPrice)
            }
        }
        
        return SupportResistanceLevels(
            supportLevels: Array(Set(supportLevels)).sorted(),
            resistanceLevels: Array(Set(resistanceLevels)).sorted()
        )
    }
}

// MARK: - Data Models

struct RSIDataPoint {
    let index: Int
    let value: Decimal
    let isOverbought: Bool
    let isOversold: Bool
}

struct MACDDataPoint {
    let index: Int
    let macdLine: Decimal
    let signalLine: Decimal
    let histogram: Decimal
    let isBullish: Bool
}

struct BollingerBandDataPoint {
    let index: Int
    let upperBand: Decimal
    let middleBand: Decimal
    let lowerBand: Decimal
    let currentPrice: Decimal
    let bandwidth: Decimal
    
    var isAboveUpperBand: Bool { currentPrice > upperBand }
    var isBelowLowerBand: Bool { currentPrice < lowerBand }
    var percentB: Decimal { (currentPrice - lowerBand) / (upperBand - lowerBand) }
}

struct SupportResistanceLevels {
    let supportLevels: [Decimal]
    let resistanceLevels: [Decimal]
}

// MARK: - Technical Indicator Types

enum TechnicalIndicator: String, CaseIterable {
    case rsi = "RSI"
    case macd = "MACD"
    case bollingerBands = "BB"
    case sma20 = "SMA20"
    case sma50 = "SMA50"
    case ema12 = "EMA12"
    case ema26 = "EMA26"
    case supportResistance = "S/R"
    
    var displayName: String {
        switch self {
        case .rsi: return "RSI (14)"
        case .macd: return "MACD (12,26,9)"
        case .bollingerBands: return "Bollinger Bands"
        case .sma20: return "SMA (20)"
        case .sma50: return "SMA (50)"
        case .ema12: return "EMA (12)"
        case .ema26: return "EMA (26)"
        case .supportResistance: return "Support/Resistance"
        }
    }
    
    var color: Color {
        switch self {
        case .rsi: return .purple
        case .macd: return .orange
        case .bollingerBands: return .blue
        case .sma20: return .yellow
        case .sma50: return .pink
        case .ema12: return .cyan
        case .ema26: return .mint
        case .supportResistance: return .gray
        }
    }
}