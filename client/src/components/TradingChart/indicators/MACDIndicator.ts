import { BaseIndicator } from './BaseIndicator';
import type { OHLCData } from './types';
import type { IndicatorResult } from './types';

export class MACDIndicator extends BaseIndicator {
  id = 'macd';
  name = 'MACD';
  category = 'oscillator' as const;
  defaultParameters = {
    fastPeriod: 12,
    slowPeriod: 26,
    signalPeriod: 9,
    source: 'close'
  };

  calculate(data: OHLCData[], parameters: Record<string, any>): IndicatorResult {
    const { fastPeriod, slowPeriod, signalPeriod, source } = { ...this.defaultParameters, ...parameters };
    
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
    
    const timestamps = data.map(d => d.timestamp);
    
    // Calculate fast and slow EMA
    const fastEMA = this.calculateEMA(sourceData, fastPeriod);
    const slowEMA = this.calculateEMA(sourceData, slowPeriod);
    
    // Calculate MACD line (fast EMA - slow EMA)
    const macdLine = sourceData.map((_, i) => {
      if (fastEMA[i] === null || slowEMA[i] === null) return null;
      return (fastEMA[i] as number) - (slowEMA[i] as number);
    });
    
    // Calculate signal line (EMA of MACD line)
    const validMacdValues = macdLine.filter(val => val !== null) as number[];
    const macdStartIndex = macdLine.findIndex(val => val !== null);
    
    let signalLine: (number | null)[] = new Array(macdStartIndex).fill(null);
    if (validMacdValues.length > 0) {
      const signalEMA = this.calculateEMA(validMacdValues, signalPeriod);
      signalLine = signalLine.concat(signalEMA);
    }
    
    // Calculate histogram (MACD - Signal)
    const histogram = macdLine.map((macd, i) => {
      if (macd === null || signalLine[i] === null) return null;
      return macd - (signalLine[i] as number);
    });
    
    return {
      datasets: [
        {
          label: 'MACD',
          data: this.formatDataPoints(timestamps, macdLine),
          borderColor: 'rgb(54, 162, 235)',
          backgroundColor: 'transparent',
          borderWidth: 2,
          pointRadius: 0,
          tension: 0.1,
          yAxisID: 'macd',
          type: 'line'
        },
        {
          label: 'Signal',
          data: this.formatDataPoints(timestamps, signalLine),
          borderColor: 'rgb(255, 99, 132)',
          backgroundColor: 'transparent',
          borderWidth: 2,
          pointRadius: 0,
          tension: 0.1,
          yAxisID: 'macd',
          type: 'line'
        },
        {
          label: 'Histogram',
          data: this.formatDataPoints(timestamps, histogram),
          backgroundColor: histogram.map(val => 
            val === null ? 'rgba(128, 128, 128, 0.6)' :
            val >= 0 ? 'rgba(38, 166, 154, 0.6)' : 'rgba(239, 83, 80, 0.6)'
          ),
          borderColor: histogram.map(val => 
            val === null ? 'rgba(128, 128, 128, 0.8)' :
            val >= 0 ? 'rgba(38, 166, 154, 0.8)' : 'rgba(239, 83, 80, 0.8)'
          ),
          borderWidth: 1,
          yAxisID: 'macd',
          type: 'bar'
        }
      ],
      scales: {
        macd: {
          type: 'linear',
          position: 'right',
          display: true,
          grid: {
            color: 'rgba(255, 255, 255, 0.1)'
          },
          title: {
            display: true,
            text: 'MACD'
          }
        }
      }
    };
  }

  validateParameters(parameters: Record<string, any>): boolean {
    const { fastPeriod, slowPeriod, signalPeriod } = parameters;
    return super.validateParameters(parameters) && 
           typeof fastPeriod === 'number' && fastPeriod > 0 &&
           typeof slowPeriod === 'number' && slowPeriod > fastPeriod &&
           typeof signalPeriod === 'number' && signalPeriod > 0;
  }
}