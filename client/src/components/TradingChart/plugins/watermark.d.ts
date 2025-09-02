import type { ChartType } from 'chart.js';
import type { WatermarkOptions } from './watermarkPlugin';

declare module 'chart.js' {
  interface PluginOptionsByType<TType extends ChartType> {
    watermark?: WatermarkOptions;
  }
}