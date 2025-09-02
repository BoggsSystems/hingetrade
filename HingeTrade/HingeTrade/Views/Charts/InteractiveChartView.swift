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