//
//  InteractiveChartView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct InteractiveChartView: View {
    let symbol: String
    @EnvironmentObject private var chartViewModel: ChartViewModel
    @FocusState private var focusedTimeframe: ChartTimeframe?
    @State private var selectedDataPoint: ChartDataPoint?
    
    var body: some View {
        VStack(spacing: 16) {
            // Timeframe Selector
            timeframeSelectorView
            
            // Chart Content
            chartContentView
            
            // Chart Controls
            chartControlsView
            
            // Technical Indicators Panel
            if chartViewModel.showIndicators {
                technicalIndicatorsPanel
            }
        }
        .onAppear {
            Task {
                await chartViewModel.loadChart(for: symbol)
            }
            
            // Auto-focus default timeframe
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedTimeframe = .oneDay
            }
        }
    }
    
    // MARK: - Timeframe Selector
    
    private var timeframeSelectorView: some View {
        HStack(spacing: 12) {
            ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
                TimeframeButton(
                    timeframe: timeframe,
                    isSelected: chartViewModel.selectedTimeframe == timeframe,
                    isFocused: focusedTimeframe == timeframe
                ) {
                    Task {
                        await chartViewModel.changeTimeframe(to: timeframe)
                    }
                }
                .focused($focusedTimeframe, equals: timeframe)
            }
            
            Spacer()
            
            // Current Price Display
            VStack(alignment: .trailing, spacing: 2) {
                Text(chartViewModel.currentPrice.formatted(.currency(code: "USD")))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: chartViewModel.priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    
                    Text("\(chartViewModel.priceChange.formatted(.currency(code: "USD"))) (\(chartViewModel.priceChangePercent.formatted(.percent.precision(.fractionLength(2)))))")
                        .font(.caption)
                }
                .foregroundColor(chartViewModel.priceChange >= 0 ? .green : .red)
            }
        }
    }
    
    // MARK: - Chart Content
    
    private var chartContentView: some View {
        ZStack {
            if chartViewModel.isLoading {
                LoadingStateView(message: "Loading chart data...")
            } else if chartViewModel.chartData.isEmpty {
                EmptyStateView(
                    title: "No Chart Data",
                    message: "Unable to load chart data for \(symbol)",
                    systemImage: "chart.line.uptrend.xyaxis",
                    actionTitle: "Retry",
                    action: {
                        Task {
                            await chartViewModel.loadChart(for: symbol)
                        }
                    }
                )
            } else {
                // Chart Canvas
                chartCanvasView
            }
        }
        .frame(height: 300)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.02))
        )
    }
    
    private var chartCanvasView: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid Lines
                chartGridView(in: geometry)
                
                // Price Line
                priceLineView(in: geometry)
                
                // Technical Indicators
                if chartViewModel.showIndicators {
                    technicalIndicatorsOverlay(in: geometry)
                }
                
                // Volume Bars (if available)
                if chartViewModel.showVolume {
                    volumeBarsView(in: geometry)
                }
                
                // Crosshair (if data point selected)
                if let selectedPoint = selectedDataPoint {
                    crosshairView(for: selectedPoint, in: geometry)
                }
            }
        }
        .onTapGesture { location in
            handleChartTap(at: location)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleChartDrag(at: value.location)
                }
        )
    }
    
    private func chartGridView(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Horizontal grid lines
            ForEach(0..<5) { i in
                let y = geometry.size.height * CGFloat(i) / 4
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            }
            
            // Vertical grid lines
            ForEach(0..<6) { i in
                let x = geometry.size.width * CGFloat(i) / 5
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            }
        }
    }
    
    private func priceLineView(in geometry: GeometryProxy) -> some View {
        Path { path in
            guard !chartViewModel.chartData.isEmpty else { return }
            
            let minPrice = chartViewModel.minPrice
            let maxPrice = chartViewModel.maxPrice
            let priceRange = maxPrice - minPrice
            
            guard priceRange > 0 else { return }
            
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(chartViewModel.chartData.count - 1)
            
            for (index, dataPoint) in chartViewModel.chartData.enumerated() {
                let x = CGFloat(index) * stepX
                let normalizedPrice = (dataPoint.price - minPrice) / priceRange
                let y = height - (CGFloat(normalizedPrice) * height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(
            LinearGradient(
                colors: chartViewModel.priceChange >= 0 ? [.green, .green.opacity(0.7)] : [.red, .red.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 2
        )
    }
    
    private func volumeBarsView(in geometry: GeometryProxy) -> some View {
        HStack(alignment: .bottom, spacing: 1) {
            ForEach(Array(chartViewModel.chartData.enumerated()), id: \.offset) { index, dataPoint in
                let maxVolume = chartViewModel.maxVolume
                let volumeHeight = maxVolume > 0 ? 
                    CGFloat(dataPoint.volume / maxVolume) * (geometry.size.height * 0.2) : 0
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: volumeHeight)
            }
        }
        .frame(height: geometry.size.height * 0.2)
        .offset(y: geometry.size.height * 0.8)
    }
    
    private func crosshairView(for dataPoint: ChartDataPoint, in geometry: GeometryProxy) -> some View {
        // Implementation for crosshair overlay when user taps/drags
        Rectangle()
            .stroke(Color.green.opacity(0.5), lineWidth: 1)
            .frame(width: 1, height: geometry.size.height)
    }
    
    // MARK: - Chart Controls
    
    private var chartControlsView: some View {
        HStack(spacing: 20) {
            Button(action: {
                chartViewModel.toggleVolume()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                    Text("Volume")
                        .font(.caption)
                }
                .foregroundColor(chartViewModel.showVolume ? .green : .gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(chartViewModel.showVolume ? Color.green.opacity(0.2) : Color.clear)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                chartViewModel.toggleIndicators()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.caption)
                    Text("Indicators")
                        .font(.caption)
                }
                .foregroundColor(chartViewModel.showIndicators ? .green : .gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(chartViewModel.showIndicators ? Color.green.opacity(0.2) : Color.clear)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            if let selectedPoint = selectedDataPoint {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(selectedPoint.price.formatted(.currency(code: "USD")))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(selectedPoint.timestamp.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Interaction Handlers
    
    private func handleChartTap(at location: CGPoint) {
        // Find closest data point to tap location
        // Implementation would calculate which data point is closest
        // and set selectedDataPoint
    }
    
    private func handleChartDrag(at location: CGPoint) {
        // Handle drag for crosshair movement
        handleChartTap(at: location)
    }
    
    // MARK: - Technical Indicators Overlay
    
    private func technicalIndicatorsOverlay(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Moving Averages
            movingAveragesOverlay(in: geometry)
            
            // Bollinger Bands
            bollingerBandsOverlay(in: geometry)
            
            // Support/Resistance Lines
            supportResistanceOverlay(in: geometry)
        }
    }
    
    private func movingAveragesOverlay(in geometry: GeometryProxy) -> some View {
        ZStack {
            // SMA 20
            if chartViewModel.selectedIndicators.contains(.sma20) && !chartViewModel.sma20Data.isEmpty {
                movingAverageLineView(data: chartViewModel.sma20Data, color: .yellow, in: geometry)
            }
            
            // SMA 50
            if chartViewModel.selectedIndicators.contains(.sma50) && !chartViewModel.sma50Data.isEmpty {
                movingAverageLineView(data: chartViewModel.sma50Data, color: .pink, in: geometry)
            }
            
            // EMA 12
            if chartViewModel.selectedIndicators.contains(.ema12) && !chartViewModel.ema12Data.isEmpty {
                movingAverageLineView(data: chartViewModel.ema12Data, color: .cyan, in: geometry)
            }
            
            // EMA 26
            if chartViewModel.selectedIndicators.contains(.ema26) && !chartViewModel.ema26Data.isEmpty {
                movingAverageLineView(data: chartViewModel.ema26Data, color: .mint, in: geometry)
            }
        }
    }
    
    private func movingAverageLineView(data: [Decimal], color: Color, in geometry: GeometryProxy) -> some View {
        Path { path in
            guard !data.isEmpty, !chartViewModel.chartData.isEmpty else { return }
            
            let minPrice = chartViewModel.minPrice
            let maxPrice = chartViewModel.maxPrice
            let priceRange = maxPrice - minPrice
            
            guard priceRange > 0 else { return }
            
            let width = geometry.size.width
            let height = geometry.size.height
            let startIndex = chartViewModel.chartData.count - data.count
            let stepX = width / CGFloat(chartViewModel.chartData.count - 1)
            
            for (index, value) in data.enumerated() {
                let x = CGFloat(index + startIndex) * stepX
                let normalizedPrice = (value - minPrice) / priceRange
                let y = height - (CGFloat(normalizedPrice) * height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(color.opacity(0.8), lineWidth: 1.5)
    }
    
    private func bollingerBandsOverlay(in geometry: GeometryProxy) -> some View {
        ZStack {
            if chartViewModel.selectedIndicators.contains(.bollingerBands) && !chartViewModel.bollingerBandsData.isEmpty {
                // Upper Band
                bollingerBandLineView(
                    data: chartViewModel.bollingerBandsData.map { $0.upperBand },
                    color: .blue.opacity(0.6),
                    in: geometry
                )
                
                // Middle Band (SMA)
                bollingerBandLineView(
                    data: chartViewModel.bollingerBandsData.map { $0.middleBand },
                    color: .blue.opacity(0.8),
                    in: geometry
                )
                
                // Lower Band
                bollingerBandLineView(
                    data: chartViewModel.bollingerBandsData.map { $0.lowerBand },
                    color: .blue.opacity(0.6),
                    in: geometry
                )
                
                // Fill between bands
                bollingerBandsFillView(in: geometry)
            }
        }
    }
    
    private func bollingerBandLineView(data: [Decimal], color: Color, in geometry: GeometryProxy) -> some View {
        movingAverageLineView(data: data, color: color, in: geometry)
    }
    
    private func bollingerBandsFillView(in geometry: GeometryProxy) -> some View {
        Path { path in
            guard !chartViewModel.bollingerBandsData.isEmpty else { return }
            
            let minPrice = chartViewModel.minPrice
            let maxPrice = chartViewModel.maxPrice
            let priceRange = maxPrice - minPrice
            
            guard priceRange > 0 else { return }
            
            let width = geometry.size.width
            let height = geometry.size.height
            let startIndex = chartViewModel.chartData.count - chartViewModel.bollingerBandsData.count
            let stepX = width / CGFloat(chartViewModel.chartData.count - 1)
            
            // Create path for upper band
            for (index, band) in chartViewModel.bollingerBandsData.enumerated() {
                let x = CGFloat(index + startIndex) * stepX
                let normalizedPrice = (band.upperBand - minPrice) / priceRange
                let y = height - (CGFloat(normalizedPrice) * height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            // Add path for lower band (in reverse)
            for (index, band) in chartViewModel.bollingerBandsData.enumerated().reversed() {
                let x = CGFloat(index + startIndex) * stepX
                let normalizedPrice = (band.lowerBand - minPrice) / priceRange
                let y = height - (CGFloat(normalizedPrice) * height)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.closeSubpath()
        }
        .fill(Color.blue.opacity(0.1))
    }
    
    private func supportResistanceOverlay(in geometry: GeometryProxy) -> some View {
        ZStack {
            if chartViewModel.selectedIndicators.contains(.supportResistance) {
                // Support levels
                ForEach(Array(chartViewModel.supportResistanceLevels.supportLevels.enumerated()), id: \.offset) { _, level in
                    supportResistanceLineView(price: level, color: .green, in: geometry)
                }
                
                // Resistance levels
                ForEach(Array(chartViewModel.supportResistanceLevels.resistanceLevels.enumerated()), id: \.offset) { _, level in
                    supportResistanceLineView(price: level, color: .red, in: geometry)
                }
            }
        }
    }
    
    private func supportResistanceLineView(price: Decimal, color: Color, in geometry: GeometryProxy) -> some View {
        let minPrice = chartViewModel.minPrice
        let maxPrice = chartViewModel.maxPrice
        let priceRange = maxPrice - minPrice
        
        guard priceRange > 0 else {
            return Path().stroke(Color.clear, lineWidth: 0)
        }
        
        let normalizedPrice = (price - minPrice) / priceRange
        let y = geometry.size.height - (CGFloat(normalizedPrice) * geometry.size.height)
        
        return Path { path in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
        }
        .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
    }
    
    // MARK: - Technical Indicators Panel
    
    private var technicalIndicatorsPanel: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Technical Indicators")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Indicator Selection
            indicatorSelectionView
            
            // RSI Panel
            if chartViewModel.selectedIndicators.contains(.rsi) && !chartViewModel.rsiData.isEmpty {
                rsiPanelView
            }
            
            // MACD Panel
            if chartViewModel.selectedIndicators.contains(.macd) && !chartViewModel.macdData.isEmpty {
                macdPanelView
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var indicatorSelectionView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
            ForEach(TechnicalIndicator.allCases, id: \.self) { indicator in
                IndicatorToggleButton(
                    indicator: indicator,
                    isSelected: chartViewModel.selectedIndicators.contains(indicator)
                ) {
                    chartViewModel.toggleIndicator(indicator)
                }
            }
        }
    }
    
    private var rsiPanelView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RSI (14)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
                
                Spacer()
                
                if let latestRSI = chartViewModel.rsiData.last {
                    Text(latestRSI.value.formatted(.number.precision(.fractionLength(2))))
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(rsiColor(for: latestRSI))
                }
            }
            
            // Mini RSI Chart
            if !chartViewModel.rsiData.isEmpty {
                rsiMiniChartView
                    .frame(height: 40)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.purple.opacity(0.1))
        )
    }
    
    private var rsiMiniChartView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background levels
                Path { path in
                    // 70 level (overbought)
                    let y70 = geometry.size.height * 0.3
                    path.move(to: CGPoint(x: 0, y: y70))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y70))
                    
                    // 30 level (oversold)
                    let y30 = geometry.size.height * 0.7
                    path.move(to: CGPoint(x: 0, y: y30))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y30))
                }
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                
                // RSI Line
                Path { path in
                    let stepX = geometry.size.width / CGFloat(max(chartViewModel.rsiData.count - 1, 1))
                    
                    for (index, rsiPoint) in chartViewModel.rsiData.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedRSI = 1 - (Double(rsiPoint.value) / 100.0) // Invert for display
                        let y = CGFloat(normalizedRSI) * geometry.size.height
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.purple, lineWidth: 1.5)
            }
        }
    }
    
    private var macdPanelView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MACD (12,26,9)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Spacer()
                
                if let latestMACD = chartViewModel.macdData.last {
                    HStack(spacing: 8) {
                        Text("MACD: \(latestMACD.macdLine.formatted(.number.precision(.fractionLength(4))))")
                            .font(.caption)
                        
                        Text("Signal: \(latestMACD.signalLine.formatted(.number.precision(.fractionLength(4))))")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                }
            }
            
            // Mini MACD Chart
            if !chartViewModel.macdData.isEmpty {
                macdMiniChartView
                    .frame(height: 40)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var macdMiniChartView: some View {
        GeometryReader { geometry in
            let macdValues = chartViewModel.macdData.map { $0.macdLine }
            let signalValues = chartViewModel.macdData.map { $0.signalLine }
            let histogramValues = chartViewModel.macdData.map { $0.histogram }
            
            let minValue = (macdValues + signalValues + histogramValues).min() ?? 0
            let maxValue = (macdValues + signalValues + histogramValues).max() ?? 0
            let range = maxValue - minValue
            
            guard range > 0 else { return AnyView(EmptyView()) }
            
            return AnyView(ZStack {
                // Zero line
                Path { path in
                    let zeroY = geometry.size.height - (CGFloat((-minValue) / range) * geometry.size.height)
                    path.move(to: CGPoint(x: 0, y: zeroY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: zeroY))
                }
                .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                
                // Histogram bars
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(Array(chartViewModel.macdData.enumerated()), id: \.offset) { index, macdPoint in
                        let normalizedValue = (macdPoint.histogram - minValue) / range
                        let barHeight = abs(CGFloat(normalizedValue) * geometry.size.height)
                        
                        Rectangle()
                            .fill(macdPoint.isBullish ? Color.green.opacity(0.6) : Color.red.opacity(0.6))
                            .frame(height: barHeight)
                    }
                }
                
                // MACD Line
                Path { path in
                    let stepX = geometry.size.width / CGFloat(max(macdValues.count - 1, 1))
                    
                    for (index, value) in macdValues.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedValue = (value - minValue) / range
                        let y = geometry.size.height - (CGFloat(normalizedValue) * geometry.size.height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.orange, lineWidth: 1)
                
                // Signal Line
                Path { path in
                    let stepX = geometry.size.width / CGFloat(max(signalValues.count - 1, 1))
                    
                    for (index, value) in signalValues.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedValue = (value - minValue) / range
                        let y = geometry.size.height - (CGFloat(normalizedValue) * geometry.size.height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 1)
            })
        }
    }
    
    // MARK: - Helper Functions
    
    private func rsiColor(for rsiPoint: RSIDataPoint) -> Color {
        if rsiPoint.isOverbought {
            return .red
        } else if rsiPoint.isOversold {
            return .green
        } else {
            return .white
        }
    }
}

// MARK: - IndicatorToggleButton

struct IndicatorToggleButton: View {
    let indicator: TechnicalIndicator
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(indicator.rawValue)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(buttonForegroundColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var buttonForegroundColor: Color {
        isSelected ? .white : indicator.color
    }
    
    private var backgroundColor: Color {
        isSelected ? indicator.color.opacity(0.3) : Color.white.opacity(0.05)
    }
    
    private var borderColor: Color {
        indicator.color.opacity(isSelected ? 0.8 : 0.4)
    }
}

// MARK: - TimeframeButton

struct TimeframeButton: View {
    let timeframe: ChartTimeframe
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeframe.shortName)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(buttonForegroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var buttonForegroundColor: Color {
        if isFocused {
            return .black
        } else if isSelected {
            return .green
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return Color.green.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return .green
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

#Preview {
    InteractiveChartView(symbol: "AAPL")
        .environmentObject(ChartViewModel())
        .padding()
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
}