import { BaseIndicator } from '../base';
import { OHLCData, IndicatorType } from '../../types/indicator';

export class RSI extends BaseIndicator {
  id = 'rsi';
  name = 'Relative Strength Index';
  type: IndicatorType = 'oscillator';
  defaultParams = {
    period: 14,
    source: 'close',
    overbought: 70,
    oversold: 30,
    color: '#9c27b0'
  };

  calculate(data: OHLCData[], params = this.defaultParams): number[] {
    const { period, source } = { ...this.defaultParams, ...params };
    const prices = this.extractPrices(data, source);
    
    if (prices.length < period + 1) {
      return [];
    }

    const rsi: number[] = [];
    const gains: number[] = [];
    const losses: number[] = [];
    
    // Calculate price changes
    for (let i = 1; i < prices.length; i++) {
      const change = prices[i] - prices[i - 1];
      gains.push(change > 0 ? change : 0);
      losses.push(change < 0 ? Math.abs(change) : 0);
    }
    
    // Calculate initial average gain and loss
    let avgGain = 0;
    let avgLoss = 0;
    
    for (let i = 0; i < period; i++) {
      avgGain += gains[i];
      avgLoss += losses[i];
    }
    
    avgGain /= period;
    avgLoss /= period;
    
    // Calculate RSI
    for (let i = period; i < gains.length; i++) {
      avgGain = (avgGain * (period - 1) + gains[i]) / period;
      avgLoss = (avgLoss * (period - 1) + losses[i]) / period;
      
      const rs = avgLoss === 0 ? 100 : avgGain / avgLoss;
      const rsiValue = 100 - (100 / (1 + rs));
      rsi.push(rsiValue);
    }

    return rsi;
  }

  getRequiredDataLength(params?: Record<string, any>): number {
    const period = params?.period || this.defaultParams.period;
    return period + 1;
  }
}