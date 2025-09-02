import React, { useEffect, useState, useMemo, useCallback, useRef } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  LogarithmicScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  TimeScale,
  BarController,
  BarElement,
} from 'chart.js';
import { Chart } from 'react-chartjs-2';
import type { ChartData, ChartOptions } from 'chart.js';
import zoomPlugin from 'chartjs-plugin-zoom';
import 'chartjs-adapter-date-fns';
import type { IPanelComponentProps } from '../../types/panel';
import SymbolAutocomplete from '../Common/SymbolAutocomplete';
import { IndicatorRegistry } from './indicators';
import { CandlestickIcon, OHLCIcon, LineIcon, VolumeIcon } from './icons/ChartIcons';
import { 
  DrawingToolbar, 
  drawingPlugin, 
  CoordinateConverter,
  DEFAULT_DRAWING_STYLES,
  findDrawingAtPoint,
  findDrawingForCursor,
  moveDrawing,
  calculateDragOffset
} from './DrawingTools';
import type {
  DrawingTool,
  Drawing, 
  DrawingState,
  DrawingStyle
} from './DrawingTools';
import InlineTextEditor from './InlineTextEditor';
import { watermarkPlugin } from './plugins/watermarkPlugin';
import './plugins/watermark.d';
import ChartPersistenceService from './services/ChartPersistenceService';
import type { ChartSettings } from './services/ChartPersistenceService';
import styles from './TradingChart.module.css';

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  LogarithmicScale,
  TimeScale,
  PointElement,
  LineElement,
  BarController,
  BarElement,
  Title,
  Tooltip,
  Legend,
  zoomPlugin,
  drawingPlugin,
  watermarkPlugin
);

// OHLC data type
interface OHLCData {
  timestamp: Date;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

// Market data service embedded in component
class MarketDataService {
  private static instance: MarketDataService;
  private cache = new Map<string, { data: OHLCData[]; timestamp: number }>();
  private readonly CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

  static getInstance(): MarketDataService {
    if (!MarketDataService.instance) {
      MarketDataService.instance = new MarketDataService();
    }
    return MarketDataService.instance;
  }

  private isValidSymbol(symbol: string): boolean {
    return /^[A-Z]{1,5}$/.test(symbol.trim().toUpperCase());
  }

  async getHistoricalData(
    symbol: string, 
    period: '1d' | '5d' | '1mo' | '3mo' | '6mo' | '1y' | '2y' = '3mo',
    interval: '1m' | '5m' | '15m' | '30m' | '1h' | '4h' | '1d' | '1w' = '1d'
  ): Promise<OHLCData[]> {
    if (!symbol || !this.isValidSymbol(symbol)) {
      throw new Error('Invalid symbol format');
    }

    const normalizedSymbol = symbol.trim().toUpperCase();
    const cacheKey = `${normalizedSymbol}-${period}-${interval}`;
    
    // Check cache
    const cached = this.cache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < this.CACHE_DURATION) {
      return cached.data;
    }

    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 800));
    
    const data = this.generateRealisticData(normalizedSymbol, period, interval);

    // Cache the result
    this.cache.set(cacheKey, {
      data,
      timestamp: Date.now(),
    });

    return data;
  }

  private generateRealisticData(symbol: string, period: string, interval: string = '1d'): OHLCData[] {
    const days = this.getPeriodDays(period);
    const intervalsPerDay = this.getIntervalsPerDay(interval);
    const totalIntervals = days * intervalsPerDay;
    const data: OHLCData[] = [];
    
    // Base prices for common symbols
    const basePrices: Record<string, number> = {
      'AAPL': 180,
      'MSFT': 340,
      'GOOGL': 140,
      'AMZN': 145,
      'TSLA': 250,
      'META': 310,
      'NVDA': 470,
      'NFLX': 450,
      'AMD': 120,
      'INTC': 25,
    };
    
    let basePrice = basePrices[symbol] || (50 + Math.random() * 200);
    
    // Symbol-specific characteristics
    const symbolSeed = symbol.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    const volatility = 0.008 + (symbolSeed % 20) * 0.0005; // 0.8% - 1.8% daily volatility
    const trendBias = (symbolSeed % 3 === 0) ? 0.0002 : -0.0001;
    
    for (let i = days; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      
      // Skip weekends for more realistic data
      if (date.getDay() === 0 || date.getDay() === 6) {
        continue;
      }
      
      // Random walk with trend
      const change = (Math.random() - 0.5) * volatility + trendBias;
      basePrice *= (1 + change);
      
      // Intraday range
      const dailyRange = basePrice * (0.005 + Math.random() * 0.015);
      const high = basePrice + dailyRange * Math.random();
      const low = basePrice - dailyRange * Math.random();
      const open = low + (high - low) * Math.random();
      
      data.push({
        timestamp: date,
        open,
        high,
        low,
        close: basePrice,
        volume: Math.floor(Math.random() * 10000000) + 1000000
      });
    }
    
    return data;
  }

  private getPeriodDays(period: string): number {
    switch (period) {
      case '1d': return 1;
      case '5d': return 5;
      case '1mo': return 30;
      case '3mo': return 90;
      case '6mo': return 180;
      case '1y': return 365;
      case '2y': return 730;
      default: return 90;
    }
  }

  private getIntervalsPerDay(interval: string): number {
    switch (interval) {
      case '1m': return 390;   // 6.5 hours of trading
      case '5m': return 78;    // 6.5 hours / 5 min
      case '15m': return 26;   // 6.5 hours / 15 min
      case '30m': return 13;   // 6.5 hours / 30 min
      case '1h': return 7;     // ~7 hours of trading
      case '4h': return 2;     // 2 4-hour intervals per day
      case '1d': return 1;     // 1 daily candle
      case '1w': return 0.2;   // 5 trading days per week
      default: return 1;
    }
  }

  private getIntervalMilliseconds(interval: string): number {
    switch (interval) {
      case '1m': return 60 * 1000;
      case '5m': return 5 * 60 * 1000;
      case '15m': return 15 * 60 * 1000;
      case '30m': return 30 * 60 * 1000;
      case '1h': return 60 * 60 * 1000;
      case '4h': return 4 * 60 * 60 * 1000;
      case '1d': return 24 * 60 * 60 * 1000;
      case '1w': return 7 * 24 * 60 * 60 * 1000;
      default: return 24 * 60 * 60 * 1000;
    }
  }

  getSupportedTimeframes(): Array<{ key: string; label: string }> {
    return [
      { key: '1d', label: '1D' },
      { key: '5d', label: '5D' },
      { key: '1mo', label: '1M' },
      { key: '3mo', label: '3M' },
      { key: '6mo', label: '6M' },
      { key: '1y', label: '1Y' },
      { key: '2y', label: '2Y' },
    ];
  }
}

const marketDataService = MarketDataService.getInstance();

// Create indicator registry instance
const indicatorRegistry = new IndicatorRegistry();

