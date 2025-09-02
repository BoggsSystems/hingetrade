// Main plugin export
export { TechnicalIndicators as default } from './plugin';
export { TechnicalIndicators } from './plugin';

// Type exports
export * from './types/indicator';
export * from './types/chart';

// Indicator exports
export { IndicatorRegistry } from './indicators';
export * from './indicators';

// Utility exports
export * from './utils/data';

// Pre-built indicator classes for direct use
export { SMA } from './indicators/overlays/sma';
export { EMA } from './indicators/overlays/ema';
export { RSI } from './indicators/oscillators/rsi';