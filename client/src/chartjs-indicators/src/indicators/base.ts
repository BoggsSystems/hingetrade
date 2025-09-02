import type { OHLCData, IndicatorStyle } from '../types/indicator';
import { Indicator } from '../types/indicator';

export abstract class BaseIndicator extends Indicator {
  protected extractPrices(data: OHLCData[], field: string = 'close'): number[] {
    return data.map(d => {
      if (field === 'volume') return d.volume || 0;
      if (field === 'open') return d.open;
      if (field === 'high') return d.high;
      if (field === 'low') return d.low;
      return d.close;
    });
  }

  protected calculateTypicalPrice(data: OHLCData[]): number[] {
    return data.map(d => (d.high + d.low + d.close) / 3);
  }

  protected calculateHLC3(data: OHLCData[]): number[] {
    return data.map(d => (d.high + d.low + d.close) / 3);
  }

  protected calculateOHLC4(data: OHLCData[]): number[] {
    return data.map(d => (d.open + d.high + d.low + d.close) / 4);
  }

  protected getDefaultStyle(): IndicatorStyle {
    return {
      lineWidth: 2,
      opacity: 1,
      fill: false
    };
  }

  protected padWithNull(data: number[], padLength: number): (number | null)[] {
    const nullPad = new Array(padLength).fill(null);
    return [...nullPad, ...data];
  }
}