import { Indicator } from '../types/indicator';
import { SMA } from './overlays/sma';
import { EMA } from './overlays/ema';
import { BollingerBands } from './overlays/bollinger';
import { RSI } from './oscillators/rsi';
import { MACD } from './oscillators/macd';
import { Stochastic } from './oscillators/stochastic';

export class IndicatorRegistry {
  private static indicators = new Map<string, new () => Indicator>();

  static {
    // Register built-in indicators
    this.register('sma', SMA);
    this.register('ema', EMA);
    this.register('bollinger', BollingerBands);
    this.register('rsi', RSI);
    this.register('macd', MACD);
    this.register('stochastic', Stochastic);
  }

  static register(id: string, indicatorClass: new () => Indicator): void {
    this.indicators.set(id, indicatorClass);
  }

  static get(id: string): Indicator | undefined {
    const IndicatorClass = this.indicators.get(id);
    return IndicatorClass ? new IndicatorClass() : undefined;
  }

  static getAll(): Map<string, new () => Indicator> {
    return new Map(this.indicators);
  }

  static has(id: string): boolean {
    return this.indicators.has(id);
  }
}

// Export individual indicators for direct use
export { SMA } from './overlays/sma';
export { EMA } from './overlays/ema';
export { BollingerBands } from './overlays/bollinger';
export { RSI } from './oscillators/rsi';
export { MACD } from './oscillators/macd';
export { Stochastic } from './oscillators/stochastic';