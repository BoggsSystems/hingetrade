import { BaseIndicator } from './BaseIndicator';
import type { OHLCData } from './types';
import type { IndicatorResult } from './types';

export class RSIIndicator extends BaseIndicator {
  id = 'rsi';
  name = 'RSI';
  category = 'oscillator' as const;
  defaultParameters = {
    period: 14,
    source: 'close',
    overbought: 70,
    oversold: 30
  };

  calculate(data: OHLCData[], parameters: Record<string, any>): IndicatorResult {
    const { period, source, overbought, oversold } = { ...this.defaultParameters, ...parameters };
    
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
    const rsiValues = this.calculateRSI(sourceData, period);
    
    // Create level lines for overbought/oversold
    const overboughtLine = timestamps.map(() => overbought);
    const oversoldLine = timestamps.map(() => oversold);
    const middleLine = timestamps.map(() => 50);
    
    return {
      datasets: [
        {
          label: `RSI ${period}`,
          data: this.formatDataPoints(timestamps, rsiValues),
          borderColor: 'rgb(153, 102, 255)',
          backgroundColor: 'transparent',
          borderWidth: 2,
          pointRadius: 0,
          tension: 0.1,
          yAxisID: 'rsi',
          type: 'line'
        },
        {
          label: 'Overbought',
          data: this.formatDataPoints(timestamps, overboughtLine),
          borderColor: 'rgba(239, 83, 80, 0.5)',
          backgroundColor: 'transparent',
          borderWidth: 1,
          borderDash: [5, 5],
          pointRadius: 0,
          yAxisID: 'rsi',
          type: 'line'
        },
        {
          label: 'Oversold',
          data: this.formatDataPoints(timestamps, oversoldLine),
          borderColor: 'rgba(38, 166, 154, 0.5)',
          backgroundColor: 'transparent',
          borderWidth: 1,
          borderDash: [5, 5],
          pointRadius: 0,
          yAxisID: 'rsi',
          type: 'line'
        },
        {
          label: 'Midline',
          data: this.formatDataPoints(timestamps, middleLine),
          borderColor: 'rgba(128, 128, 128, 0.3)',
          backgroundColor: 'transparent',
          borderWidth: 1,
          borderDash: [2, 2],
          pointRadius: 0,
          yAxisID: 'rsi',
          type: 'line'
        }
      ],
      scales: {
        rsi: {
          type: 'linear',
          position: 'right',
          display: true,
          min: 0,
          max: 100,
          grid: {
            color: 'rgba(255, 255, 255, 0.1)'
          },
          title: {
            display: true,
            text: 'RSI'
          },
          ticks: {
            stepSize: 20
          }
        }
      }
    };
  }

  private calculateRSI(prices: number[], period: number): (number | null)[] {
    const result: (number | null)[] = [];
    
    if (prices.length < period + 1) {
      return prices.map(() => null);
    }
    
    // Calculate price changes
    const changes = prices.slice(1).map((price, i) => price - prices[i]);
    
    // Separate gains and losses
    const gains = changes.map(change => change > 0 ? change : 0);
    const losses = changes.map(change => change < 0 ? Math.abs(change) : 0);
    
    result.push(null); // First value is always null due to change calculation
    
    for (let i = 0; i < changes.length; i++) {
      if (i < period - 1) {
        result.push(null);
        continue;
      }
      
      let avgGain: number;
      let avgLoss: number;
      
      if (i === period - 1) {
        // Initial calculation - simple average
        avgGain = gains.slice(0, period).reduce((sum, gain) => sum + gain, 0) / period;
        avgLoss = losses.slice(0, period).reduce((sum, loss) => sum + loss, 0) / period;
      } else {
        // Subsequent calculations - exponential smoothing
        const prevAvgGain = this.getPreviousAvgGain(result, i - 1, gains, losses, period);
        const prevAvgLoss = this.getPreviousAvgLoss(result, i - 1, gains, losses, period);
        
        avgGain = ((prevAvgGain * (period - 1)) + gains[i]) / period;
        avgLoss = ((prevAvgLoss * (period - 1)) + losses[i]) / period;
      }
      
      if (avgLoss === 0) {
        result.push(100);
      } else {
        const rs = avgGain / avgLoss;
        const rsi = 100 - (100 / (1 + rs));
        result.push(rsi);
      }
    }
    
    return result;
  }

  private getPreviousAvgGain(_results: (number | null)[], index: number, gains: number[], _losses: number[], period: number): number {
    // Simplified - in a real implementation, we'd store the running averages
    // For now, recalculate from the start
    const startIndex = index - period + 1;
    return gains.slice(startIndex, index + 1).reduce((sum, gain) => sum + gain, 0) / period;
  }

  private getPreviousAvgLoss(_results: (number | null)[], index: number, _gains: number[], losses: number[], period: number): number {
    // Simplified - in a real implementation, we'd store the running averages
    // For now, recalculate from the start
    const startIndex = index - period + 1;
    return losses.slice(startIndex, index + 1).reduce((sum, loss) => sum + loss, 0) / period;
  }

  validateParameters(parameters: Record<string, any>): boolean {
    const { period, overbought, oversold } = parameters;
    return super.validateParameters(parameters) && 
           typeof period === 'number' && period > 0 && period <= 100 &&
           typeof overbought === 'number' && overbought > 50 && overbought <= 100 &&
           typeof oversold === 'number' && oversold >= 0 && oversold < 50 &&
           oversold < overbought;
  }
}