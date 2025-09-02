import type { Chart, ChartType, Plugin } from 'chart.js';
import type { IndicatorConfig, IndicatorResult } from './indicator';

declare module 'chart.js' {
  interface PluginOptionsByType<TType extends ChartType> {
    technicalIndicators?: {
      indicators: Record<string, IndicatorConfig>;
      panels?: {
        layout: 'vertical' | 'horizontal';
        ratios?: number[];
        gap?: number;
      };
      crosshair?: {
        enabled: boolean;
        color: string;
        width: number;
        dash?: number[];
      };
    };
  }

  interface Chart {
    indicators?: Map<string, IndicatorResult>;
    
    // Extended methods
    addIndicator(type: string, config?: Partial<IndicatorConfig>): void;
    removeIndicator(id: string): void;
    updateIndicator(id: string, config: Partial<IndicatorConfig>): void;
    getIndicator(id: string): IndicatorResult | undefined;
    clearIndicators(): void;
  }
}

export interface TechnicalIndicatorsPlugin extends Plugin<ChartType> {
  id: string;
  beforeInit?(chart: Chart): void;
  beforeUpdate?(chart: Chart): void;
  afterDatasetsDraw?(chart: Chart): void;
  beforeDestroy?(chart: Chart): void;
}