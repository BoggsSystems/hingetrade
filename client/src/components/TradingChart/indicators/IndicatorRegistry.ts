import type { IndicatorCalculator, IndicatorConfig, OHLCData } from './types';
import { SMAIndicator } from './SMAIndicator';
import { EMAIndicator } from './EMAIndicator';
import { MACDIndicator } from './MACDIndicator';
import { RSIIndicator } from './RSIIndicator';

export class IndicatorRegistry {
  private indicators = new Map<string, IndicatorCalculator>();
  private configs = new Map<string, IndicatorConfig>();
  
  constructor() {
    this.registerDefaultIndicators();
  }
  
  private registerDefaultIndicators() {
    // Register all default indicators
    this.register(new SMAIndicator());
    this.register(new EMAIndicator());
    this.register(new MACDIndicator());
    this.register(new RSIIndicator());
    
    // Set up default configurations
    this.addConfig({
      id: 'sma20',
      name: 'SMA 20',
      category: 'overlay',
      parameters: { period: 20, source: 'close' },
      defaultParameters: { period: 20, source: 'close' },
      enabled: false
    });
    
    this.addConfig({
      id: 'sma50',
      name: 'SMA 50',
      category: 'overlay',
      parameters: { period: 50, source: 'close' },
      defaultParameters: { period: 50, source: 'close' },
      enabled: false
    });
    
    this.addConfig({
      id: 'ema20',
      name: 'EMA 20',
      category: 'overlay',
      parameters: { period: 20, source: 'close' },
      defaultParameters: { period: 20, source: 'close' },
      enabled: false
    });
    
    this.addConfig({
      id: 'macd',
      name: 'MACD (12,26,9)',
      category: 'oscillator',
      parameters: { fastPeriod: 12, slowPeriod: 26, signalPeriod: 9, source: 'close' },
      defaultParameters: { fastPeriod: 12, slowPeriod: 26, signalPeriod: 9, source: 'close' },
      enabled: false
    });
    
    this.addConfig({
      id: 'rsi14',
      name: 'RSI 14',
      category: 'oscillator',
      parameters: { period: 14, source: 'close', overbought: 70, oversold: 30 },
      defaultParameters: { period: 14, source: 'close', overbought: 70, oversold: 30 },
      enabled: false
    });
  }
  
  register(indicator: IndicatorCalculator) {
    this.indicators.set(indicator.id, indicator);
  }
  
  addConfig(config: IndicatorConfig) {
    this.configs.set(config.id, config);
  }
  
  getIndicator(id: string): IndicatorCalculator | undefined {
    return this.indicators.get(id);
  }
  
  getConfig(id: string): IndicatorConfig | undefined {
    return this.configs.get(id);
  }
  
  getAllConfigs(): IndicatorConfig[] {
    return Array.from(this.configs.values());
  }
  
  getConfigsByCategory(category: 'overlay' | 'oscillator'): IndicatorConfig[] {
    return Array.from(this.configs.values()).filter(config => config.category === category);
  }
  
  calculateIndicator(configId: string, data: OHLCData[]) {
    const config = this.getConfig(configId);
    if (!config) {
      throw new Error(`Indicator config '${configId}' not found`);
    }
    
    // Extract base indicator type from config ID
    const baseType = this.extractBaseType(configId);
    const indicator = this.getIndicator(baseType);
    
    if (!indicator) {
      throw new Error(`Indicator calculator '${baseType}' not found`);
    }
    
    if (!indicator.validateParameters(config.parameters)) {
      throw new Error(`Invalid parameters for indicator '${configId}'`);
    }
    
    return indicator.calculate(data, config.parameters);
  }
  
  private extractBaseType(configId: string): string {
    // Extract base indicator type from config ID
    // e.g., 'sma20' -> 'sma', 'rsi14' -> 'rsi'
    if (configId.startsWith('sma')) return 'sma';
    if (configId.startsWith('ema')) return 'ema';
    if (configId.startsWith('macd')) return 'macd';
    if (configId.startsWith('rsi')) return 'rsi';
    
    // Default to the config ID itself
    return configId;
  }
  
  enableIndicator(configId: string) {
    const config = this.getConfig(configId);
    if (config) {
      config.enabled = true;
    }
  }
  
  disableIndicator(configId: string) {
    const config = this.getConfig(configId);
    if (config) {
      config.enabled = false;
    }
  }
  
  getEnabledConfigs(): IndicatorConfig[] {
    return Array.from(this.configs.values()).filter(config => config.enabled);
  }
}