//
//  ChartModels.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Foundation

// MARK: - Chart Data Models

struct ChartData: Identifiable {
    let id = UUID().uuidString
    let title: String
    let subtitle: String?
    let timeRange: String
    let chartType: ChartType
    let series: [ChartSeries]
    let xAxis: ChartAxis
    let yAxis: ChartAxis
    let annotations: [ChartAnnotation]
    let metadata: ChartMetadata?
    
    var primarySeries: ChartSeries? {
        return series.first { $0.isPrimary }
    }
    
    var hasMultipleSeries: Bool {
        return series.count > 1
    }
}

struct ChartSeries: Identifiable {
    let id = UUID().uuidString
    let name: String
    let color: String
    let lineWidth: CGFloat
    let dataPoints: [ChartDataPoint]
    let seriesType: SeriesType
    let isPrimary: Bool
    let isVisible: Bool
    let fillGradient: ChartGradient?
    
    var minValue: Double {
        return dataPoints.map(\.value).min() ?? 0
    }
    
    var maxValue: Double {
        return dataPoints.map(\.value).max() ?? 0
    }
    
    var latestValue: Double {
        return dataPoints.last?.value ?? 0
    }
    
    var valueChange: Double {
        guard let first = dataPoints.first?.value,
              let last = dataPoints.last?.value else { return 0 }
        return last - first
    }
    
    var percentChange: Double {
        guard let first = dataPoints.first?.value,
              let last = dataPoints.last?.value,
              first != 0 else { return 0 }
        return ((last - first) / first) * 100
    }
}

struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID().uuidString
    let date: Date
    let value: Double
    let volume: Double?
    let metadata: [String: Any]?
    
    var displayValue: String {
        return value.formatted(.number.precision(.fractionLength(2)))
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.value == rhs.value &&
               lhs.volume == rhs.volume
        // Note: metadata is ignored for equality comparison due to [String: Any] not being Equatable
    }
}

// MARK: - Chart Configuration

enum ChartType: String, CaseIterable {
    case line = "line"
    case area = "area"
    case bar = "bar"
    case candlestick = "candlestick"
    case scatter = "scatter"
    case pie = "pie"
    case donut = "donut"
    case heatmap = "heatmap"
    
    var displayName: String {
        switch self {
        case .line: return "Line Chart"
        case .area: return "Area Chart"
        case .bar: return "Bar Chart"
        case .candlestick: return "Candlestick Chart"
        case .scatter: return "Scatter Plot"
        case .pie: return "Pie Chart"
        case .donut: return "Donut Chart"
        case .heatmap: return "Heat Map"
        }
    }
    
    var systemImage: String {
        switch self {
        case .line: return "chart.xyaxis.line"
        case .area: return "chart.line.uptrend.xyaxis"
        case .bar: return "chart.bar"
        case .candlestick: return "chart.bar.xaxis"
        case .scatter: return "circle.grid.cross"
        case .pie: return "chart.pie"
        case .donut: return "chart.pie"
        case .heatmap: return "grid"
        }
    }
}

enum SeriesType: String, CaseIterable {
    case portfolio = "portfolio"
    case benchmark = "benchmark"
    case position = "position"
    case sector = "sector"
    case indicator = "indicator"
    case volume = "volume"
    
    var displayName: String {
        switch self {
        case .portfolio: return "Portfolio"
        case .benchmark: return "Benchmark"
        case .position: return "Position"
        case .sector: return "Sector"
        case .indicator: return "Indicator"
        case .volume: return "Volume"
        }
    }
}

struct ChartAxis {
    let title: String
    let format: AxisFormat
    let scale: AxisScale
    let gridLines: Bool
    let minValue: Double?
    let maxValue: Double?
    
    enum AxisFormat {
        case number
        case currency
        case percentage
        case date
        case time
        
        func format(_ value: Double) -> String {
            switch self {
            case .number:
                return value.formatted(.number.precision(.fractionLength(2)))
            case .currency:
                return Decimal(value).formatted(.currency(code: "USD"))
            case .percentage:
                return (value / 100).formatted(.percent.precision(.fractionLength(1)))
            case .date:
                return Date(timeIntervalSince1970: value).formatted(.dateTime.month().day())
            case .time:
                return Date(timeIntervalSince1970: value).formatted(.dateTime.hour().minute())
            }
        }
    }
    
    enum AxisScale {
        case linear
        case logarithmic
        case timeSeries
    }
}

struct ChartGradient {
    let startColor: String
    let endColor: String
    let opacity: Double
    let direction: GradientDirection
    
    enum GradientDirection {
        case vertical
        case horizontal
        case radial
    }
}

struct ChartAnnotation: Identifiable {
    let id = UUID().uuidString
    let type: AnnotationType
    let position: ChartPosition
    let text: String
    let color: String
    let isVisible: Bool
    
    enum AnnotationType {
        case point
        case line
        case rectangle
        case text
        case trend
    }
}

struct ChartPosition {
    let x: Double
    let y: Double
    let anchor: AnchorPoint?
    
    enum AnchorPoint {
        case topLeading
        case top
        case topTrailing
        case leading
        case center
        case trailing
        case bottomLeading
        case bottom
        case bottomTrailing
    }
}

struct ChartMetadata {
    let lastUpdated: Date
    let dataSource: String
    let frequency: String
    let aggregation: AggregationType?
    let additionalInfo: [String: Any]
    
    enum AggregationType: String {
        case sum = "sum"
        case average = "average"
        case median = "median"
        case max = "max"
        case min = "min"
    }
}

// MARK: - Specialized Chart Types