interface TradingChartProps extends IPanelComponentProps {
  data?: OHLCData[];
}

const TradingChartWithData: React.FC<TradingChartProps> = ({
  symbol: propSymbol = 'AAPL',
  onSymbolChange,
  onReady,
  data: propData
}) => {
  // Initialize persistence service
  const persistenceService = useMemo(() => ChartPersistenceService.getInstance(), []);
  
  // Initialize state with persisted data
  const [currentSymbol, setCurrentSymbol] = useState<string>(propSymbol);
  const [selectedIndicators, setSelectedIndicators] = useState<string[]>(['sma20']);
  
  // Initialize chart settings from persistence
  const initialSettings = useMemo(() => {
    const saved = persistenceService.getSettings(propSymbol);
    return saved;
  }, [persistenceService, propSymbol]);
  
  const [timeframe, setTimeframe] = useState<'1d' | '5d' | '1mo' | '3mo' | '6mo' | '1y' | '2y'>(initialSettings.period);
  const [interval, setInterval] = useState<'1m' | '5m' | '15m' | '30m' | '1h' | '4h' | '1d' | '1w'>(initialSettings.interval);
  const [chartType, setChartType] = useState<'line' | 'candlestick' | 'ohlc'>(initialSettings.chartType as 'line' | 'candlestick' | 'ohlc');
  const [showVolume, setShowVolume] = useState<boolean>(initialSettings.showVolume);
  const [priceScale, setPriceScale] = useState<'linear' | 'logarithmic'>(initialSettings.priceScale);
  const [chartData, setChartData] = useState<OHLCData[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Drawing tools state - initialize with persisted drawings
  const [drawingState, setDrawingState] = useState<DrawingState>(() => ({
    activeTool: 'none',
    drawings: persistenceService.getDrawings(propSymbol),
    selectedDrawingId: null,
    isDrawing: false,
    isDragging: false,
    dragStartPoint: null,
    dragOffset: null,
    currentDrawing: null
  }));

  // Chart references for zoom/pan synchronization
  const mainChartRef = useRef<ChartJS | null>(null);
  const volumeChartRef = useRef<ChartJS | null>(null);
  const syncingRef = useRef<boolean>(false); // Prevent infinite sync loops

  // Synchronize volume chart with main chart's time scale
  const syncVolumeChart = useCallback((sourceChart: ChartJS) => {
    if (syncingRef.current) {
      console.log('🔄 syncVolumeChart: Skipping - already syncing');
      return;
    }

    console.log('🔄 syncVolumeChart called', {
      hasVolumeChart: !!volumeChartRef.current,
      showVolume,
      sourceChart: !!sourceChart
    });

    if (!volumeChartRef.current || !showVolume) {
      console.log('❌ syncVolumeChart: Early return - no volume chart or volume disabled');
      return;
    }

    syncingRef.current = true;

    const sourceScale = sourceChart.scales.x;
    const targetChart = volumeChartRef.current;
    const targetScale = targetChart.scales.x;

    console.log('📊 Chart scales:', {
      sourceScale: !!sourceScale,
      targetScale: !!targetScale,
      sourceMin: sourceScale?.min,
      sourceMax: sourceScale?.max,
      targetMin: targetScale?.min,
      targetMax: targetScale?.max
    });

    if (sourceScale && targetScale) {
      // Get the current zoom state from the source chart
      const minTime = sourceScale.min;
      const maxTime = sourceScale.max;
      
      console.log('✅ syncVolumeChart: Attempting to sync time range', {
        minTime,
        maxTime,
        oldMin: targetScale.min,
        oldMax: targetScale.max
      });
      
      // Use Chart.js zoom API to programmatically zoom the volume chart
      if (targetChart.zoom) {
        targetChart.zoom({
          x: {
            min: minTime,
            max: maxTime
          }
        });
        console.log('✅ syncVolumeChart: Used zoom API to sync');
      } else {
        // Fallback: direct scale manipulation with proper update
        targetScale.options.min = minTime;
        targetScale.options.max = maxTime;
        targetChart.update('active');
        console.log('✅ syncVolumeChart: Used scale options fallback');
      }
    } else {
      console.log('❌ syncVolumeChart: Missing scales');
    }

    // Allow future syncs
    setTimeout(() => {
      syncingRef.current = false;
    }, 100);
  }, [showVolume]);

  // Synchronize main chart with volume chart's time scale
  const syncMainChart = useCallback((sourceChart: ChartJS) => {
    if (syncingRef.current) {
      console.log('🔄 syncMainChart: Skipping - already syncing');
      return;
    }

    console.log('🔄 syncMainChart called', {
      hasMainChart: !!mainChartRef.current,
      sourceChart: !!sourceChart
    });

    if (!mainChartRef.current) {
      console.log('❌ syncMainChart: Early return - no main chart');
      return;
    }

    syncingRef.current = true;

    const sourceScale = sourceChart.scales.x;
    const targetChart = mainChartRef.current;
    const targetScale = targetChart.scales.x;

    console.log('📊 Main chart scales:', {
      sourceScale: !!sourceScale,
      targetScale: !!targetScale,
      sourceMin: sourceScale?.min,
      sourceMax: sourceScale?.max,
      targetMin: targetScale?.min,
      targetMax: targetScale?.max
    });

    if (sourceScale && targetScale) {
      // Get the current zoom state from the source chart
      const minTime = sourceScale.min;
      const maxTime = sourceScale.max;
      
      console.log('✅ syncMainChart: Attempting to sync time range', {
        minTime,
        maxTime,
        oldMin: targetScale.min,
        oldMax: targetScale.max
      });
      
      // Use Chart.js zoom API to programmatically zoom the main chart
      if (targetChart.zoom) {
        targetChart.zoom({
          x: {
            min: minTime,
            max: maxTime
          }
        });
        console.log('✅ syncMainChart: Used zoom API to sync');
      } else {
        // Fallback: direct scale manipulation with proper update
        targetScale.options.min = minTime;
        targetScale.options.max = maxTime;
        targetChart.update('active');
        console.log('✅ syncMainChart: Used scale options fallback');
      }
    } else {
      console.log('❌ syncMainChart: Missing scales');
    }

    // Allow future syncs
    setTimeout(() => {
      syncingRef.current = false;
    }, 100);
  }, []);

  // Fetch market data
  const fetchData = useCallback(async (symbolToFetch: string, periodToFetch: typeof timeframe, intervalToFetch: typeof interval) => {
    if (!symbolToFetch || symbolToFetch.trim().length === 0) {
      setChartData([]);
      setError(null);
      return;
    }

    setLoading(true);
    setError(null);
    
    try {
      const data = await marketDataService.getHistoricalData(symbolToFetch, periodToFetch, intervalToFetch);
      setChartData(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch data');
      setChartData([]);
    } finally {
      setLoading(false);
    }
  }, []);

  // Initial data fetch and when currentSymbol/timeframe changes
  useEffect(() => {
    if (propData) {
      setChartData(propData);
    } else {
      fetchData(currentSymbol, timeframe, interval);
    }
  }, [currentSymbol, timeframe, interval, propData, fetchData]);

  // Update currentSymbol when propSymbol changes (from panel linking)
  useEffect(() => {
    setCurrentSymbol(propSymbol);
  }, [propSymbol]);

  // Load persisted data when symbol changes
  useEffect(() => {
    const symbolData = persistenceService.getSymbolData(currentSymbol);
    
    // Load drawings
    setDrawingState(prev => ({
      ...prev,
      drawings: symbolData.drawings,
      selectedDrawingId: null, // Clear selection when switching symbols
      activeTool: 'none' // Reset tool selection
    }));
    
    // Load chart settings
    const settings = symbolData.settings;
    setTimeframe(settings.period);
    setInterval(settings.interval);
    setChartType(settings.chartType as 'line' | 'candlestick' | 'ohlc');
    setShowVolume(settings.showVolume);
    setPriceScale(settings.priceScale);
  }, [currentSymbol, persistenceService]);

  // Auto-save drawings when they change
  useEffect(() => {
    if (drawingState.drawings.length > 0 || persistenceService.getDrawings(currentSymbol).length > 0) {
      persistenceService.saveDrawings(currentSymbol, drawingState.drawings);
    }
  }, [drawingState.drawings, currentSymbol, persistenceService]);

  // Auto-save chart settings when they change
  useEffect(() => {
    const settings: ChartSettings = {
      period: timeframe,
      interval: interval,
      chartType: chartType,
      showVolume: showVolume,
      priceScale: priceScale,
      indicators: selectedIndicators
    };
    
    persistenceService.saveSettings(currentSymbol, settings);
  }, [timeframe, interval, chartType, showVolume, priceScale, selectedIndicators, currentSymbol, persistenceService]);

  // Force save on component unmount
  useEffect(() => {
    return () => {
      persistenceService.forceSave();
    };
  }, [persistenceService]);

  // Calculate close prices for indicators
  const closePrices = useMemo(() => {
    return chartData.map(d => d.close);
  }, [chartData]);

  useEffect(() => {
    onReady?.();
  }, [onReady]);

  // Sync volume chart when it becomes visible
  useEffect(() => {
    console.log('🎯 Initial sync effect triggered', {
      showVolume,
      hasMainChart: !!mainChartRef.current,
      hasVolumeChart: !!volumeChartRef.current
    });

    if (showVolume && mainChartRef.current && volumeChartRef.current) {
      console.log('⏰ Setting up initial sync with delay');
      // Small delay to ensure both charts are fully rendered
      setTimeout(() => {
        console.log('⚡ Performing initial sync now');
        if (mainChartRef.current) {
          syncVolumeChart(mainChartRef.current);
        }
      }, 100);
    }
  }, [showVolume, syncVolumeChart]);


  // Handle dynamic cursor changes for select mode (optimized without debug logging)
  const handleChartMouseMoveForCursor = useCallback((event: MouseEvent) => {
    if (!mainChartRef.current || drawingState.activeTool !== 'none') return;

    const converter = new CoordinateConverter(mainChartRef.current);
    const canvasPoint = converter.getCanvasPosition(event);
    
    if (!converter.isPointInChart(canvasPoint)) return;

    // Use optimized cursor hit testing (no debug logs)
    const hoveredDrawing = findDrawingForCursor(drawingState.drawings, canvasPoint, converter);
    const canvas = mainChartRef.current.canvas;
    
    if (hoveredDrawing) {
      // Show move cursor if hovering over selected drawing, otherwise pointer
      if (hoveredDrawing.selected) {
        canvas.style.cursor = 'move';
      } else {
        canvas.style.cursor = 'url(/cursors/selection-hover-cursor.svg) 3 3, pointer';
      }
    } else {
      // Custom cursor for select mode in empty areas
      canvas.style.cursor = 'url(/cursors/selection-cursor.svg) 3 3, default';
    }
  }, [drawingState.activeTool, drawingState.drawings]);

  // Handle cursor changes based on active tool
  useEffect(() => {
    if (!mainChartRef.current?.canvas) return;

    const canvas = mainChartRef.current.canvas;

    const handleMouseEnter = () => {
      if (drawingState.activeTool === 'none') {
        // Use custom cursor for select mode
        canvas.style.cursor = 'url(/cursors/selection-cursor.svg) 3 3, default';
      } else {
        const cursor = getCursorForTool(drawingState.activeTool, drawingState.selectedDrawingId);
        canvas.style.cursor = cursor;
      }
    };

    const handleMouseLeave = () => {
      canvas.style.cursor = 'default';
    };

    canvas.addEventListener('mouseenter', handleMouseEnter);
    canvas.addEventListener('mouseleave', handleMouseLeave);
    
    // Add dynamic cursor handling for select mode
    if (drawingState.activeTool === 'none') {
      canvas.addEventListener('mousemove', handleChartMouseMoveForCursor);
    }

    // Set initial cursor if mouse is already over canvas
    handleMouseEnter();

    return () => {
      canvas.removeEventListener('mouseenter', handleMouseEnter);
      canvas.removeEventListener('mouseleave', handleMouseLeave);
      canvas.removeEventListener('mousemove', handleChartMouseMoveForCursor);
      canvas.style.cursor = 'default';
    };
  }, [drawingState.activeTool, drawingState.selectedDrawingId, handleChartMouseMoveForCursor]);

  // Helper function to get cursor based on active tool
  const getCursorForTool = (tool: DrawingTool, selectedId: string | null): string => {
    switch (tool) {
      case 'none':
        // In select mode, cursor will be handled dynamically
        return 'url(/cursors/selection-cursor.svg) 3 3, default';
      case 'trendline':
        return 'url(/cursors/crosshair-cursor.svg) 12 12, crosshair';
      case 'horizontal-line':
        return 'row-resize'; // Better cursor for horizontal lines
      case 'vertical-line':
        return 'col-resize'; // Better cursor for vertical lines
      case 'rectangle':
        return 'url(/cursors/crosshair-cursor.svg) 12 12, crosshair';
      case 'text':
        return 'text';
      default:
        return 'default';
    }
  };

  const handleSymbolSelect = useCallback((newSymbol: string) => {
    console.log('Chart symbol selected:', newSymbol);
    setCurrentSymbol(newSymbol.toUpperCase());
    onSymbolChange?.(newSymbol.toUpperCase());
  }, [onSymbolChange]);

  const handleTimeframeChange = (newTimeframe: typeof timeframe) => {
    setTimeframe(newTimeframe);
    
    // Auto-adjust interval based on timeframe
    if (newTimeframe === '1d') {
      setInterval('5m');
    } else if (newTimeframe === '5d') {
      setInterval('15m');
    } else if (newTimeframe === '1mo') {
      setInterval('1h');
    } else if (newTimeframe === '3mo' || newTimeframe === '6mo') {
      setInterval('4h');
    } else {
      setInterval('1d');
    }
  };

  const handleIntervalChange = (newInterval: typeof interval) => {
    setInterval(newInterval);
  };

  const toggleIndicator = (indicatorId: string) => {
    setSelectedIndicators(prev => 
      prev.includes(indicatorId) 
        ? prev.filter(id => id !== indicatorId)
        : [...prev, indicatorId]
    );
  };

  const handleChartTypeChange = (newChartType: typeof chartType) => {
    setChartType(newChartType);
  };

  const toggleVolume = () => {
    setShowVolume(prev => !prev);
  };

  const togglePriceScale = () => {
    setPriceScale(prev => prev === 'linear' ? 'logarithmic' : 'linear');
  };

  // State for inline text editing
  const [textEditState, setTextEditState] = useState<{
    isEditing: boolean;
    drawingId: string | null;
    position: { x: number; y: number } | null;
  }>({
    isEditing: false,
    drawingId: null,
    position: null
  });

  // Mouse event handlers for drawing and selection
  const handleChartMouseDown = useCallback((event: MouseEvent) => {
    // Don't process clicks when text editing is active
    if (textEditState.isEditing) {
      console.log('🚫 Ignoring click - text editing active');
      return;
    }
    
    console.log('🖱️ CLICK DETECTED on canvas');
    
    if (!mainChartRef.current) {
      console.log('❌ No chart ref available');
      return;
    }

    const converter = new CoordinateConverter(mainChartRef.current);
    const canvasPoint = converter.getCanvasPosition(event);
    
    console.log('📍 Canvas click point:', canvasPoint);
    
    if (!converter.isPointInChart(canvasPoint)) {
      console.log('❌ Click outside chart area');
      return;
    }

    // Handle selection mode (Select tool)
    if (drawingState.activeTool === 'none') {
      console.log('🎯 SELECTION MODE - Click at:', canvasPoint);
      console.log('🎯 Available drawings:', drawingState.drawings.length);
      console.log('🎯 Drawings list:', drawingState.drawings);
      
      // Try to find a drawing at the click point
      const clickedDrawing = findDrawingAtPoint(drawingState.drawings, canvasPoint, converter);
      console.log('🎯 Hit test result:', clickedDrawing ? `Found: ${clickedDrawing.id} (${clickedDrawing.type})` : 'No drawing found');
      
      if (clickedDrawing) {
        const chartPoint = converter.canvasToChart(canvasPoint);
        
        // If clicking on already selected drawing, start dragging
        if (clickedDrawing.selected && drawingState.selectedDrawingId === clickedDrawing.id) {
          console.log('🏃 Starting drag for selected drawing');
          const dragOffset = calculateDragOffset(chartPoint, clickedDrawing);
          
          setDrawingState(prev => ({
            ...prev,
            isDragging: true,
            dragStartPoint: chartPoint,
            dragOffset
          }));
        } else {
          console.log('✅ Selecting drawing:', clickedDrawing.id);
          // Select the clicked drawing
          setDrawingState(prev => ({
            ...prev,
            selectedDrawingId: clickedDrawing.id,
            drawings: prev.drawings.map(d => ({
              ...d,
              selected: d.id === clickedDrawing.id
            }))
          }));
        }
        
        // If it's a text drawing, enable editing on double-click
        if (clickedDrawing.type === 'text' && event.detail === 2) {
          console.log('📝 Double-click on text - entering edit mode');
          setTextEditState({
            isEditing: true,
            drawingId: clickedDrawing.id,
            position: { x: canvasPoint.x, y: canvasPoint.y }
          });
        }
      } else {
        console.log('❌ Deselecting all drawings');
        // Clicked empty space - deselect all
        setDrawingState(prev => ({
          ...prev,
          selectedDrawingId: null,
          drawings: prev.drawings.map(d => ({ ...d, selected: false }))
        }));
      }
      return;
    }

    // Handle drawing mode
    const chartPoint = converter.canvasToChart(canvasPoint);
    const drawingId = `drawing-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    // Handle different tool types
    const isTwoPointTool = drawingState.activeTool === 'trendline' || drawingState.activeTool === 'rectangle';
    const isSinglePointTool = drawingState.activeTool === 'horizontal-line' || 
                              drawingState.activeTool === 'vertical-line' || 
                              drawingState.activeTool === 'text';
    
    if (drawingState.activeTool === 'text') {
      // For text tool, create the drawing and immediately enter edit mode
      const completedDrawing: Drawing = {
        id: drawingId,
        type: 'text',
        points: [chartPoint],
        style: DEFAULT_DRAWING_STYLES['text'] as DrawingStyle,
        selected: true,
        text: '' // Start with empty text
      } as Drawing;
      
      setDrawingState(prev => ({
        ...prev,
        drawings: [...prev.drawings.map(d => ({ ...d, selected: false })), completedDrawing],
        selectedDrawingId: drawingId,
        isDrawing: false,
        currentDrawing: null
      }));
      
      // Enter text edit mode with a small delay to ensure proper focus
      setTimeout(() => {
        setTextEditState({
          isEditing: true,
          drawingId: drawingId,
          position: { x: canvasPoint.x, y: canvasPoint.y }
        });
      }, 10);
    } else if (isSinglePointTool) {
      // Other single-point tools: Create and persist immediately
      const completedDrawing: Drawing = {
        id: drawingId,
        type: drawingState.activeTool,
        points: [chartPoint],
        style: DEFAULT_DRAWING_STYLES[drawingState.activeTool] as DrawingStyle,
        selected: false
      } as Drawing;
      
      setDrawingState(prev => ({
        ...prev,
        drawings: [...prev.drawings.map(d => ({ ...d, selected: false })), completedDrawing],
        // Tool remains active for creating more drawings
        isDrawing: false,
        currentDrawing: null,
        selectedDrawingId: null
      }));
    } else if (isTwoPointTool) {
      // Two-point tools: Start drawing mode
      setDrawingState(prev => ({
        ...prev,
        isDrawing: true,
        currentDrawing: {
          id: drawingId,
          type: prev.activeTool,
          points: [chartPoint],
          style: DEFAULT_DRAWING_STYLES[prev.activeTool] as DrawingStyle
        },
        // Clear selections when starting new drawing
        selectedDrawingId: null,
        drawings: prev.drawings.map(d => ({ ...d, selected: false }))
      }));
    }
  }, [drawingState.activeTool, drawingState.drawings, textEditState.isEditing]);

  const handleChartMouseMove = useCallback((event: MouseEvent) => {
    if (!mainChartRef.current) return;

    const converter = new CoordinateConverter(mainChartRef.current);
    const canvasPoint = converter.getCanvasPosition(event);
    const chartPoint = converter.canvasToChart(canvasPoint);

    // Handle dragging a selected drawing
    if (drawingState.isDragging && drawingState.selectedDrawingId && drawingState.dragOffset) {
      console.log('🏃 Dragging drawing');
      const newPosition = {
        x: chartPoint.x + drawingState.dragOffset.x,
        y: chartPoint.y + drawingState.dragOffset.y
      };
      
      const draggedDrawing = drawingState.drawings.find(d => d.id === drawingState.selectedDrawingId);
      if (draggedDrawing) {
        const offset = {
          x: newPosition.x - draggedDrawing.points[0].x,
          y: newPosition.y - draggedDrawing.points[0].y
        };
        
        const movedDrawing = moveDrawing(draggedDrawing, offset);
        
        setDrawingState(prev => ({
          ...prev,
          drawings: prev.drawings.map(d => 
            d.id === prev.selectedDrawingId ? movedDrawing : d
          )
        }));
      }
      return;
    }

    // Handle drawing mode for two-point tools
    if (drawingState.isDrawing && drawingState.currentDrawing) {
      // Update current drawing for two-point tools
      const isTwoPointTool = drawingState.currentDrawing.type === 'trendline' || 
                            drawingState.currentDrawing.type === 'rectangle';
      
      if (isTwoPointTool) {
        setDrawingState(prev => ({
          ...prev,
          currentDrawing: prev.currentDrawing ? {
            ...prev.currentDrawing,
            points: [prev.currentDrawing.points[0], chartPoint]
          } : null
        }));
      }
    }
  }, [drawingState.isDrawing, drawingState.currentDrawing, drawingState.isDragging, drawingState.selectedDrawingId, drawingState.dragOffset, drawingState.drawings]);

  const handleChartMouseUp = useCallback((_event: MouseEvent) => {
    if (!mainChartRef.current) return;

    // End dragging if in progress
    if (drawingState.isDragging) {
      console.log('🛑 Ending drag');
      setDrawingState(prev => ({
        ...prev,
        isDragging: false,
        dragStartPoint: null,
        dragOffset: null
      }));
      return;
    }

    // Complete drawing if in progress
    if (drawingState.isDrawing && drawingState.currentDrawing) {
      // Complete the two-point drawing and persist it
      const completedDrawing = { ...drawingState.currentDrawing } as Drawing;
      
      setDrawingState(prev => ({
        ...prev,
        drawings: [...prev.drawings, completedDrawing],
        isDrawing: false,
        currentDrawing: null
        // Tool remains active (activeTool unchanged) for creating more drawings
      }));
    }
  }, [drawingState.isDrawing, drawingState.currentDrawing, drawingState.isDragging]);

  // Drawing tool handlers
  const handleToolSelect = useCallback((tool: DrawingTool) => {
    setDrawingState(prev => ({
      ...prev,
      activeTool: tool,
      isDrawing: false,
      currentDrawing: null,
      selectedDrawingId: null
    }));
  }, []);
  
  // Add keyboard event handler for ESC key and Delete key
  const handleKeyDown = useCallback((event: KeyboardEvent) => {
    // Don't handle keys if we're editing text (let the text editor handle it)
    if (textEditState.isEditing) return;
    
    // ESC key - exit drawing mode
    if (event.key === 'Escape' && drawingState.activeTool !== 'none') {
      // Cancel current drawing and switch to select mode
      setDrawingState(prev => ({
        ...prev,
        activeTool: 'none',
        isDrawing: false,
        currentDrawing: null,
        selectedDrawingId: null,
        drawings: prev.drawings.map(d => ({ ...d, selected: false }))
      }));
    }
    
    // Delete/Backspace key - remove selected drawing
    if ((event.key === 'Delete' || event.key === 'Backspace') && drawingState.selectedDrawingId) {
      event.preventDefault(); // Prevent browser back navigation on backspace
      console.log('🗑️ Deleting drawing:', drawingState.selectedDrawingId);
      
      setDrawingState(prev => ({
        ...prev,
        drawings: prev.drawings.filter(d => d.id !== prev.selectedDrawingId),
        selectedDrawingId: null
      }));
    }
  }, [drawingState.activeTool, drawingState.selectedDrawingId, textEditState.isEditing]);

  // Debug: Log drawing state changes
  useEffect(() => {
    console.log('📊 Drawing State Updated:', {
      activeTool: drawingState.activeTool,
      drawingsCount: drawingState.drawings.length,
      selectedDrawingId: drawingState.selectedDrawingId,
      selectedDrawings: drawingState.drawings.filter(d => d.selected).map(d => ({ id: d.id, type: d.type }))
    });
  }, [drawingState]);
  
  // Add keyboard event listener
  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleKeyDown]);

  // Attach mouse event listeners to canvas (moved here after handlers are defined)
  useEffect(() => {
    if (!mainChartRef.current?.canvas) return;

    const canvas = mainChartRef.current.canvas;
    console.log('🎮 Attaching mouse event listeners to canvas');

    canvas.addEventListener('mousedown', handleChartMouseDown);
    canvas.addEventListener('mousemove', handleChartMouseMove);
    canvas.addEventListener('mouseup', handleChartMouseUp);

    return () => {
      console.log('🎮 Removing mouse event listeners from canvas');
      canvas.removeEventListener('mousedown', handleChartMouseDown);
      canvas.removeEventListener('mousemove', handleChartMouseMove);
      canvas.removeEventListener('mouseup', handleChartMouseUp);
    };
  }, [handleChartMouseDown, handleChartMouseMove, handleChartMouseUp]);

  const handleClearAllDrawings = useCallback(() => {
    if (drawingState.drawings.length === 0) return;
    
    // Add confirmation for clearing all drawings
    if (window.confirm(`Clear all ${drawingState.drawings.length} drawings?`)) {
      setDrawingState(prev => ({
        ...prev,
        drawings: [],
        selectedDrawingId: null,
        isDrawing: false,
        currentDrawing: null
      }));
    }
  }, [drawingState.drawings.length]);


  // Prepare chart data with indicators
  const data: ChartData<any> = useMemo(() => {
    const datasets: any[] = [];
    const additionalScales: Record<string, any> = {};

    // Main price dataset - changes based on chart type
    if (chartType === 'candlestick') {
      // Create candlestick using floating bars for bodies and lines for wicks
      datasets.push({
        id: `${currentSymbol}-candlestick-bodies`,
        label: `${currentSymbol} Bodies`,
        type: 'bar',
        data: chartData.map(d => ({
          x: d.timestamp,
          y: [Math.min(d.open, d.close), Math.max(d.open, d.close)]
        })),
        backgroundColor: chartData.map(d => 
          d.close >= d.open ? 'rgba(38, 166, 154, 0.8)' : 'rgba(239, 83, 80, 0.8)'
        ),
        borderColor: chartData.map(d => 
          d.close >= d.open ? '#26a69a' : '#ef5350'
        ),
        borderWidth: 1,
        barThickness: 8,
        categoryPercentage: 0.9,
        barPercentage: 0.9,
      });

      // Wicks (high-low lines) using line segments
      datasets.push({
        id: `${currentSymbol}-candlestick-wicks`,
        label: `${currentSymbol} Wicks`,
        type: 'line',
        data: chartData.map(d => ({
          x: d.timestamp,
          y: d.high
        })),
        borderColor: 'rgba(128, 128, 128, 0.6)',
        backgroundColor: 'transparent',
        borderWidth: 1,
        pointRadius: 0,
        pointHoverRadius: 0,
        tension: 0,
        segment: {
          borderColor: (ctx: any) => {
            const index = ctx.p0DataIndex;
            const candle = chartData[index];
            return candle?.close >= candle?.open ? '#26a69a' : '#ef5350';
          }
        },
      });

      // Low wicks
      datasets.push({
        id: `${currentSymbol}-candlestick-low-wicks`,
        label: `${currentSymbol} Low Wicks`,
        type: 'line',
        data: chartData.map(d => ({
          x: d.timestamp,
          y: d.low
        })),
        borderColor: 'rgba(128, 128, 128, 0.6)',
        backgroundColor: 'transparent',
        borderWidth: 1,
        pointRadius: 0,
        pointHoverRadius: 0,
        tension: 0,
      });
    } else if (chartType === 'ohlc') {
      // OHLC as line chart with high/low range
      datasets.push({
        id: `${currentSymbol}-ohlc-range`,
        label: `${currentSymbol} Range`,
        type: 'bar',
        data: chartData.map(d => ({
          x: d.timestamp,
          y: [d.low, d.high]
        })),
        backgroundColor: chartData.map(d => 
          d.close >= d.open ? 'rgba(38, 166, 154, 0.3)' : 'rgba(239, 83, 80, 0.3)'
        ),
        borderColor: chartData.map(d => 
          d.close >= d.open ? '#26a69a' : '#ef5350'
        ),
        borderWidth: 1,
        barThickness: 2,
      });

      // Close prices as line
      datasets.push({
        id: `${currentSymbol}-ohlc-close`,
        label: `${currentSymbol} Close`,
        type: 'line',
        data: chartData.map(d => ({
          x: d.timestamp,
          y: d.close
        })),
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'transparent',
        borderWidth: 2,
        pointRadius: 1,
        pointBackgroundColor: chartData.map(d => 
          d.close >= d.open ? '#26a69a' : '#ef5350'
        ),
        tension: 0,
      });
    } else {
      // Line chart
      datasets.push({
        id: `${currentSymbol}-line`,
        label: currentSymbol,
        type: 'line',
        data: chartData.map(d => ({
          x: d.timestamp,
          y: d.close
        })),
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.1)',
        borderWidth: 2,
        pointRadius: 0,
        pointHoverRadius: 4,
        tension: 0.1,
      });
    }

    // Add indicators using the registry
    selectedIndicators.forEach(indicatorId => {
      try {
        if (!chartData || chartData.length === 0) {
          // Silently skip indicators when no data - this is normal during loading
          return;
        }
        
        indicatorRegistry.enableIndicator(indicatorId);
        // Use closePrices if needed for performance optimization
        const enrichedData = chartData.map((d, i) => ({
          ...d,
          _closePrice: closePrices[i] // Add pre-calculated close price
        }));
        const result = indicatorRegistry.calculateIndicator(indicatorId, enrichedData);
        
        // Add all datasets from this indicator
        if (result && result.datasets) {
          result.datasets.forEach((dataset, index) => {
            datasets.push({
              ...dataset,
              type: dataset.type || 'line',
              // Ensure unique identifier for each indicator dataset
              _indicatorId: `${indicatorId}-${index}`
            });
          });
        }
        
        // Merge additional scales
        if (result && result.scales) {
          Object.assign(additionalScales, result.scales);
        }
      } catch (error) {
        console.warn(`Failed to calculate indicator ${indicatorId}:`, error);
      }
    });

    // Volume is now handled in a separate chart below

    const chartDatasets = {
      datasets
    };
    
    // Store additional scales in a closure variable since ChartData doesn't support it
    (chartDatasets as any).additionalScales = additionalScales;
    
    // Debug log for financial chart types
    if (chartType !== 'line') {
      console.log('Financial chart data:', {
        chartType,
        datasetCount: chartDatasets.datasets.length,
        firstDataset: chartDatasets.datasets[0],
        firstDataPoint: chartDatasets.datasets[0]?.data?.[0]
      });
    }
    
    return chartDatasets;
  }, [chartData, selectedIndicators, currentSymbol, chartType]);

  // Separate volume chart data
  const volumeData: ChartData<any> = useMemo(() => {
    if (!showVolume || !chartData.length) {
      return { datasets: [] };
    }

    return {
      datasets: [{
        id: `volume-dataset-${currentSymbol}`, // Unique dataset ID
        label: 'Volume',
        data: chartData.map((d, index) => ({
          x: d.timestamp,
          y: d.volume,
          _id: `volume-bar-${currentSymbol}-${index}` // More specific ID to avoid conflicts
        })),
        backgroundColor: chartData.map((d) => {
          return d.close >= d.open ? 'rgba(38, 166, 154, 0.8)' : 'rgba(239, 83, 80, 0.8)';
        }),
        borderColor: chartData.map((d) => {
          return d.close >= d.open ? 'rgba(38, 166, 154, 1)' : 'rgba(239, 83, 80, 1)';
        }),
        borderWidth: 1,
      }]
    };
  }, [chartData, showVolume]);

  // Calculate price range for auto-scaling
  const priceRange = useMemo(() => {
    if (chartData.length === 0) return { min: undefined, max: undefined };
    
    if (chartType === 'candlestick' || chartType === 'ohlc') {
      // For financial charts, use high/low prices
      const minPrice = Math.min(...chartData.map(d => d.low));
      const maxPrice = Math.max(...chartData.map(d => d.high));
      return {
        min: minPrice * 0.98, // 2% padding below lowest low
        max: maxPrice * 1.02  // 2% padding above highest high
      };
    } else {
      // For line charts, use close prices
      const minPrice = Math.min(...chartData.map(d => d.close));
      const maxPrice = Math.max(...chartData.map(d => d.close));
      return {
        min: minPrice * 0.98,
        max: maxPrice * 1.02
      };
    }
  }, [chartData, chartType]);

  // Chart options
  const options: ChartOptions<any> = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
      mode: 'index',
      intersect: false,
    },
    plugins: {
      drawingTools: {
        drawings: [
          ...drawingState.drawings,
          ...(drawingState.currentDrawing ? [drawingState.currentDrawing as Drawing] : [])
        ]
      },
      watermark: {
        text: currentSymbol,
        fontSize: undefined, // Will use default based on chart size
        fontFamily: 'Arial, sans-serif',
        color: '#ffffff',
        opacity: 0.08
      },
      legend: {
        display: true,
        position: 'top',
      },
      title: {
        display: false,
      },
      tooltip: {
        mode: 'index',
        intersect: false,
        callbacks: {
          beforeBody: (tooltipItems: any[]) => {
            if (chartType === 'candlestick' && tooltipItems.length > 0) {
              const index = tooltipItems[0].dataIndex;
              const ohlc = chartData[index];
              if (ohlc) {
                return [
                  `Open: $${ohlc.open.toFixed(2)}`,
                  `High: $${ohlc.high.toFixed(2)}`,
                  `Low: $${ohlc.low.toFixed(2)}`,
                  `Close: $${ohlc.close.toFixed(2)}`,
                ];
              }
            }
            return [];
          },
          label: (context: any) => {
            const datasetLabel = context.dataset.label || '';
            
            // Skip candlestick component datasets in tooltip
            if (chartType === 'candlestick' && (
              datasetLabel.includes('Bodies') || 
              datasetLabel.includes('Wicks') || 
              datasetLabel.includes('Low Wicks')
            )) {
              return null;
            }
            
            // For volume bars
            if (context.dataset.label === 'Volume') {
              const value = context.parsed.y;
              const formatted = value ? (value >= 1000000 ? `${(value / 1000000).toFixed(1)}M` : 
                                        value >= 1000 ? `${(value / 1000).toFixed(1)}K` : 
                                        value.toLocaleString()) : 'N/A';
              return `Volume: ${formatted}`;
            }
            
            // For line charts and indicators
            const value = Array.isArray(context.parsed.y) ? context.parsed.y[1] : context.parsed.y;
            return value !== null ? `${datasetLabel}: $${value.toFixed(2)}` : '';
          },
          filter: (tooltipItem: any) => {
            // Filter out candlestick component datasets from tooltip
            if (chartType === 'candlestick') {
              const label = tooltipItem.dataset.label || '';
              return !label.includes('Bodies') && !label.includes('Wicks') && !label.includes('Low Wicks');
            }
            return true;
          }
        }
      },
      zoom: {
        zoom: {
          wheel: {
            enabled: true,
          },
          pinch: {
            enabled: true
          },
          mode: 'x',
          onZoomComplete: ({ chart }: { chart: ChartJS }) => {
            console.log('🖱️ Main chart zoom completed');
            syncVolumeChart(chart);
          }
        },
        pan: {
          enabled: true,
          mode: 'x',
          onPanComplete: ({ chart }: { chart: ChartJS }) => {
            console.log('👆 Main chart pan completed');
            syncVolumeChart(chart);
          }
        }
      }
    },
    scales: {
      x: {
        type: 'time',
        time: {
          unit: 'day',
          displayFormats: {
            day: 'MMM dd'
          }
        },
        grid: {
          display: false
        }
      },
      y: {
        type: priceScale,
        position: 'right',
        min: priceScale === 'logarithmic' ? undefined : priceRange.min,
        max: priceScale === 'logarithmic' ? undefined : priceRange.max,
        grid: {
          color: 'rgba(255, 255, 255, 0.1)'
        },
        ticks: {
          callback: (value: any) => `$${value.toFixed(2)}`
        },
      },
      ...(data as any).additionalScales || {}
    }
  };

  // Volume chart options
  const volumeOptions: ChartOptions<any> = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
      mode: 'index',
      intersect: false,
    },
    plugins: {
      legend: {
        display: false, // Hide volume legend
      },
      title: {
        display: false,
      },
      tooltip: {
        callbacks: {
          label: (context: any) => {
            const value = context.parsed.y;
            const formatted = value ? (value >= 1000000 ? `${(value / 1000000).toFixed(1)}M` : 
                                      value >= 1000 ? `${(value / 1000).toFixed(1)}K` : 
                                      value.toLocaleString()) : 'N/A';
            return `Volume: ${formatted}`;
          }
        }
      },
      zoom: {
        zoom: {
          wheel: {
            enabled: true,
          },
          pinch: {
            enabled: true
          },
          mode: 'x',
          onZoomComplete: ({ chart }: { chart: ChartJS }) => {
            console.log('🖱️ Volume chart zoom completed');
            syncMainChart(chart);
          }
        },
        pan: {
          enabled: true,
          mode: 'x',
          onPanComplete: ({ chart }: { chart: ChartJS }) => {
            console.log('👆 Volume chart pan completed');
            syncMainChart(chart);
          }
        }
      }
    },
    scales: {
      x: {
        type: 'time',
        time: {
          unit: 'day',
          displayFormats: {
            day: 'MMM dd'
          }
        },
        grid: {
          display: false
        }
      },
      y: {
        type: 'linear',
        position: 'right',
        min: 0,
        grid: {
          color: 'rgba(255, 255, 255, 0.05)'
        },
        ticks: {
          callback: (value: any) => {
            return value >= 1000000 ? `${(value / 1000000).toFixed(1)}M` : 
                   value >= 1000 ? `${(value / 1000).toFixed(1)}K` : 
                   value.toLocaleString();
          }
        },
      }
    }
  };

  // Get available indicators from registry
  const availableIndicators = indicatorRegistry.getAllConfigs().map(config => ({
    id: config.id,
    name: config.name,
    category: config.category
  }));

  const chartTypes = [
    { key: 'candlestick', label: 'Candlestick', IconComponent: CandlestickIcon },
    { key: 'ohlc', label: 'OHLC', IconComponent: OHLCIcon },
    { key: 'line', label: 'Line', IconComponent: LineIcon },
  ] as const;

  const timeframes = marketDataService.getSupportedTimeframes();
  
  const intervals = [
    { key: '1m', label: '1m' },
    { key: '5m', label: '5m' },
    { key: '15m', label: '15m' },
    { key: '30m', label: '30m' },
    { key: '1h', label: '1H' },
    { key: '4h', label: '4H' },
    { key: '1d', label: '1D' },
    { key: '1w', label: '1W' }
  ];

  // Handle text input save
  const handleTextSave = useCallback((newText: string, formatting: any) => {
    if (!textEditState.drawingId) return;
    
    if (newText.trim()) {
      // Update the drawing with the new text and formatting
      setDrawingState(prev => ({
        ...prev,
        drawings: prev.drawings.map(d => 
          d.id === textEditState.drawingId 
            ? { 
                ...d, 
                text: newText.trim(), 
                formatting: formatting 
              } as Drawing
            : d
        )
      }));
    } else {
      // If text is empty, remove the drawing
      setDrawingState(prev => ({
        ...prev,
        drawings: prev.drawings.filter(d => d.id !== textEditState.drawingId),
        selectedDrawingId: null
      }));
    }
    
    // Exit text edit mode
    setTextEditState({
      isEditing: false,
      drawingId: null,
      position: null
    });
  }, [textEditState.drawingId]);

  // Handle text input cancel
  const handleTextCancel = useCallback(() => {
    if (!textEditState.drawingId) return;
    
    // Check if this is a new text drawing (empty text)
    const drawing = drawingState.drawings.find(d => d.id === textEditState.drawingId);
    if (drawing && drawing.type === 'text' && !(drawing as any).text) {
      // Remove the empty text drawing
      setDrawingState(prev => ({
        ...prev,
        drawings: prev.drawings.filter(d => d.id !== textEditState.drawingId),
        selectedDrawingId: null
      }));
    }
    
    // Exit text edit mode
    setTextEditState({
      isEditing: false,
      drawingId: null,
      position: null
    });
  }, [textEditState.drawingId, drawingState.drawings]);

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div className={styles.symbolInput}>
          <div className={styles.symbolDisplay}>
            <span className={styles.currentSymbol}>{currentSymbol}</span>
            {loading && <span className={styles.loadingIndicator}>Loading...</span>}
          </div>
          <SymbolAutocomplete
            onSymbolSelect={handleSymbolSelect}
            placeholder="Change symbol..."
            mode="populate"
            className={styles.symbolAutocomplete}
          />
        </div>
        <div className={styles.chartTypeSelector}>
          {chartTypes.map(ct => (
            <button
              key={ct.key}
              className={`${styles.chartTypeButton} ${chartType === ct.key ? styles.active : ''}`}
              onClick={() => handleChartTypeChange(ct.key)}
              disabled={loading}
              title={ct.label}
            >
              <span className={styles.chartTypeIcon}>
                <ct.IconComponent size={16} />
              </span>
              <span className={styles.chartTypeLabel}>{ct.label}</span>
            </button>
          ))}
        </div>
        <div className={styles.volumeToggle}>
          <button
            className={`${styles.volumeButton} ${showVolume ? styles.active : ''}`}
            onClick={toggleVolume}
            disabled={loading}
            title="Toggle Volume Overlay"
          >
            <span className={styles.volumeIcon}>
              <VolumeIcon size={16} />
            </span>
            <span className={styles.volumeLabel}>Volume</span>
          </button>
        </div>
        <div className={styles.scaleToggle}>
          <button
            className={`${styles.scaleButton} ${priceScale === 'logarithmic' ? styles.active : ''}`}
            onClick={togglePriceScale}
            disabled={loading}
            title={`Switch to ${priceScale === 'linear' ? 'Logarithmic' : 'Linear'} Scale`}
          >
            <span className={styles.scaleLabel}>
              {priceScale === 'linear' ? 'Linear' : 'Log'}
            </span>
          </button>
        </div>
        <div className={styles.indicatorDropdown}>
          <select 
            className={styles.indicatorSelect}
            onChange={(e) => {
              if (e.target.value) {
                toggleIndicator(e.target.value);
                e.target.value = ''; // Reset selection
              }
            }}
            disabled={loading || chartData.length === 0}
          >
            <option value="">
              {selectedIndicators.length > 0 
                ? `Indicators (${selectedIndicators.length})` 
                : 'Add Indicator...'
              }
            </option>
            <optgroup label="Overlay Indicators">
              {availableIndicators.filter(indicator => indicator.category === 'overlay').map(indicator => (
                <option 
                  key={indicator.id} 
                  value={indicator.id}
                  style={{ 
                    color: selectedIndicators.includes(indicator.id) ? '#26a69a' : 'inherit' 
                  }}
                >
                  {selectedIndicators.includes(indicator.id) ? '✓ ' : ''}{indicator.name}
                </option>
              ))}
            </optgroup>
            <optgroup label="Oscillators">
              {availableIndicators.filter(indicator => indicator.category === 'oscillator').map(indicator => (
                <option 
                  key={indicator.id} 
                  value={indicator.id}
                  style={{ 
                    color: selectedIndicators.includes(indicator.id) ? '#26a69a' : 'inherit' 
                  }}
                >
                  {selectedIndicators.includes(indicator.id) ? '✓ ' : ''}{indicator.name}
                </option>
              ))}
            </optgroup>
          </select>
        </div>
        <div className={styles.periodDropdown}>
          <select
            className={styles.periodSelect}
            value={timeframe}
            onChange={(e) => handleTimeframeChange(e.target.value as typeof timeframe)}
            disabled={loading}
          >
            <optgroup label="Period">
              {timeframes.map(tf => (
                <option key={tf.key} value={tf.key}>
                  {tf.label}
                </option>
              ))}
            </optgroup>
          </select>
        </div>
        <div className={styles.intervalDropdown}>
          <select
            className={styles.intervalSelect}
            value={interval}
            onChange={(e) => handleIntervalChange(e.target.value as typeof interval)}
            disabled={loading}
          >
            <optgroup label="Interval">
              {intervals.map(iv => (
                <option key={iv.key} value={iv.key}>
                  {iv.label}
                </option>
              ))}
            </optgroup>
          </select>
        </div>
      </div>
      
      {error && (
        <div className={styles.errorMessage}>
          {error}
        </div>
      )}

      {/* Drawing Tools Toolbar */}
      <div className={styles.drawingToolbar}>
        <DrawingToolbar
          activeTool={drawingState.activeTool}
          onToolSelect={handleToolSelect}
          onClearAll={handleClearAllDrawings}
          disabled={loading || chartData.length === 0}
          drawingsCount={drawingState.drawings.length}
          selectedDrawingId={drawingState.selectedDrawingId}
        />
      </div>
      
      <div className={styles.chartWrapper}>
        {/* Main Price Chart */}
        <div className={styles.mainChart}>
          {chartData.length > 0 && data.datasets.length > 0 ? (
            <Chart 
              ref={(chartInstance) => {
                mainChartRef.current = chartInstance;
                console.log('📊 Main chart ref assigned:', !!chartInstance);
              }}
              type={chartType === 'line' ? 'line' : 'bar'} 
              data={data} 
              options={options} 
            />
          ) : loading ? (
            <div className={styles.loadingMessage}>
              Loading chart data...
            </div>
          ) : error ? (
            <div className={styles.errorMessage}>
              {error}
            </div>
          ) : (
            <div className={styles.noDataMessage}>
              Enter a valid stock symbol to view chart data
            </div>
          )}
        </div>

        {/* Volume Chart */}
        {showVolume && chartData.length > 0 && (
          <div className={styles.volumeChart}>
            <Chart 
              ref={(chartInstance) => {
                volumeChartRef.current = chartInstance;
                console.log('📈 Volume chart ref assigned:', !!chartInstance);
              }}
              type="bar" 
              data={volumeData} 
              options={volumeOptions} 
            />
          </div>
        )}

        {/* Inline Text Editor */}
        {textEditState.isEditing && textEditState.position && (
          <InlineTextEditor
            position={textEditState.position}
            initialText={(() => {
              const drawing = drawingState.drawings.find(d => d.id === textEditState.drawingId);
              return (drawing && drawing.type === 'text') ? (drawing as any).text || '' : '';
            })()}
            initialFormatting={(() => {
              const drawing = drawingState.drawings.find(d => d.id === textEditState.drawingId);
              return (drawing && drawing.type === 'text') ? (drawing as any).formatting : undefined;
            })()}
            onSave={handleTextSave}
            onCancel={handleTextCancel}
          />
        )}
      </div>
    </div>
  );
};

TradingChartWithData.displayName = 'Trading Chart';

export default TradingChartWithData;