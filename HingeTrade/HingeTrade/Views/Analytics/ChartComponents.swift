//
//  ChartComponents.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

// MARK: - Chart Container

struct ChartContainer: View {
    let chartData: ChartData
    let theme: ChartTheme
    let interaction: ChartInteraction
    let onPointSelected: ((ChartDataPoint) -> Void)?
    
    @State private var selectedPoint: ChartDataPoint?
    @State private var hoveredSeries: String?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Header
            chartHeader
            
            // Main Chart
            chartContent
                .focused($isFocused)
            
            // Chart Legend
            if chartData.hasMultipleSeries {
                chartLegend
            }
            
            // Chart Controls
            chartControls
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: theme.backgroundColor))
                .stroke(Color(hex: theme.gridColor), lineWidth: 1)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var chartHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(chartData.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: theme.textColor))
                
                Spacer()
                
                if let metadata = chartData.metadata {
                    Text("Updated: \(metadata.lastUpdated.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(Color(hex: theme.neutralColor))
                }
            }
            
            if let subtitle = chartData.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: theme.neutralColor))
            }
        }
    }
    
    private var chartContent: some View {
        Group {
            switch chartData.chartType {
            case .line:
                LineChartView(
                    chartData: chartData,
                    theme: theme,
                    selectedPoint: $selectedPoint
                )
            case .area:
                AreaChartView(
                    chartData: chartData,
                    theme: theme,
                    selectedPoint: $selectedPoint
                )
            case .bar:
                BarChartView(
                    chartData: chartData,
                    theme: theme,
                    selectedPoint: $selectedPoint
                )
            case .pie:
                PieChartView(
                    chartData: chartData,
                    theme: theme
                )
            case .donut:
                DonutChartView(
                    chartData: chartData,
                    theme: theme
                )
            default:
                PlaceholderChartView(
                    chartType: chartData.chartType,
                    theme: theme
                )
            }
        }
        .frame(height: 300)
        .onChange(of: selectedPoint) { point in
            if let point = point {
                onPointSelected?(point)
            }
        }
    }
    
    private var chartLegend: some View {
        HStack(spacing: 20) {
            ForEach(chartData.series, id: \.id) { series in
                if series.isVisible {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: series.color))
                            .frame(width: 12, height: 12)
                        
                        Text(series.name)
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.textColor))
                        
                        Text("(\(series.percentChange.formatted(.number.precision(.fractionLength(1))))%)")
                            .font(.caption)
                            .foregroundColor(Color(hex: series.percentChange >= 0 ? theme.positiveColor : theme.negativeColor))
                    }
                    .opacity(hoveredSeries == nil || hoveredSeries == series.name ? 1.0 : 0.5)
                }
            }
            
            Spacer()
        }
    }
    
    private var chartControls: some View {
        HStack(spacing: 12) {
            // Zoom controls would go here
            Spacer()
            
            if let primarySeries = chartData.primarySeries {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Latest: \(primarySeries.latestValue.formatted(.number.precision(.fractionLength(2))))")
                        .font(.caption)
                        .foregroundColor(Color(hex: theme.textColor))
                    
                    Text("Change: \(primarySeries.percentChange.formatted(.number.precision(.fractionLength(1))))%")
                        .font(.caption)
                        .foregroundColor(Color(hex: primarySeries.percentChange >= 0 ? theme.positiveColor : theme.negativeColor))
                }
            }
        }
    }
}

// MARK: - Line Chart

struct LineChartView: View {
    let chartData: ChartData
    let theme: ChartTheme
    @Binding var selectedPoint: ChartDataPoint?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                ChartGridView(
                    chartData: chartData,
                    theme: theme,
                    size: geometry.size
                )
                
                // Line series
                ForEach(chartData.series, id: \.id) { series in
                    if series.isVisible {
                        LineSeriesView(
                            series: series,
                            theme: theme,
                            size: geometry.size,
                            chartData: chartData
                        )
                    }
                }
                
                // Annotations
                ForEach(chartData.annotations, id: \.id) { annotation in
                    if annotation.isVisible {
                        ChartAnnotationView(
                            annotation: annotation,
                            theme: theme,
                            size: geometry.size,
                            chartData: chartData
                        )
                    }
                }
                
                // Selection overlay
                if let selectedPoint = selectedPoint {
                    SelectionOverlayView(
                        selectedPoint: selectedPoint,
                        theme: theme,
                        size: geometry.size,
                        chartData: chartData
                    )
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Handle point selection
                    handlePointSelection(at: value.location)
                }
        )
    }
    
    private func handlePointSelection(at location: CGPoint) {
        // Implementation would find the nearest data point
        // This is a simplified version
        guard let primarySeries = chartData.primarySeries,
              !primarySeries.dataPoints.isEmpty else { return }
        
        // Find closest point (simplified)
        let closestPoint = primarySeries.dataPoints.min { point1, point2 in
            // This would calculate actual distance based on chart coordinates
            abs(point1.value - point2.value) < abs(point1.value - point2.value)
        }
        
        selectedPoint = closestPoint
    }
}

