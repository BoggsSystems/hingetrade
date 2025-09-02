import { BaseIndicator } from '../base';
import { OHLCData, IndicatorType } from '../../types/indicator';

export class EMA extends BaseIndicator {
  id = 'ema';
  name = 'Exponential Moving Average';
  type: IndicatorType = 'overlay';
  defaultParams = {
    period: 20,
    source: 'close',
    color: '#ff9800'
  };

  calculate(data: OHLCData[], params = this.defaultParams): number[] {
    const { period, source } = { ...this.defaultParams, ...params };
    const prices = this.extractPrices(data, source);
    
    if (prices.length < period) {
      return [];
    }

    const ema: number[] = [];
    const multiplier = 2 / (period + 1);
    
    // Calculate initial SMA for the first EMA value
    let sum = 0;
    for (let i = 0; i < period; i++) {
      sum += prices[i];
    }
    ema.push(sum / period);
    
    // Calculate EMA for remaining values
    for (let i = period; i < prices.length; i++) {
      const currentEMA = (prices[i] - ema[ema.length - 1]) * multiplier + ema[ema.length - 1];
      ema.push(currentEMA);
    }

    return ema;
  }

  getRequiredDataLength(params?: Record<string, any>): number {
    const period = params?.period || this.defaultParams.period;
    return period;
  }
}