struct PerformanceChart: Identifiable {
    let id = UUID().uuidString
    let portfolioSeries: ChartSeries
    let benchmarkSeries: ChartSeries?
    let drawdownSeries: ChartSeries?
    let timeRange: PerformancePeriod
    let showBenchmark: Bool
    let showDrawdown: Bool
    let annotations: [PerformanceAnnotation]
    
    var chartData: ChartData {
        var series = [portfolioSeries]
        
        if showBenchmark, let benchmark = benchmarkSeries {
            series.append(benchmark)
        }
        
        if showDrawdown, let drawdown = drawdownSeries {
            series.append(drawdown)
        }
        
        return ChartData(
            title: "Portfolio Performance",
            subtitle: timeRange.displayName,
            timeRange: timeRange.displayName,
            chartType: .area,
            series: series,
            xAxis: ChartAxis(
                title: "Date",
                format: .date,
                scale: .timeSeries,
                gridLines: true,
                minValue: nil,
                maxValue: nil
            ),
            yAxis: ChartAxis(
                title: "Return %",
                format: .percentage,
                scale: .linear,
                gridLines: true,
                minValue: nil,
                maxValue: nil
            ),
            annotations: annotations.map { $0.chartAnnotation },
            metadata: nil
        )
    }
}

struct AllocationChart: Identifiable {
    let id = UUID().uuidString
    let allocations: [AllocationSlice]
    let chartType: ChartType // .pie or .donut
    let showLabels: Bool
    let showPercentages: Bool
    
    var chartData: ChartData {
        let dataPoints = allocations.map { allocation in
            ChartDataPoint(
                date: Date(),
                value: allocation.percentage,
                volume: nil,
                metadata: [
                    "name": allocation.name,
                    "value": allocation.value,
                    "color": allocation.color
                ]
            )
        }
        
        let series = ChartSeries(
            name: "Allocation",
            color: "007AFF",
            lineWidth: 0,
            dataPoints: dataPoints,
            seriesType: .portfolio,
            isPrimary: true,
            isVisible: true,
            fillGradient: nil
        )
        
        return ChartData(
            title: "Portfolio Allocation",
            subtitle: nil,
            timeRange: "Current",
            chartType: chartType,
            series: [series],
            xAxis: ChartAxis(title: "", format: .number, scale: .linear, gridLines: false, minValue: nil, maxValue: nil),
            yAxis: ChartAxis(title: "", format: .percentage, scale: .linear, gridLines: false, minValue: nil, maxValue: nil),
            annotations: [],
            metadata: nil
        )
    }
}

struct AllocationSlice: Identifiable {
    let id = UUID().uuidString
    let name: String
    let value: Decimal
    let percentage: Double
    let color: String
    
    var displayValue: String {
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
    
    var displayPercentage: String {
        return (percentage / 100).formatted(.percent.precision(.fractionLength(1)))
    }
}

struct PerformanceAnnotation: Identifiable {
    let id = UUID().uuidString
    let date: Date
    let type: AnnotationType
    let title: String
    let description: String
    let color: String
    
    enum AnnotationType {
        case dividend
        case split
        case earnings
        case rebalance
        case buySignal
        case sellSignal
        case alert
        
        var displayName: String {
            switch self {
            case .dividend: return "Dividend"
            case .split: return "Stock Split"
            case .earnings: return "Earnings"
            case .rebalance: return "Rebalance"
            case .buySignal: return "Buy Signal"
            case .sellSignal: return "Sell Signal"
            case .alert: return "Alert"
            }
        }
        
        var systemImage: String {
            switch self {
            case .dividend: return "dollarsign.circle.fill"
            case .split: return "arrow.branch"
            case .earnings: return "chart.bar.fill"
            case .rebalance: return "arrow.clockwise.circle"
            case .buySignal: return "arrow.up.circle.fill"
            case .sellSignal: return "arrow.down.circle.fill"
            case .alert: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var chartAnnotation: ChartAnnotation {
        return ChartAnnotation(
            type: .point,
            position: ChartPosition(
                x: date.timeIntervalSince1970,
                y: 0, // Would be calculated based on chart data
                anchor: .top
            ),
            text: title,
            color: color,
            isVisible: true
        )
    }
}

// MARK: - Chart Interaction

struct ChartInteraction {
    let selectedPoint: ChartDataPoint?
    let hoveredSeries: String?
    let zoomLevel: Double
    let panOffset: CGSize
    let isInteractive: Bool
    
    static let `default` = ChartInteraction(
        selectedPoint: nil,
        hoveredSeries: nil,
        zoomLevel: 1.0,
        panOffset: .zero,
        isInteractive: true
    )
}

// MARK: - Chart Themes

struct ChartTheme {
    let backgroundColor: String
    let gridColor: String
    let textColor: String
    let primaryColor: String
    let secondaryColor: String
    let accentColor: String
    let positiveColor: String
    let negativeColor: String
    let neutralColor: String
    
    static let dark = ChartTheme(
        backgroundColor: "000000",
        gridColor: "333333",
        textColor: "FFFFFF",
        primaryColor: "007AFF",
        secondaryColor: "FF9500",
        accentColor: "34C759",
        positiveColor: "00FF00",
        negativeColor: "FF0000",
        neutralColor: "8E8E93"
    )
    
    static let light = ChartTheme(
        backgroundColor: "FFFFFF",
        gridColor: "E5E5E7",
        textColor: "000000",
        primaryColor: "007AFF",
        secondaryColor: "FF9500",
        accentColor: "34C759",
        positiveColor: "34C759",
        negativeColor: "FF3B30",
        neutralColor: "8E8E93"
    )
}