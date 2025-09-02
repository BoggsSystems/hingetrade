import { BaseIndicator } from '../base';
import { OHLCData } from '../../types/indicator';

export interface MACDParams {
  fastPeriod: number;
  slowPeriod: number;
  signalPeriod: number;
  source?: string;
}

export interface MACDResult {
  macd: (number | null)[];
  signal: (number | null)[];
  histogram: (number | null)[];
}

export class MACD extends BaseIndicator {
  id = 'macd';
  name = 'MACD';
  type = 'oscillator' as const;
  
  defaultParams: MACDParams = {
    fastPeriod: 12,
    slowPeriod: 26,
    signalPeriod: 9,
    source: 'close'
  };

  calculate(data: OHLCData[], params?: Partial<MACDParams>): number[] {
    const config = { ...this.defaultParams, ...params };
    const prices = this.extractPrices(data, config.source);
    
    if (prices.length < config.slowPeriod) {
      return [];
    }

    // Calculate EMAs
    const fastEMA = this.calculateEMA(prices, config.fastPeriod);
    const slowEMA = this.calculateEMA(prices, config.slowPeriod);
    
    // Calculate MACD line (fast EMA - slow EMA)
    const macdLine: (number | null)[] = [];
    for (let i = 0; i < prices.length; i++) {
      if (fastEMA[i] !== null && slowEMA[i] !== null) {
        macdLine.push(fastEMA[i]! - slowEMA[i]!);
      } else {
        macdLine.push(null);
      }
    }
    
    // Calculate Signal line (EMA of MACD line)
    const validMacdValues = macdLine.filter(v => v !== null) as number[];
    const signalEMA = this.calculateEMA(validMacdValues, config.signalPeriod);
    
    // Align signal line with MACD line
    const signalLine: (number | null)[] = new Array(prices.length).fill(null);
    let signalIndex = 0;
    for (let i = 0; i < macdLine.length; i++) {
      if (macdLine[i] !== null && signalIndex < signalEMA.length) {
        signalLine[i] = signalEMA[signalIndex];
        signalIndex++;
      }
    }
    
    // For the main indicator line, we'll return the MACD line
    // The signal and histogram will be available through the getFullResult method
    return macdLine as number[];
  }

  getRequiredDataLength(params?: Partial<MACDParams>): number {
    const config = { ...this.defaultParams, ...params };
    return config.slowPeriod + config.signalPeriod;
  }

  private calculateEMA(data: number[], period: number): (number | null)[] {
    if (data.length < period) {
      return new Array(data.length).fill(null);
    }

    const ema: (number | null)[] = new Array(data.length).fill(null);
    const multiplier = 2 / (period + 1);
    
    // Calculate initial SMA for the first EMA value
    let sum = 0;
    for (let i = 0; i < period; i++) {
      sum += data[i];
    }
    ema[period - 1] = sum / period;
    
    // Calculate EMA for remaining values
    for (let i = period; i < data.length; i++) {
      ema[i] = (data[i] - ema[i - 1]!) * multiplier + ema[i - 1]!;
    }
    
    return ema;
  }

  // Extended method to get all MACD components
  calculateFull(data: OHLCData[], params?: Partial<MACDParams>): MACDResult {
    const config = { ...this.defaultParams, ...params };
    const prices = this.extractPrices(data, config.source);
    
    if (prices.length < config.slowPeriod) {
      return {
        macd: [],
        signal: [],
        histogram: []
      };
    }

    // Calculate EMAs
    const fastEMA = this.calculateEMA(prices, config.fastPeriod);
    const slowEMA = this.calculateEMA(prices, config.slowPeriod);
    
    // Calculate MACD line
    const macdLine: (number | null)[] = [];
    for (let i = 0; i < prices.length; i++) {
      if (fastEMA[i] !== null && slowEMA[i] !== null) {
        macdLine.push(fastEMA[i]! - slowEMA[i]!);
      } else {
        macdLine.push(null);
      }
    }
    
    // Calculate Signal line
    const validMacdValues = macdLine.filter(v => v !== null) as number[];
    const signalEMA = this.calculateEMA(validMacdValues, config.signalPeriod);
    
    // Align signal line with MACD line
    const signalLine: (number | null)[] = new Array(prices.length).fill(null);
    let signalIndex = 0;
    for (let i = 0; i < macdLine.length; i++) {
      if (macdLine[i] !== null && signalIndex < signalEMA.length) {
        signalLine[i] = signalEMA[signalIndex];
        signalIndex++;
      }
    }
    
    // Calculate Histogram (MACD - Signal)
    const histogram: (number | null)[] = [];
    for (let i = 0; i < prices.length; i++) {
      if (macdLine[i] !== null && signalLine[i] !== null) {
        histogram.push(macdLine[i]! - signalLine[i]!);
      } else {
        histogram.push(null);
      }
    }
    
    return {
      macd: macdLine,
      signal: signalLine,
      histogram: histogram
    };
  }
}