//
//  ChartViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class ChartViewModel: ObservableObject {
    @Published var chartData: [ChartDataPoint] = []
    @Published var selectedTimeframe: ChartTimeframe = .oneDay
    @Published var isLoading: Bool = false
    @Published var error: ChartError?
    @Published var showingError: Bool = false
    
    // Chart display options
    @Published var showVolume: Bool = true
    @Published var showIndicators: Bool = false
    @Published var chartType: ChartType = .line
    @Published var selectedIndicators: Set<TechnicalIndicator> = []
    
    // Technical indicator data
    @Published var rsiData: [RSIDataPoint] = []
    @Published var macdData: [MACDDataPoint] = []
    @Published var bollingerBandsData: [BollingerBandDataPoint] = []
    @Published var sma20Data: [Decimal] = []
    @Published var sma50Data: [Decimal] = []
    @Published var ema12Data: [Decimal] = []
    @Published var ema26Data: [Decimal] = []
    @Published var supportResistanceLevels: SupportResistanceLevels = SupportResistanceLevels(supportLevels: [], resistanceLevels: [])
    
    // Current symbol
    @Published var currentSymbol: String = ""
    
    // Price information
    @Published var currentPrice: Decimal = 0.0
    @Published var priceChange: Decimal = 0.0
    @Published var priceChangePercent: Double = 0.0
    
    private let marketDataService: MarketDataService
    private let webSocketService: WebSocketService
    private let technicalIndicatorsService: TechnicalIndicatorsService
    private var cancellables = Set<AnyCancellable>()
    
    init(marketDataService: MarketDataService = MarketDataService(), webSocketService: WebSocketService = WebSocketService(), technicalIndicatorsService: TechnicalIndicatorsService = TechnicalIndicatorsService()) {
        self.marketDataService = marketDataService
        self.webSocketService = webSocketService
        self.technicalIndicatorsService = technicalIndicatorsService
        setupRealTimeUpdates()
        setupErrorHandling()
    }
    
    // MARK: - Data Loading
    
    func loadChart(for symbol: String) async {
        currentSymbol = symbol
        isLoading = true
        error = nil
        
        do {
            let bars = try await marketDataService.getBars(
                symbol: symbol,
                timeframe: selectedTimeframe.alpacaTimeframe,
                limit: selectedTimeframe.defaultLimit
            )
            
            self.chartData = bars.map { bar in
                ChartDataPoint(
                    timestamp: bar.timestamp,
                    price: bar.close,
                    volume: bar.volume,
                    open: bar.open,
                    high: bar.high,
                    low: bar.low,
                    close: bar.close
                )
            }
            
            updatePriceInformation()
            
            // Calculate technical indicators if enabled
            if showIndicators {
                calculateTechnicalIndicators()
            }
            
        } catch {
            self.error = ChartError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    func changeTimeframe(to timeframe: ChartTimeframe) async {
        selectedTimeframe = timeframe
        await loadChart(for: currentSymbol)
    }
    
    private func updatePriceInformation() {
        guard !chartData.isEmpty else { return }
        
        let latestPoint = chartData.last!
        let firstPoint = chartData.first!
        
        currentPrice = latestPoint.close
        priceChange = latestPoint.close - firstPoint.open
        priceChangePercent = firstPoint.open > 0 ? Double(priceChange / firstPoint.open) : 0.0
    }
    
    // MARK: - Real-Time Updates
    
    private func setupRealTimeUpdates() {
        webSocketService.barUpdates
            .filter { [weak self] bar in
                bar.symbol == self?.currentSymbol
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bar in
                self?.handleBarUpdate(bar)
            }
            .store(in: &cancellables)
        
        webSocketService.quoteUpdates
            .filter { [weak self] quote in
                quote.symbol == self?.currentSymbol
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quote in
                self?.handleQuoteUpdate(quote)
            }
            .store(in: &cancellables)
    }
    
    private func handleBarUpdate(_ bar: Bar) {
        let newDataPoint = ChartDataPoint(
            timestamp: bar.timestamp,
            price: bar.close,
            volume: bar.volume,
            open: bar.open,
            high: bar.high,
            low: bar.low,
            close: bar.close
        )
        
        // Update the latest data point or add new one
        if let lastIndex = chartData.indices.last,
           chartData[lastIndex].timestamp == bar.timestamp {
            chartData[lastIndex] = newDataPoint
        } else {
            chartData.append(newDataPoint)
            
            // Keep only the required number of data points
            let maxPoints = selectedTimeframe.defaultLimit
            if chartData.count > maxPoints {
                chartData.removeFirst(chartData.count - maxPoints)
            }
        }
        
        updatePriceInformation()
    }
    
    private func handleQuoteUpdate(_ quote: Quote) {
        currentPrice = quote.bidPrice
        
        // Update the latest data point with real-time price
        if var lastPoint = chartData.last {
            lastPoint.price = quote.bidPrice
            lastPoint.close = quote.bidPrice
            chartData[chartData.count - 1] = lastPoint
        }
        
        updatePriceInformation()
    }
    
    // MARK: - Chart Controls
    
    func toggleVolume() {
        showVolume.toggle()
    }
    
    func toggleIndicators() {
        showIndicators.toggle()
        if showIndicators {
            calculateTechnicalIndicators()
        } else {
            clearTechnicalIndicators()
        }
    }
    
    func toggleIndicator(_ indicator: TechnicalIndicator) {
        if selectedIndicators.contains(indicator) {
            selectedIndicators.remove(indicator)
        } else {
            selectedIndicators.insert(indicator)
        }
        
        if showIndicators {
            calculateTechnicalIndicators()
        }
    }
    
    func changeChartType(to type: ChartType) {
        chartType = type
    }
    
    // MARK: - Computed Properties
    
    var minPrice: Decimal {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map { $0.low }.min() ?? 0
    }
    
    var maxPrice: Decimal {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map { $0.high }.max() ?? 0
    }
    
    var maxVolume: Decimal {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map { $0.volume }.max() ?? 0
    }
    
    var priceRange: Decimal {
        maxPrice - minPrice
    }
    
    // MARK: - Technical Indicators
    
    private func calculateTechnicalIndicators() {
        guard !chartData.isEmpty else { return }
        
        let prices = chartData.map { $0.close }
        
        // Calculate RSI
        if selectedIndicators.contains(.rsi) {
            rsiData = technicalIndicatorsService.calculateRSI(prices: prices)
        }
        
        // Calculate MACD
        if selectedIndicators.contains(.macd) {
            macdData = technicalIndicatorsService.calculateMACD(prices: prices)
        }
        
        // Calculate Bollinger Bands
        if selectedIndicators.contains(.bollingerBands) {
            bollingerBandsData = technicalIndicatorsService.calculateBollingerBands(prices: prices)
        }
        
        // Calculate Moving Averages
        if selectedIndicators.contains(.sma20) {
            sma20Data = technicalIndicatorsService.calculateSMA(prices: prices, period: 20)
        }
        
        if selectedIndicators.contains(.sma50) {
            sma50Data = technicalIndicatorsService.calculateSMA(prices: prices, period: 50)
        }
        
        if selectedIndicators.contains(.ema12) {
            ema12Data = technicalIndicatorsService.calculateEMA(prices: prices, period: 12)
        }
        
        if selectedIndicators.contains(.ema26) {
            ema26Data = technicalIndicatorsService.calculateEMA(prices: prices, period: 26)
        }
        
        // Calculate Support/Resistance
        if selectedIndicators.contains(.supportResistance) {
            supportResistanceLevels = technicalIndicatorsService.findSupportResistanceLevels(prices: prices)
        }
    }
    
    private func clearTechnicalIndicators() {
        rsiData = []
        macdData = []
        bollingerBandsData = []
        sma20Data = []
        sma50Data = []
        ema12Data = []
        ema26Data = []
        supportResistanceLevels = SupportResistanceLevels(supportLevels: [], resistanceLevels: [])
    }
    
    func calculateMovingAverage(period: Int) -> [Decimal] {
        guard chartData.count >= period else { return [] }
        let prices = chartData.map { $0.close }
        return technicalIndicatorsService.calculateSMA(prices: prices, period: period)
    }
    
    func calculateRSI(period: Int = 14) -> [RSIDataPoint] {
        guard chartData.count >= period else { return [] }
        let prices = chartData.map { $0.close }
        return technicalIndicatorsService.calculateRSI(prices: prices, period: period)
    }
    
    // MARK: - Error Handling
    
    private func setupErrorHandling() {
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

// MARK: - Supporting Types

struct ChartDataPoint {
    let timestamp: Date
    var price: Decimal
    let volume: Decimal
    let open: Decimal
    let high: Decimal
    let low: Decimal
    var close: Decimal
}

enum ChartTimeframe: String, CaseIterable {
    case oneMinute = "1Min"
    case fiveMinutes = "5Min"
    case fifteenMinutes = "15Min"
    case thirtyMinutes = "30Min"
    case oneHour = "1Hour"
    case oneDay = "1Day"
    case oneWeek = "1Week"
    case oneMonth = "1Month"
    
    var shortName: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .oneHour: return "1h"
        case .oneDay: return "1d"
        case .oneWeek: return "1w"
        case .oneMonth: return "1M"
        }
    }
    
    var alpacaTimeframe: String {
        switch self {
        case .oneMinute: return "1Min"
        case .fiveMinutes: return "5Min"
        case .fifteenMinutes: return "15Min"
        case .thirtyMinutes: return "30Min"
        case .oneHour: return "1Hour"
        case .oneDay: return "1Day"
        case .oneWeek: return "1Week"
        case .oneMonth: return "1Month"
        }
    }
    
    var defaultLimit: Int {
        switch self {
        case .oneMinute: return 60
        case .fiveMinutes: return 75
        case .fifteenMinutes: return 96
        case .thirtyMinutes: return 48
        case .oneHour: return 24
        case .oneDay: return 252
        case .oneWeek: return 52
        case .oneMonth: return 12
        }
    }
}

enum ChartType {
    case line
    case candlestick
    case bar
    case area
}

// MARK: - ChartError

enum ChartError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case noData(String)
    case invalidSymbol(String)
    case networkError(String)
    case rateLimited
    case unknown(String)
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .noData(let message),
             .invalidSymbol(let message),
             .networkError(let message),
             .unknown(let message):
            return message
        case .rateLimited:
            return "rate_limited"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load chart data: \(message)"
        case .noData(let symbol):
            return "No chart data available for \(symbol)"
        case .invalidSymbol(let symbol):
            return "Invalid symbol: \(symbol)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadingFailed, .networkError:
            return "Please check your internet connection and try again."
        case .noData:
            return "Try selecting a different timeframe or symbol."
        case .invalidSymbol:
            return "Please check the symbol and try again."
        case .rateLimited:
            return "Please wait a moment before making more requests."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}