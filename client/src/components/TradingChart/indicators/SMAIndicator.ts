import { BaseIndicator } from './BaseIndicator';
import type { OHLCData } from './types';
import type { IndicatorResult } from './types';

export class SMAIndicator extends BaseIndicator {
  id = 'sma';
  name = 'Simple Moving Average';
  category = 'overlay' as const;
  defaultParameters = {
    period: 20,
    source: 'close'
  };

  calculate(data: OHLCData[], parameters: Record<string, any>): IndicatorResult {
    const { period, source } = { ...this.defaultParameters, ...parameters };
    
    // Extract source data
    const sourceData = data.map(d => {
      switch (source) {
        case 'high': return d.high;
        case 'low': return d.low;
        case 'open': return d.open;
        case 'close':
        default: return d.close;
      }
    });
    
    const smaValues = this.calculateSMA(sourceData, period);
    const timestamps = data.map(d => d.timestamp);
    
    return {
      datasets: [{
        label: `SMA ${period}`,
        data: this.formatDataPoints(timestamps, smaValues),
        borderColor: this.getColorForPeriod(period),
        backgroundColor: 'transparent',
        borderWidth: 2,
        pointRadius: 0,
        tension: 0.1,
        yAxisID: 'y',
        type: 'line'
      }]
    };
  }

  private getColorForPeriod(period: number): string {
    // Different colors for different periods
    const colors = [
      'rgb(255, 99, 132)',   // Red
      'rgb(255, 159, 64)',   // Orange
      'rgb(255, 205, 86)',   // Yellow
      'rgb(75, 192, 192)',   // Teal
      'rgb(54, 162, 235)',   // Blue
      'rgb(153, 102, 255)',  // Purple
      'rgb(201, 203, 207)'   // Grey
    ];
    
    // Map common periods to specific colors
    switch (period) {
      case 20: return 'rgb(255, 99, 132)';
      case 50: return 'rgb(255, 159, 64)';
      case 100: return 'rgb(75, 192, 192)';
      case 200: return 'rgb(153, 102, 255)';
      default: return colors[period % colors.length];
    }
  }

  validateParameters(parameters: Record<string, any>): boolean {
    const { period } = parameters;
    return super.validateParameters(parameters) && 
           typeof period === 'number' && 
           period > 0 && 
           period <= 500;
  }
}