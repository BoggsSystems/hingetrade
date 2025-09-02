import type { Chart as ChartJS } from 'chart.js';
import type { ChartPoint, CanvasPoint } from './types';

/**
 * Utility functions for converting between chart data coordinates and canvas pixel coordinates
 */

export class CoordinateConverter {
  public chart: ChartJS;
  
  constructor(chart: ChartJS) {
    this.chart = chart;
  }

  /**
   * Convert chart data coordinates (timestamp, price) to canvas pixel coordinates
   */
  chartToCanvas(chartPoint: ChartPoint): CanvasPoint {
    const xScale = this.chart.scales.x;
    const yScale = this.chart.scales.y;

    if (!xScale || !yScale) {
      throw new Error('Chart scales not available');
    }

    return {
      x: xScale.getPixelForValue(chartPoint.x),
      y: yScale.getPixelForValue(chartPoint.y)
    };
  }

  /**
   * Convert canvas pixel coordinates to chart data coordinates (timestamp, price)
   */
  canvasToChart(canvasPoint: CanvasPoint): ChartPoint {
    const xScale = this.chart.scales.x;
    const yScale = this.chart.scales.y;

    if (!xScale || !yScale) {
      throw new Error('Chart scales not available');
    }

    return {
      x: xScale.getValueForPixel(canvasPoint.x) as number,
      y: yScale.getValueForPixel(canvasPoint.y) as number
    };
  }

  /**
   * Get mouse position relative to chart canvas
   */
  getCanvasPosition(event: MouseEvent): CanvasPoint {
    const canvas = this.chart.canvas;
    const rect = canvas.getBoundingClientRect();
    
    return {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top
    };
  }

  /**
   * Check if a canvas point is within the chart area
   */
  isPointInChart(canvasPoint: CanvasPoint): boolean {
    const chartArea = this.chart.chartArea;
    
    return canvasPoint.x >= chartArea.left && 
           canvasPoint.x <= chartArea.right &&
           canvasPoint.y >= chartArea.top && 
           canvasPoint.y <= chartArea.bottom;
  }

  /**
   * Snap canvas point to nearest price level (OHLC)
   */
  snapToPrice(canvasPoint: CanvasPoint, tolerance: number = 5): CanvasPoint {
    const xScale = this.chart.scales.x;
    const yScale = this.chart.scales.y;
    
    if (!xScale || !yScale) return canvasPoint;

    // Find the nearest data point
    const datasets = this.chart.data.datasets;
    if (!datasets || datasets.length === 0) return canvasPoint;

    const mainDataset = datasets[0]; // Assume first dataset is price data
    if (!mainDataset.data || mainDataset.data.length === 0) return canvasPoint;

    let nearestPrice: number | null = null;
    let minDistance = Infinity;

    // Check each data point for the closest price level
    mainDataset.data.forEach((dataPoint: any) => {
      if (!dataPoint || typeof dataPoint !== 'object') return;
      
      // Handle different data formats (OHLC vs simple y value)
      const prices = [];
      if ('o' in dataPoint && 'h' in dataPoint && 'l' in dataPoint && 'c' in dataPoint) {
        // OHLC data
        prices.push(dataPoint.o, dataPoint.h, dataPoint.l, dataPoint.c);
      } else if ('y' in dataPoint) {
        // Simple y value
        prices.push(dataPoint.y);
      }

      prices.forEach(price => {
        if (typeof price === 'number') {
          const pricePixel = yScale.getPixelForValue(price);
          const distance = Math.abs(canvasPoint.y - pricePixel);
          
          if (distance < tolerance && distance < minDistance) {
            minDistance = distance;
            nearestPrice = price;
          }
        }
      });
    });

    if (nearestPrice !== null) {
      return {
        x: canvasPoint.x,
        y: yScale.getPixelForValue(nearestPrice)
      };
    }

    return canvasPoint;
  }

  /**
   * Calculate distance between two canvas points
   */
  calculateDistance(point1: CanvasPoint, point2: CanvasPoint): number {
    const dx = point1.x - point2.x;
    const dy = point1.y - point2.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * Check if a point is near a line (for selection)
   */
  isPointNearLine(point: CanvasPoint, lineStart: CanvasPoint, lineEnd: CanvasPoint, tolerance: number = 5): boolean {
    const dx = lineEnd.x - lineStart.x;
    const dy = lineEnd.y - lineStart.y;
    const length = Math.sqrt(dx * dx + dy * dy);
    
    if (length === 0) {
      const distance = this.calculateDistance(point, lineStart);
      return distance <= tolerance;
    }
    
    const t = Math.max(0, Math.min(1, ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (length * length)));
    const projection = {
      x: lineStart.x + t * dx,
      y: lineStart.y + t * dy
    };
    
    const distance = this.calculateDistance(point, projection);
    return distance <= tolerance;
  }

  /**
   * Check if a point is inside a rectangle
   */
  isPointInRectangle(point: CanvasPoint, rect: { x: number; y: number; width: number; height: number }): boolean {
    return point.x >= rect.x && 
           point.x <= rect.x + rect.width &&
           point.y >= rect.y && 
           point.y <= rect.y + rect.height;
  }

  /**
   * Check if a point is near a horizontal line
   */
  isPointNearHorizontalLine(point: CanvasPoint, y: number, tolerance: number = 5): boolean {
    const chartArea = this.chart.chartArea;
    return Math.abs(point.y - y) <= tolerance && 
           point.x >= chartArea.left && 
           point.x <= chartArea.right;
  }

  /**
   * Check if a point is near a vertical line
   */
  isPointNearVerticalLine(point: CanvasPoint, x: number, tolerance: number = 5): boolean {
    const chartArea = this.chart.chartArea;
    return Math.abs(point.x - x) <= tolerance && 
           point.y >= chartArea.top && 
           point.y <= chartArea.bottom;
  }

  /**
   * Check if a point is near text annotation
   */
  isPointNearText(point: CanvasPoint, textPosition: CanvasPoint, text: string, fontSize: number = 12, _tolerance: number = 5): boolean {
    // Estimate text dimensions (rough approximation)
    const textWidth = text.length * (fontSize * 0.6);
    const textHeight = fontSize + 8; // Include padding
    
    const textBounds = {
      x: textPosition.x - textWidth / 2 - 4,
      y: textPosition.y - textHeight - 4,
      width: textWidth + 8,
      height: textHeight + 8
    };
    
    return this.isPointInRectangle(point, textBounds);
  }
}