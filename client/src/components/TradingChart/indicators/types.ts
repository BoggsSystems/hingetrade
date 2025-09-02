// Indicator types and interfaces for the trading chart

export interface OHLCData {
  timestamp: Date;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

export interface IndicatorConfig {
  id: string;
  name: string;
  category: 'overlay' | 'oscillator';
  parameters: Record<string, any>;
  defaultParameters: Record<string, any>;
  enabled: boolean;
}

export interface IndicatorDataPoint {
  x: Date;
  y: number | null;
}

export interface IndicatorDataset {
  label: string;
  data: IndicatorDataPoint[];
  borderColor: string | string[];
  backgroundColor?: string | string[];
  borderWidth?: number;
  pointRadius?: number;
  tension?: number;
  yAxisID?: string;
  type?: 'line' | 'bar';
  borderDash?: number[];
}

export interface OscillatorDataset extends IndicatorDataset {
  upperLevel?: number;
  lowerLevel?: number;
}

export interface IndicatorResult {
  datasets: IndicatorDataset[];
  scales?: Record<string, any>;
}

export interface IndicatorCalculator {
  id: string;
  name: string;
  category: 'overlay' | 'oscillator';
  defaultParameters: Record<string, any>;
  
  calculate: (
    data: Array<{
      timestamp: Date;
      open: number;
      high: number;
      low: number;
      close: number;
      volume: number;
    }>,
    parameters: Record<string, any>
  ) => IndicatorResult;
  
  validateParameters: (parameters: Record<string, any>) => boolean;
}