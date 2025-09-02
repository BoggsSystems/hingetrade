import type { IndicatorCalculator, IndicatorResult, OHLCData } from './types';

// Base abstract class for indicators
export abstract class BaseIndicator implements IndicatorCalculator {
  abstract id: string;
  abstract name: string;
  abstract category: 'overlay' | 'oscillator';
  abstract defaultParameters: Record<string, any>;

  abstract calculate(data: OHLCData[], parameters: Record<string, any>): IndicatorResult;
  
  validateParameters(parameters: Record<string, any>): boolean {
    // Default validation - check if all required parameters exist
    const defaults = this.defaultParameters;
    for (const key in defaults) {
      if (!(key in parameters)) {
        return false;
      }
    }
    return true;
  }

  // Helper methods for common calculations
  protected calculateSMA(values: number[], period: number): (number | null)[] {
    const result: (number | null)[] = [];
    
    for (let i = 0; i < values.length; i++) {
      if (i < period - 1) {
        result.push(null);
      } else {
        let sum = 0;
        for (let j = 0; j < period; j++) {
          sum += values[i - j];
        }
        result.push(sum / period);
      }
    }
    
    return result;
  }

  protected calculateEMA(values: number[], period: number): (number | null)[] {
    const result: (number | null)[] = [];
    const multiplier = 2 / (period + 1);
    
    // Start with SMA for the first value
    let sum = 0;
    for (let i = 0; i < period && i < values.length; i++) {
      sum += values[i];
      if (i < period - 1) {
        result.push(null);
      } else {
        result.push(sum / period);
      }
    }
    
    // Calculate EMA for the rest
    for (let i = period; i < values.length; i++) {
      const prevEma = result[i - 1] as number;
      result.push((values[i] - prevEma) * multiplier + prevEma);
    }
    
    return result;
  }

  protected formatDataPoints(timestamps: Date[], values: (number | null)[]): Array<{ x: Date; y: number | null }> {
    return timestamps.map((timestamp, i) => ({
      x: timestamp,
      y: values[i]
    }));
  }
}