// MARK: - Area Chart

struct AreaChartView: View {
    let chartData: ChartData
    let theme: ChartTheme
    @Binding var selectedPoint: ChartDataPoint?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid
                ChartGridView(
                    chartData: chartData,
                    theme: theme,
                    size: geometry.size
                )
                
                // Area series
                ForEach(chartData.series, id: \.id) { series in
                    if series.isVisible {
                        AreaSeriesView(
                            series: series,
                            theme: theme,
                            size: geometry.size,
                            chartData: chartData
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Bar Chart

struct BarChartView: View {
    let chartData: ChartData
    let theme: ChartTheme
    @Binding var selectedPoint: ChartDataPoint?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ChartGridView(
                    chartData: chartData,
                    theme: theme,
                    size: geometry.size
                )
                
                // Bar series
                ForEach(chartData.series, id: \.id) { series in
                    if series.isVisible {
                        BarSeriesView(
                            series: series,
                            theme: theme,
                            size: geometry.size,
                            chartData: chartData
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Pie Chart

struct PieChartView: View {
    let chartData: ChartData
    let theme: ChartTheme
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
            
            ZStack {
                ForEach(Array(chartData.series.first?.dataPoints.enumerated() ?? []), id: \.offset) { index, dataPoint in
                    PieSliceView(
                        dataPoint: dataPoint,
                        startAngle: calculateStartAngle(for: index),
                        endAngle: calculateEndAngle(for: index),
                        center: center,
                        radius: radius,
                        theme: theme
                    )
                }
            }
        }
    }
    
    private func calculateStartAngle(for index: Int) -> Angle {
        // Calculate based on previous slices
        return .degrees(0) // Simplified
    }
    
    private func calculateEndAngle(for index: Int) -> Angle {
        // Calculate based on data point value
        return .degrees(90) // Simplified
    }
}

// MARK: - Donut Chart

struct DonutChartView: View {
    let chartData: ChartData
    let theme: ChartTheme
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let outerRadius = min(geometry.size.width, geometry.size.height) / 2 - 20
            let innerRadius = outerRadius * 0.6
            
            ZStack {
                // Donut slices
                ForEach(Array(chartData.series.first?.dataPoints.enumerated() ?? []), id: \.offset) { index, dataPoint in
                    DonutSliceView(
                        dataPoint: dataPoint,
                        startAngle: calculateStartAngle(for: index),
                        endAngle: calculateEndAngle(for: index),
                        center: center,
                        outerRadius: outerRadius,
                        innerRadius: innerRadius,
                        theme: theme
                    )
                }
                
                // Center label
                VStack(spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(Color(hex: theme.neutralColor))
                    
                    Text("$125,430")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: theme.textColor))
                }
            }
        }
    }
    
    private func calculateStartAngle(for index: Int) -> Angle {
        return .degrees(0) // Simplified
    }
    
    private func calculateEndAngle(for index: Int) -> Angle {
        return .degrees(90) // Simplified
    }
}

// MARK: - Supporting Chart Views

struct ChartGridView: View {
    let chartData: ChartData
    let theme: ChartTheme
    let size: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Draw horizontal grid lines
            if chartData.yAxis.gridLines {
                drawHorizontalGridLines(context: context, size: size)
            }
            
            // Draw vertical grid lines
            if chartData.xAxis.gridLines {
                drawVerticalGridLines(context: context, size: size)
            }
        }
    }
    
    private func drawHorizontalGridLines(context: GraphicsContext, size: CGSize) {
        let gridColor = Color(hex: theme.gridColor)
        let lineCount = 5
        
        for i in 0...lineCount {
            let y = (size.height / CGFloat(lineCount)) * CGFloat(i)
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                },
                with: .color(gridColor),
                lineWidth: 0.5
            )
        }
    }
    
    private func drawVerticalGridLines(context: GraphicsContext, size: CGSize) {
        let gridColor = Color(hex: theme.gridColor)
        let lineCount = 6
        
        for i in 0...lineCount {
            let x = (size.width / CGFloat(lineCount)) * CGFloat(i)
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                },
                with: .color(gridColor),
                lineWidth: 0.5
            )
        }
    }
}

struct LineSeriesView: View {
    let series: ChartSeries
    let theme: ChartTheme
    let size: CGSize
    let chartData: ChartData
    
