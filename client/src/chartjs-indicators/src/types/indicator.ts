export interface OHLCData {
  timestamp: string | number | Date;
  open: number;
  high: number;
  low: number;
  close: number;
  volume?: number;
}

export type IndicatorType = 'overlay' | 'oscillator' | 'volume';

export interface IndicatorConfig {
  id: string;
  name: string;
  type: IndicatorType;
  enabled: boolean;
  params: Record<string, any>;
  style?: IndicatorStyle;
  yAxisID?: string;
  panel?: 'main' | 'bottom' | 'top';
}

export interface IndicatorStyle {
  color?: string | string[];
  lineWidth?: number;
  lineDash?: number[];
  fill?: boolean;
  fillColor?: string;
  opacity?: number;
}

export interface IndicatorResult {
  id: string;
  name: string;
  type: IndicatorType;
  data: any[];
  style?: IndicatorStyle;
  yAxisID?: string;
}

export abstract class Indicator {
  abstract id: string;
  abstract name: string;
  abstract type: IndicatorType;
  abstract defaultParams: Record<string, any>;

  abstract calculate(data: OHLCData[], params?: Record<string, any>): number[];
  
  validateData(data: OHLCData[]): boolean {
    return data && data.length > 0;
  }

  getRequiredDataLength(params?: Record<string, any>): number {
    return 1;
  }
}