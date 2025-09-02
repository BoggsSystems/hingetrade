import type { OHLCData } from '../types/indicator';
import type { ChartDataset, ScatterDataPoint } from 'chart.js';

export function extractOHLCFromDataset(dataset: ChartDataset): OHLCData[] {
  if (!dataset.data || dataset.data.length === 0) {
    return [];
  }

  // Handle candlestick data format
  if ('o' in (dataset.data[0] as any)) {
    return dataset.data.map((point: any) => ({
      timestamp: point.x,
      open: point.o,
      high: point.h,
      low: point.l,
      close: point.c,
      volume: point.v || 0
    }));
  }

  // Handle line/scatter data format (use y as close price)
  return dataset.data.map((point: any) => ({
    timestamp: point.x,
    open: point.y,
    high: point.y,
    low: point.y,
    close: point.y,
    volume: 0
  }));
}

export function alignDataWithTimestamps(
  values: number[],
  sourceData: OHLCData[],
  offset: number = 0
): ScatterDataPoint[] {
  const aligned: ScatterDataPoint[] = [];
  
  for (let i = 0; i < values.length; i++) {
    const dataIndex = i + offset;
    if (dataIndex < sourceData.length) {
      aligned.push({
        x: sourceData[dataIndex].timestamp as number,
        y: values[i]
      });
    }
  }
  
  return aligned;
}

export function createDatasetFromIndicator(
  id: string,
  name: string,
  data: ScatterDataPoint[],
  style: any,
  yAxisID?: string
): ChartDataset {
  const dataset: any = {
    label: name,
    data: data,
    type: 'line' as const,
    borderColor: style.color || '#2196f3',
    backgroundColor: style.backgroundColor || style.fillColor || 'transparent',
    borderWidth: style.lineWidth || 2,
    borderDash: style.borderDash || style.lineDash || [],
    fill: style.fill !== undefined ? style.fill : false,
    pointRadius: 0,
    pointHoverRadius: 4,
    tension: 0.1,
    yAxisID: yAxisID || 'y',
    // Custom property to identify indicator datasets
    indicatorId: id
  };
  
  // If fill is an object (for advanced fill configuration), ensure it's properly set
  if (typeof style.fill === 'object' && style.fill !== null) {
    dataset.fill = style.fill;
    dataset.backgroundColor = style.fill.above || style.backgroundColor || 'transparent';
  }
  
  return dataset as ChartDataset & { indicatorId: string };
}