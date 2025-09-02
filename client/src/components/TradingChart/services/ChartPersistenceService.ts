import type { Drawing } from '../DrawingTools/types';

// Chart settings that should be persisted
export interface ChartSettings {
  period: '1d' | '5d' | '1mo' | '3mo' | '6mo' | '1y' | '2y';
  interval: '1m' | '5m' | '15m' | '30m' | '1h' | '4h' | '1d' | '1w';
  chartType: 'candlestick' | 'ohlc' | 'line';
  showVolume: boolean;
  priceScale: 'linear' | 'logarithmic';
  indicators?: string[]; // Future: technical indicators
}

// Complete chart state for a symbol
export interface SymbolChartData {
  symbol: string;
  drawings: Drawing[];
  settings: ChartSettings;
  lastModified: number;
  version: number; // For future migrations
}

// Storage key structure for localStorage
const STORAGE_KEYS = {
  CHART_DATA: 'hingetrade_chart_data',
  GLOBAL_SETTINGS: 'hingetrade_chart_global_settings',
  VERSION: 'hingetrade_chart_version'
} as const;

// Current version for data migration
const CURRENT_VERSION = 1;

// Global chart preferences (not symbol-specific)
export interface GlobalChartSettings {
  autoSave: boolean;
  maxStoredSymbols: number;
  dataRetentionDays: number;
}

export class ChartPersistenceService {
  private static instance: ChartPersistenceService;
  private cache: Map<string, SymbolChartData> = new Map();
  private saveTimeouts: Map<string, number> = new Map();
  private readonly DEBOUNCE_DELAY = 1000; // 1 second debounce for auto-save

  // Default settings
  private readonly DEFAULT_CHART_SETTINGS: ChartSettings = {
    period: '3mo',
    interval: '1d',
    chartType: 'candlestick',
    showVolume: true,
    priceScale: 'linear',
    indicators: []
  };

  private readonly DEFAULT_GLOBAL_SETTINGS: GlobalChartSettings = {
    autoSave: true,
    maxStoredSymbols: 50, // Limit to prevent localStorage bloat
    dataRetentionDays: 90 // Clean up old data after 90 days
  };

  private constructor() {
    this.initializeStorage();
    this.cleanupOldData();
  }

  static getInstance(): ChartPersistenceService {
    if (!ChartPersistenceService.instance) {
      ChartPersistenceService.instance = new ChartPersistenceService();
    }
    return ChartPersistenceService.instance;
  }

  /**
   * Initialize storage system and handle version migrations
   */
  private initializeStorage(): void {
    try {
      const storedVersion = localStorage.getItem(STORAGE_KEYS.VERSION);
      if (!storedVersion || parseInt(storedVersion) < CURRENT_VERSION) {
        this.migrateData(storedVersion ? parseInt(storedVersion) : 0);
        localStorage.setItem(STORAGE_KEYS.VERSION, CURRENT_VERSION.toString());
      }
    } catch (error) {
      console.warn('Failed to initialize chart persistence storage:', error);
    }
  }

  /**
   * Migrate data from older versions
   */
  private migrateData(fromVersion: number): void {
    console.log(`Migrating chart data from version ${fromVersion} to ${CURRENT_VERSION}`);
    
    // Future migration logic can be added here
    if (fromVersion === 0) {
      // First-time setup - no migration needed
      return;
    }

    // Example migration logic for future versions:
    // if (fromVersion < 2) {
    //   // Migrate from v1 to v2
    // }
  }

  /**
   * Clean up old data based on retention settings
   */
  private cleanupOldData(): void {
    try {
      const globalSettings = this.getGlobalSettings();
      const cutoffTime = Date.now() - (globalSettings.dataRetentionDays * 24 * 60 * 60 * 1000);
      
      const allData = this.getAllStoredData();
      const symbolsToRemove: string[] = [];

      for (const [symbol, data] of allData.entries()) {
        if (data.lastModified < cutoffTime) {
          symbolsToRemove.push(symbol);
        }
      }

      // Also enforce max symbols limit
      const sortedByDate = Array.from(allData.entries())
        .sort(([, a], [, b]) => b.lastModified - a.lastModified);

      if (sortedByDate.length > globalSettings.maxStoredSymbols) {
        const excess = sortedByDate.slice(globalSettings.maxStoredSymbols);
        symbolsToRemove.push(...excess.map(([symbol]) => symbol));
      }

      // Remove old/excess symbols
      if (symbolsToRemove.length > 0) {
        console.log(`Cleaning up chart data for ${symbolsToRemove.length} symbols:`, symbolsToRemove);
        symbolsToRemove.forEach(symbol => this.clearSymbolData(symbol));
      }
    } catch (error) {
      console.warn('Failed to cleanup old chart data:', error);
    }
  }

