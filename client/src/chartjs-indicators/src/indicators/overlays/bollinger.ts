import { BaseIndicator } from '../base';
import { OHLCData } from '../../types/indicator';

export interface BollingerBandsParams {
  period: number;
  standardDeviations: number;
  source?: string;
}

export interface BollingerBandsResult {
  upper: (number | null)[];
  middle: (number | null)[];
  lower: (number | null)[];
}

export class BollingerBands extends BaseIndicator {
  id = 'bollinger';
  name = 'Bollinger Bands';
  type = 'overlay' as const;
  
  defaultParams: BollingerBandsParams = {
    period: 20,
    standardDeviations: 2,
    source: 'close'
  };

  calculate(data: OHLCData[], params?: Partial<BollingerBandsParams>): number[] {
    const config = { ...this.defaultParams, ...params };
    const result = this.calculateFull(data, params);
    // Return middle band as the primary line
    return result.middle as number[];
  }

  getRequiredDataLength(params?: Partial<BollingerBandsParams>): number {
    const config = { ...this.defaultParams, ...params };
    return config.period;
  }

  calculateFull(data: OHLCData[], params?: Partial<BollingerBandsParams>): BollingerBandsResult {
    const config = { ...this.defaultParams, ...params };
    const prices = this.extractPrices(data, config.source);
    
    if (prices.length < config.period) {
      return {
        upper: [],
        middle: [],
        lower: []
      };
    }

    const upper: (number | null)[] = new Array(prices.length).fill(null);
    const middle: (number | null)[] = new Array(prices.length).fill(null);
    const lower: (number | null)[] = new Array(prices.length).fill(null);

    // Calculate SMA and standard deviation for each point
    for (let i = config.period - 1; i < prices.length; i++) {
      // Calculate SMA (middle band)
      let sum = 0;
      for (let j = 0; j < config.period; j++) {
        sum += prices[i - j];
      }
      const sma = sum / config.period;
      middle[i] = sma;

      // Calculate standard deviation
      let squaredDiffSum = 0;
      for (let j = 0; j < config.period; j++) {
        const diff = prices[i - j] - sma;
        squaredDiffSum += diff * diff;
      }
      const standardDeviation = Math.sqrt(squaredDiffSum / config.period);

      // Calculate upper and lower bands
      const deviation = standardDeviation * config.standardDeviations;
      upper[i] = sma + deviation;
      lower[i] = sma - deviation;
    }

    return {
      upper,
      middle,
      lower
    };
  }
}