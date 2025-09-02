import { BaseIndicator } from '../base';
import { OHLCData } from '../../types/indicator';

export interface StochasticParams {
  kPeriod: number;
  dPeriod: number;
  smoothK: number;
}

export interface StochasticResult {
  k: (number | null)[];
  d: (number | null)[];
}

export class Stochastic extends BaseIndicator {
  id = 'stochastic';
  name = 'Stochastic';
  type = 'oscillator' as const;
  
  defaultParams: StochasticParams = {
    kPeriod: 14,    // %K period
    dPeriod: 3,     // %D period (SMA of %K)
    smoothK: 1      // Smoothing period for %K
  };

  calculate(data: OHLCData[], params?: Partial<StochasticParams>): number[] {
    const config = { ...this.defaultParams, ...params };
    const result = this.calculateFull(data, params);
    // Return %K as the primary line
    return result.k as number[];
  }

  getRequiredDataLength(params?: Partial<StochasticParams>): number {
    const config = { ...this.defaultParams, ...params };
    return config.kPeriod + config.smoothK + config.dPeriod - 1;
  }

  calculateFull(data: OHLCData[], params?: Partial<StochasticParams>): StochasticResult {
    const config = { ...this.defaultParams, ...params };
    
    if (data.length < this.getRequiredDataLength(params)) {
      return {
        k: [],
        d: []
      };
    }

    const k: (number | null)[] = new Array(data.length).fill(null);
    const d: (number | null)[] = new Array(data.length).fill(null);

    // Calculate raw %K values
    const rawK: number[] = [];
    for (let i = config.kPeriod - 1; i < data.length; i++) {
      // Find highest high and lowest low in the period
      let highestHigh = data[i].high;
      let lowestLow = data[i].low;
      
      for (let j = 0; j < config.kPeriod; j++) {
        const idx = i - j;
        if (idx >= 0) {
          highestHigh = Math.max(highestHigh, data[idx].high);
          lowestLow = Math.min(lowestLow, data[idx].low);
        }
      }
      
      // Calculate %K
      const range = highestHigh - lowestLow;
      if (range === 0) {
        rawK.push(50); // Neutral value when no range
      } else {
        const kValue = ((data[i].close - lowestLow) / range) * 100;
        rawK.push(kValue);
      }
    }

    // Smooth %K if smoothK > 1
    let smoothedK = rawK;
    if (config.smoothK > 1) {
      smoothedK = [];
      for (let i = config.smoothK - 1; i < rawK.length; i++) {
        let sum = 0;
        for (let j = 0; j < config.smoothK; j++) {
          sum += rawK[i - j];
        }
        smoothedK.push(sum / config.smoothK);
      }
    }

    // Place smoothed %K values in the result array
    const kStartIndex = config.kPeriod - 1 + (config.smoothK > 1 ? config.smoothK - 1 : 0);
    for (let i = 0; i < smoothedK.length; i++) {
      k[kStartIndex + i] = smoothedK[i];
    }

    // Calculate %D (SMA of %K)
    const dStartIndex = kStartIndex + config.dPeriod - 1;
    for (let i = 0; i < smoothedK.length - config.dPeriod + 1; i++) {
      let sum = 0;
      for (let j = 0; j < config.dPeriod; j++) {
        sum += smoothedK[i + j];
      }
      d[dStartIndex + i] = sum / config.dPeriod;
    }

    return { k, d };
  }
}