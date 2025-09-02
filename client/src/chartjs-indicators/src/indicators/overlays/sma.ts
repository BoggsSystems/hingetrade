import { BaseIndicator } from '../base';
import { OHLCData, IndicatorType } from '../../types/indicator';

export class SMA extends BaseIndicator {
  id = 'sma';
  name = 'Simple Moving Average';
  type: IndicatorType = 'overlay';
  defaultParams = {
    period: 20,
    source: 'close',
    color: '#2196f3'
  };

  calculate(data: OHLCData[], params = this.defaultParams): number[] {
    const { period, source } = { ...this.defaultParams, ...params };
    const prices = this.extractPrices(data, source);
    
    if (prices.length < period) {
      return [];
    }

    const sma: number[] = [];
    
    for (let i = period - 1; i < prices.length; i++) {
      let sum = 0;
      for (let j = 0; j < period; j++) {
        sum += prices[i - j];
      }
      sma.push(sum / period);
    }

    return sma;
  }

  getRequiredDataLength(params?: Record<string, any>): number {
    const period = params?.period || this.defaultParams.period;
    return period;
  }
}