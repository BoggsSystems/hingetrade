import type { Chart } from 'chart.js';
import type { TechnicalIndicatorsPlugin } from './types/chart';
import type { IndicatorConfig, IndicatorResult, OHLCData, IndicatorStyle } from './types/indicator';
import { IndicatorRegistry } from './indicators';
import { extractOHLCFromDataset, alignDataWithTimestamps, createDatasetFromIndicator } from './utils/data';

export const TechnicalIndicators: TechnicalIndicatorsPlugin = {
  id: 'technicalIndicators',

  beforeInit(chart: Chart) {
    // Initialize indicators map
    chart.indicators = new Map<string, IndicatorResult>();

    // Add indicator methods to chart instance
    chart.addIndicator = function(type: string, config?: Partial<IndicatorConfig>) {
      const indicator = IndicatorRegistry.get(type);
      if (!indicator) {
        console.warn(`Indicator type '${type}' not found`);
        return;
      }

      const id = config?.id || `${type}_${Date.now()}`;
      const fullConfig: IndicatorConfig = {
        id,
        name: config?.name || indicator.name,
        type: indicator.type,
        enabled: config?.enabled ?? true,
        params: { ...indicator.defaultParams, ...config?.params },
        style: { ...indicator.defaultParams, ...config?.style },
        yAxisID: config?.yAxisID,
        panel: config?.panel
      };

      // Store config in options
      if (!chart.options.plugins) {
        chart.options.plugins = {};
      }
      if (!chart.options.plugins.technicalIndicators) {
        chart.options.plugins.technicalIndicators = { indicators: {} };
      }
      if (!chart.options.plugins.technicalIndicators.indicators) {
        chart.options.plugins.technicalIndicators.indicators = {};
      }
      chart.options.plugins.technicalIndicators.indicators[id] = fullConfig;

      chart.update();
    };

    chart.removeIndicator = function(id: string) {
      if (chart.options.plugins?.technicalIndicators?.indicators) {
        const config = chart.options.plugins.technicalIndicators.indicators[id];
        const indicatorType = config?.type || id.split('_')[0];
        
        delete chart.options.plugins.technicalIndicators.indicators[id];
        
        // Handle indicators with multiple datasets
        if (indicatorType === 'bollinger') {
          // Remove upper, lower, middle, and fill band datasets
          ['_upper', '_lower', '_middle', '_fill'].forEach(suffix => {
            const datasetIndex = chart.data.datasets.findIndex(
              (ds: any) => ds.indicatorId === `${id}${suffix}`
            );
            if (datasetIndex > -1) {
              chart.data.datasets.splice(datasetIndex, 1);
            }
          });
        } else if (indicatorType === 'macd') {
          // Remove MACD line and signal line datasets
          ['_macd', '_signal'].forEach(suffix => {
            const datasetIndex = chart.data.datasets.findIndex(
              (ds: any) => ds.indicatorId === `${id}${suffix}`
            );
            if (datasetIndex > -1) {
              chart.data.datasets.splice(datasetIndex, 1);
            }
          });
        } else if (indicatorType === 'stochastic') {
          // Remove %K and %D line datasets
          ['_k', '_d'].forEach(suffix => {
            const datasetIndex = chart.data.datasets.findIndex(
              (ds: any) => ds.indicatorId === `${id}${suffix}`
            );
            if (datasetIndex > -1) {
              chart.data.datasets.splice(datasetIndex, 1);
            }
          });
        } else {
          // Remove single dataset for other indicators
          const datasetIndex = chart.data.datasets.findIndex(
            (ds: any) => ds.indicatorId === id
          );
          if (datasetIndex > -1) {
            chart.data.datasets.splice(datasetIndex, 1);
          }
        }
        
        chart.indicators?.delete(id);
        chart.update();
      }
    };

    chart.updateIndicator = function(id: string, config: Partial<IndicatorConfig>) {
      if (chart.options.plugins?.technicalIndicators?.indicators && chart.options.plugins.technicalIndicators.indicators[id]) {
        chart.options.plugins.technicalIndicators.indicators[id] = {
          ...chart.options.plugins.technicalIndicators.indicators[id],
          ...config
        };
        chart.update();
      }
    };

    chart.getIndicator = function(id: string): IndicatorResult | undefined {
      return chart.indicators?.get(id);
    };

    chart.clearIndicators = function() {
      if (chart.options.plugins?.technicalIndicators) {
        chart.options.plugins.technicalIndicators.indicators = {};
        
        // Remove all indicator datasets
        chart.data.datasets = chart.data.datasets.filter(
          (ds: any) => !ds.indicatorId
        );
        
        chart.indicators?.clear();
        chart.update();
      }
    };
  },

  beforeUpdate(chart: Chart) {
    const options = chart.options.plugins?.technicalIndicators;
    if (!options?.indicators) return;

    // Find the main dataset (first candlestick or line dataset)
    const mainDataset = chart.data.datasets.find((ds: any) => 
      ds.type === 'candlestick' || ds.type === 'line' || !ds.type
    );
    
    if (!mainDataset || !mainDataset.data || mainDataset.data.length === 0) return;

    // Extract OHLC data
    const ohlcData = extractOHLCFromDataset(mainDataset);
    if (ohlcData.length === 0) return;

    // Calculate each enabled indicator
    Object.entries(options.indicators).forEach(([id, config]) => {
      if (!config || !config.enabled) return;

      const indicatorType = config.type || id.split('_')[0];
      const indicator = IndicatorRegistry.get(indicatorType);
      if (!indicator) return;

      try {
        // Special handling for Bollinger Bands which has three lines
        if (indicatorType === 'bollinger' && 'calculateFull' in indicator) {
          const bollingerResult = (indicator as any).calculateFull(ohlcData, config.params);
          if (bollingerResult.middle.length === 0) return;

          const requiredLength = indicator.getRequiredDataLength(config.params);
          const offset = Math.max(0, requiredLength - 1);

          // Create datasets for upper, middle, and lower bands
          const upperData = alignDataWithTimestamps(bollingerResult.upper, ohlcData, offset);
          const middleData = alignDataWithTimestamps(bollingerResult.middle, ohlcData, offset);
          const lowerData = alignDataWithTimestamps(bollingerResult.lower, ohlcData, offset);
          
          // Upper band line
          const upperDataset: any = {
            label: `${config.name || 'BB'} Upper`,
            data: upperData,
            type: 'line',
            borderColor: 'rgba(33, 150, 243, 0.6)',
            backgroundColor: 'transparent',
            borderWidth: 1,
            fill: false,
            pointRadius: 0,
            pointHoverRadius: 4,
            tension: 0.1,
            yAxisID: config.yAxisID || 'y',
            indicatorId: `${id}_upper`
          };
          
          // Lower band line with fill to upper band
          const lowerDataset: any = {
            label: `${config.name || 'BB'} Lower`,
            data: lowerData,
            type: 'line',
            borderColor: 'rgba(33, 150, 243, 0.6)',
            backgroundColor: 'rgba(33, 150, 243, 0.1)',
            borderWidth: 1,
            fill: '-1', // Fill to the previous dataset (upper band)
            pointRadius: 0,
            pointHoverRadius: 4,
            tension: 0.1,
            yAxisID: config.yAxisID || 'y',
            indicatorId: `${id}_lower`
          };
          
          // Update or add datasets in specific order for fill to work
          // First remove existing datasets
          ['_upper', '_lower', '_middle', '_fill'].forEach(suffix => {
            const existingIndex = chart.data.datasets.findIndex(
              (dataset: any) => dataset.indicatorId === `${id}${suffix}`
            );
            if (existingIndex > -1) {
              chart.data.datasets.splice(existingIndex, 1);
            }
          });
          
          // Add datasets in order: upper line first, then lower line with fill
          chart.data.datasets.push(upperDataset);
          chart.data.datasets.push(lowerDataset);

          // Store result for the main line
          const result: IndicatorResult = {
            id,
            name: config.name || indicator.name,
            type: indicator.type,
            data: middleData,
            style: config.style as IndicatorStyle,
            yAxisID: config.yAxisID
          };
          chart.indicators?.set(id, result);
          
        } else if (indicatorType === 'macd' && 'calculateFull' in indicator) {
          const macdResult = (indicator as any).calculateFull(ohlcData, config.params);
          if (macdResult.macd.length === 0) return;

          const requiredLength = indicator.getRequiredDataLength(config.params);
          const offset = Math.max(0, requiredLength - 1);

          // Create datasets for MACD line and signal line
          const macdData = alignDataWithTimestamps(macdResult.macd, ohlcData, offset);
          const signalData = alignDataWithTimestamps(macdResult.signal, ohlcData, offset);
          
          // MACD line
          const macdDataset = createDatasetFromIndicator(
            `${id}_macd`,
            `${config.name || 'MACD'} Line`,
            macdData,
            { ...config.style, color: config.style?.color || '#2196f3' },
            config.yAxisID
          );
          
          // Signal line
          const signalDataset = createDatasetFromIndicator(
            `${id}_signal`,
            `${config.name || 'MACD'} Signal`,
            signalData,
            { ...config.style, color: '#ff9800' },
            config.yAxisID
          );

          // Update or add datasets
          ['_macd', '_signal'].forEach((suffix, idx) => {
            const ds = idx === 0 ? macdDataset : signalDataset;
            const existingIndex = chart.data.datasets.findIndex(
              (dataset: any) => dataset.indicatorId === `${id}${suffix}`
            );
            
            if (existingIndex > -1) {
              chart.data.datasets[existingIndex] = ds;
            } else {
              chart.data.datasets.push(ds);
            }
          });

          // Store result for the main line
          const result: IndicatorResult = {
            id,
            name: config.name || indicator.name,
            type: indicator.type,
            data: macdData,
            style: config.style as IndicatorStyle,
            yAxisID: config.yAxisID
          };
          chart.indicators?.set(id, result);
          
        } else if (indicatorType === 'stochastic' && 'calculateFull' in indicator) {
          const stochasticResult = (indicator as any).calculateFull(ohlcData, config.params);
          if (stochasticResult.k.length === 0) return;

          const requiredLength = indicator.getRequiredDataLength(config.params);
          const offset = Math.max(0, requiredLength - 1);

          // Create datasets for %K and %D lines
          const kData = alignDataWithTimestamps(stochasticResult.k, ohlcData, offset);
          const dData = alignDataWithTimestamps(stochasticResult.d, ohlcData, offset);
          
          // %K line
          const kDataset = createDatasetFromIndicator(
            `${id}_k`,
            `${config.name || 'Stochastic'} %K`,
            kData,
            { ...config.style, color: config.style?.color || '#2196f3' },
            config.yAxisID
          );
          
          // %D line
          const dDataset = createDatasetFromIndicator(
            `${id}_d`,
            `${config.name || 'Stochastic'} %D`,
            dData,
            { ...config.style, color: '#ff9800' },
            config.yAxisID
          );

          // Update or add datasets
          ['_k', '_d'].forEach((suffix, idx) => {
            const ds = idx === 0 ? kDataset : dDataset;
            const existingIndex = chart.data.datasets.findIndex(
              (dataset: any) => dataset.indicatorId === `${id}${suffix}`
            );
            
            if (existingIndex > -1) {
              chart.data.datasets[existingIndex] = ds;
            } else {
              chart.data.datasets.push(ds);
            }
          });

          // Store result for the main line
          const result: IndicatorResult = {
            id,
            name: config.name || indicator.name,
            type: indicator.type,
            data: kData,
            style: config.style as IndicatorStyle,
            yAxisID: config.yAxisID
          };
          chart.indicators?.set(id, result);
          
        } else {
          // Standard single-line indicator handling
          const values = indicator.calculate(ohlcData, config.params);
          if (values.length === 0) return;

          // Determine offset for alignment
          const requiredLength = indicator.getRequiredDataLength(config.params);
          const offset = Math.max(0, requiredLength - 1);

          // Align with timestamps
          const alignedData = alignDataWithTimestamps(values, ohlcData, offset);

          // Store result
          const result: IndicatorResult = {
            id,
            name: config.name || indicator.name,
            type: indicator.type,
            data: alignedData,
            style: config.style as IndicatorStyle,
            yAxisID: config.yAxisID
          };

          chart.indicators?.set(id, result);

          // Update dataset for overlay indicators
          if (indicator.type === 'overlay') {
            const dataset = createDatasetFromIndicator(
              id,
              config.name || indicator.name,
              alignedData,
              config.style || {},
              config.yAxisID
            );

            // Find existing dataset or add new
            const existingIndex = chart.data.datasets.findIndex(
              (ds: any) => ds.indicatorId === id
            );

            if (existingIndex > -1) {
              chart.data.datasets[existingIndex] = dataset;
            } else {
              chart.data.datasets.push(dataset);
            }
          }
        }
      } catch (error) {
        console.error(`Error calculating indicator ${id}:`, error);
      }
    });

    // Remove datasets for disabled/deleted indicators
    chart.data.datasets = chart.data.datasets.filter((ds: any) => {
      if (!ds.indicatorId) return true;
      
      // For multi-line indicator sub-datasets, check the parent indicator
      if (ds.indicatorId.includes('_macd') || ds.indicatorId.includes('_signal')) {
        const parentId = ds.indicatorId.replace(/_macd|_signal/, '');
        return options.indicators && options.indicators[parentId]?.enabled;
      }
      
      if (ds.indicatorId.includes('_k') || ds.indicatorId.includes('_d')) {
        const parentId = ds.indicatorId.replace(/_k|_d/, '');
        return options.indicators && options.indicators[parentId]?.enabled;
      }
      
      if (ds.indicatorId.includes('_upper') || ds.indicatorId.includes('_lower') || ds.indicatorId.includes('_middle') || ds.indicatorId.includes('_fill')) {
        const parentId = ds.indicatorId.replace(/_upper|_lower|_middle|_fill/, '');
        return options.indicators && options.indicators[parentId]?.enabled;
      }
      
      return options.indicators && options.indicators[ds.indicatorId]?.enabled;
    });
  },

  afterDatasetsDraw(chart: Chart) {
    const options = chart.options.plugins?.technicalIndicators;
    if (!options) return;

    // Draw oscillator indicators in separate panels
    const ctx = chart.ctx;
    const chartArea = chart.chartArea;
    
    // This is where we'd implement separate panels for RSI, MACD, etc.
    // For now, they need to be added as separate charts
  },

  beforeDestroy(chart: Chart) {
    // Cleanup
    chart.indicators?.clear();
  }
};

export default TechnicalIndicators;