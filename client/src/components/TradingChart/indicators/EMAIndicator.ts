import { BaseIndicator } from './BaseIndicator';
import type { OHLCData } from './types';
import type { IndicatorResult } from './types';

export class EMAIndicator extends BaseIndicator {
  id = 'ema';
  name = 'Exponential Moving Average';
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
    
    const emaValues = this.calculateEMA(sourceData, period);
    const timestamps = data.map(d => d.timestamp);
    
    return {
      datasets: [{
        label: `EMA ${period}`,
        data: this.formatDataPoints(timestamps, emaValues),
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
    // Different colors for different periods, offset from SMA colors
    const colors = [
      'rgb(255, 119, 152)',  // Light Red
      'rgb(255, 179, 84)',   // Light Orange
      'rgb(255, 225, 106)',  // Light Yellow
      'rgb(95, 212, 212)',   // Light Teal
      'rgb(74, 182, 255)',   // Light Blue
      'rgb(173, 122, 255)',  // Light Purple
      'rgb(221, 223, 227)'   // Light Grey
    ];
    
    // Map common periods to specific colors
    switch (period) {
      case 12: return 'rgb(255, 119, 152)';
      case 20: return 'rgb(173, 122, 255)';
      case 26: return 'rgb(74, 182, 255)';
      case 50: return 'rgb(95, 212, 212)';
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