  /**
   * Get all stored chart data from localStorage
   */
  private getAllStoredData(): Map<string, SymbolChartData> {
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.CHART_DATA);
      if (!stored) return new Map();

      const data = JSON.parse(stored) as Record<string, SymbolChartData>;
      return new Map(Object.entries(data));
    } catch (error) {
      console.warn('Failed to load stored chart data:', error);
      return new Map();
    }
  }

  /**
   * Save all cached data to localStorage
   */
  private saveToStorage(): void {
    try {
      const dataToSave: Record<string, SymbolChartData> = {};
      this.cache.forEach((data, symbol) => {
        dataToSave[symbol] = data;
      });

      localStorage.setItem(STORAGE_KEYS.CHART_DATA, JSON.stringify(dataToSave));
    } catch (error) {
      console.error('Failed to save chart data to localStorage:', error);
      // Handle localStorage quota exceeded
      if (error instanceof Error && error.name === 'QuotaExceededError') {
        this.handleStorageQuotaExceeded();
      }
    }
  }

  /**
   * Handle localStorage quota exceeded by removing oldest data
   */
  private handleStorageQuotaExceeded(): void {
    console.warn('localStorage quota exceeded, removing oldest chart data...');
    
    const allData = Array.from(this.cache.entries())
      .sort(([, a], [, b]) => a.lastModified - b.lastModified);

    // Remove oldest 25% of data
    const toRemove = Math.ceil(allData.length * 0.25);
    for (let i = 0; i < toRemove; i++) {
      const [symbol] = allData[i];
      this.cache.delete(symbol);
    }

    // Try saving again
    this.saveToStorage();
  }

  /**
   * Get chart data for a specific symbol
   */
  getSymbolData(symbol: string): SymbolChartData {
    const normalizedSymbol = symbol.toUpperCase().trim();
    
    // Check cache first
    if (this.cache.has(normalizedSymbol)) {
      return this.cache.get(normalizedSymbol)!;
    }

    // Load from storage
    const allData = this.getAllStoredData();
    const stored = allData.get(normalizedSymbol);

    if (stored) {
      this.cache.set(normalizedSymbol, stored);
      return stored;
    }

    // Create new data with defaults
    const newData: SymbolChartData = {
      symbol: normalizedSymbol,
      drawings: [],
      settings: { ...this.DEFAULT_CHART_SETTINGS },
      lastModified: Date.now(),
      version: CURRENT_VERSION
    };

    this.cache.set(normalizedSymbol, newData);
    return newData;
  }

  /**
   * Save drawings for a symbol with debounced auto-save
   */
  saveDrawings(symbol: string, drawings: Drawing[]): void {
    const normalizedSymbol = symbol.toUpperCase().trim();
    const data = this.getSymbolData(normalizedSymbol);
    
    // Update data
    data.drawings = [...drawings]; // Create a copy
    data.lastModified = Date.now();
    this.cache.set(normalizedSymbol, data);

    // Debounced save to prevent excessive writes
    this.debouncedSave(normalizedSymbol);
  }

  /**
   * Save chart settings for a symbol
   */
  saveSettings(symbol: string, settings: Partial<ChartSettings>): void {
    const normalizedSymbol = symbol.toUpperCase().trim();
    const data = this.getSymbolData(normalizedSymbol);
    
    // Update settings
    data.settings = { ...data.settings, ...settings };
    data.lastModified = Date.now();
    this.cache.set(normalizedSymbol, data);

    this.debouncedSave(normalizedSymbol);
  }

  /**
   * Get drawings for a symbol
   */
  getDrawings(symbol: string): Drawing[] {
    return this.getSymbolData(symbol).drawings;
  }

  /**
   * Get settings for a symbol
   */
  getSettings(symbol: string): ChartSettings {
    return this.getSymbolData(symbol).settings;
  }

  /**
   * Clear all data for a symbol
   */
  clearSymbolData(symbol: string): void {
    const normalizedSymbol = symbol.toUpperCase().trim();
    this.cache.delete(normalizedSymbol);
    
    // Remove from localStorage
    const allData = this.getAllStoredData();
    allData.delete(normalizedSymbol);
    
    const dataToSave: Record<string, SymbolChartData> = {};
    allData.forEach((data, sym) => {
      dataToSave[sym] = data;
    });
    
    localStorage.setItem(STORAGE_KEYS.CHART_DATA, JSON.stringify(dataToSave));
  }

  /**
   * Clear all stored chart data
   */
  clearAllData(): void {
    this.cache.clear();
    localStorage.removeItem(STORAGE_KEYS.CHART_DATA);
    localStorage.removeItem(STORAGE_KEYS.GLOBAL_SETTINGS);
    localStorage.removeItem(STORAGE_KEYS.VERSION);
  }

  /**
   * Get list of symbols with saved data
   */
  getSavedSymbols(): string[] {
    const allData = this.getAllStoredData();
    return Array.from(allData.keys()).sort();
  }

  /**
   * Get global chart settings
   */
  getGlobalSettings(): GlobalChartSettings {
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.GLOBAL_SETTINGS);
      if (stored) {
        return { ...this.DEFAULT_GLOBAL_SETTINGS, ...JSON.parse(stored) };
      }
    } catch (error) {
      console.warn('Failed to load global chart settings:', error);
    }
    return { ...this.DEFAULT_GLOBAL_SETTINGS };
  }

  /**
   * Save global chart settings
   */
  saveGlobalSettings(settings: Partial<GlobalChartSettings>): void {
    try {
      const current = this.getGlobalSettings();
      const updated = { ...current, ...settings };
      localStorage.setItem(STORAGE_KEYS.GLOBAL_SETTINGS, JSON.stringify(updated));
    } catch (error) {
      console.error('Failed to save global chart settings:', error);
    }
  }

  /**
   * Debounced save to prevent excessive localStorage writes
   */
  private debouncedSave(symbol: string): void {
    // Clear existing timeout
    const existingTimeout = this.saveTimeouts.get(symbol);
    if (existingTimeout) {
      clearTimeout(existingTimeout);
    }

    // Set new timeout
    const timeout = window.setTimeout(() => {
      this.saveToStorage();
      this.saveTimeouts.delete(symbol);
    }, this.DEBOUNCE_DELAY);

    this.saveTimeouts.set(symbol, timeout);
  }

  /**
   * Force immediate save (useful for component unmount)
   */
  forceSave(): void {
    // Clear all pending timeouts
    this.saveTimeouts.forEach(timeout => clearTimeout(timeout));
    this.saveTimeouts.clear();
    
    // Save immediately
    this.saveToStorage();
  }

  /**
   * Export chart data for a symbol (for sharing/backup)
   */
  exportSymbolData(symbol: string): string {
    const data = this.getSymbolData(symbol);
    return JSON.stringify(data, null, 2);
  }

  /**
   * Import chart data for a symbol
   */
  importSymbolData(symbol: string, jsonData: string): boolean {
    try {
      const data = JSON.parse(jsonData) as SymbolChartData;
      
      // Validate the data structure
      if (!data.symbol || !Array.isArray(data.drawings) || !data.settings) {
        throw new Error('Invalid chart data structure');
      }

      // Update symbol to match the requested one
      data.symbol = symbol.toUpperCase().trim();
      data.lastModified = Date.now();
      data.version = CURRENT_VERSION;

      this.cache.set(data.symbol, data);
      this.saveToStorage();
      
      return true;
    } catch (error) {
      console.error('Failed to import chart data:', error);
      return false;
    }
  }
}

export default ChartPersistenceService;