    var body: some View {
        Path { path in
            // Create line path from data points
            guard !series.dataPoints.isEmpty else { return }
            
            let points = calculateChartPoints()
            path.move(to: points.first ?? .zero)
            
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(
            Color(hex: series.color),
            style: StrokeStyle(lineWidth: series.lineWidth, lineCap: .round, lineJoin: .round)
        )
    }
    
    private func calculateChartPoints() -> [CGPoint] {
        // Convert data points to chart coordinates
        // This is a simplified version
        return series.dataPoints.enumerated().map { index, dataPoint in
            let x = (size.width / CGFloat(series.dataPoints.count - 1)) * CGFloat(index)
            let y = size.height - (CGFloat(dataPoint.value) / CGFloat(series.maxValue)) * size.height
            return CGPoint(x: x, y: y)
        }
    }
}

struct AreaSeriesView: View {
    let series: ChartSeries
    let theme: ChartTheme
    let size: CGSize
    let chartData: ChartData
    
    var body: some View {
        Path { path in
            guard !series.dataPoints.isEmpty else { return }
            
            let points = calculateChartPoints()
            path.move(to: CGPoint(x: points.first?.x ?? 0, y: size.height))
            
            for point in points {
                path.addLine(to: point)
            }
            
            path.addLine(to: CGPoint(x: points.last?.x ?? size.width, y: size.height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    Color(hex: series.color).opacity(0.3),
                    Color(hex: series.color).opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            LineSeriesView(
                series: series,
                theme: theme,
                size: size,
                chartData: chartData
            )
        )
    }
    
    private func calculateChartPoints() -> [CGPoint] {
        return series.dataPoints.enumerated().map { index, dataPoint in
            let x = (size.width / CGFloat(series.dataPoints.count - 1)) * CGFloat(index)
            let y = size.height - (CGFloat(dataPoint.value) / CGFloat(series.maxValue)) * size.height
            return CGPoint(x: x, y: y)
        }
    }
}

struct BarSeriesView: View {
    let series: ChartSeries
    let theme: ChartTheme
    let size: CGSize
    let chartData: ChartData
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(series.dataPoints.enumerated()), id: \.offset) { index, dataPoint in
                Rectangle()
                    .fill(Color(hex: series.color))
                    .frame(
                        width: (size.width / CGFloat(series.dataPoints.count)) - 2,
                        height: (CGFloat(dataPoint.value) / CGFloat(series.maxValue)) * size.height
                    )
            }
        }
    }
}

struct PieSliceView: View {
    let dataPoint: ChartDataPoint
    let startAngle: Angle
    let endAngle: Angle
    let center: CGPoint
    let radius: CGFloat
    let theme: ChartTheme
    
    var body: some View {
        Path { path in
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
        .fill(Color(hex: getSliceColor()))
    }
    
    private func getSliceColor() -> String {
        // Get color from metadata or use default
        if let metadata = dataPoint.metadata,
           let color = metadata["color"] as? String {
            return color
        }
        return theme.primaryColor
    }
}

struct DonutSliceView: View {
    let dataPoint: ChartDataPoint
    let startAngle: Angle
    let endAngle: Angle
    let center: CGPoint
    let outerRadius: CGFloat
    let innerRadius: CGFloat
    let theme: ChartTheme
    
    var body: some View {
        Path { path in
            path.addArc(
                center: center,
                radius: outerRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: innerRadius,
                startAngle: endAngle,
                endAngle: startAngle,
                clockwise: true
            )
            path.closeSubpath()
        }
        .fill(Color(hex: getSliceColor()))
    }
    
    private func getSliceColor() -> String {
        if let metadata = dataPoint.metadata,
           let color = metadata["color"] as? String {
            return color
        }
        return theme.primaryColor
    }
}

struct ChartAnnotationView: View {
    let annotation: ChartAnnotation
    let theme: ChartTheme
    let size: CGSize
    let chartData: ChartData
    
    var body: some View {
        // Simplified annotation rendering
        Circle()
            .fill(Color(hex: annotation.color))
            .frame(width: 8, height: 8)
            .position(
                x: CGFloat(annotation.position.x),
                y: CGFloat(annotation.position.y)
            )
    }
}

struct SelectionOverlayView: View {
    let selectedPoint: ChartDataPoint
    let theme: ChartTheme
    let size: CGSize
    let chartData: ChartData
    
    var body: some View {
        VStack {
            Text(selectedPoint.displayValue)
                .font(.caption)
                .foregroundColor(Color(hex: theme.textColor))
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: theme.backgroundColor).opacity(0.9))
                        .stroke(Color(hex: theme.gridColor), lineWidth: 1)
                )
        }
        .position(x: size.width / 2, y: 20)
    }
}

struct PlaceholderChartView: View {
    let chartType: ChartType
    let theme: ChartTheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: chartType.systemImage)
                .font(.system(size: 48))
                .foregroundColor(Color(hex: theme.neutralColor))
            
            Text("\(chartType.displayName) - Coming Soon")
                .font(.title3)
                .foregroundColor(Color(hex: theme.textColor))
            
            Text("This chart type will be implemented in a future update")
                .font(.caption)
                .foregroundColor(Color(hex: theme.neutralColor))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: theme.gridColor).opacity(0.1))
                .stroke(Color(hex: theme.gridColor), lineWidth: 1, lineCap: .round, dash: [5, 5])
        )
    }
}