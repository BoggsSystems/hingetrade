import { useQuery, useQueries } from '@tanstack/react-query';
import apiClient from '../services/api';
import type { Asset, MarketHours } from '../types';

// Hook to get asset details with latest price
export const useAsset = (symbol: string, enabled = true) => {
  return useQuery<Asset>({
    queryKey: ['asset', symbol],
    queryFn: () => apiClient.getAsset(symbol),
    enabled: enabled && !!symbol,
    staleTime: 5 * 1000, // Consider data fresh for 5 seconds
    refetchInterval: 10 * 1000, // Refresh every 10 seconds
  });
};

// Mock data for development
const createMockAsset = (symbol: string) => ({
  id: symbol,
  symbol,
  name: `${symbol} Mock Company`,
  exchange: 'NASDAQ',
  class: 'us_equity',
  status: 'active',
  tradable: true,
  marginable: true,
  shortable: true,
  easyToBorrow: true,
  fractionable: true,
  price: Math.random() * 200 + 50, // Random price between 50-250
  changePercent: (Math.random() - 0.5) * 10, // Random change between -5% and +5%
  volume: Math.floor(Math.random() * 1000000) + 100000,
  avgVolume: Math.floor(Math.random() * 2000000) + 500000,
  dayHigh: 0,
  dayLow: 0,
  timestamp: new Date().toISOString(),
});

// Hook to get multiple assets (for watchlist or portfolio)
export const useAssets = (symbols: string[]) => {
  return useQueries({
    queries: symbols.map(symbol => ({
      queryKey: ['asset', symbol],
      queryFn: async () => {
        console.log(`🔍 [useAssets] Fetching asset data for: ${symbol}`);
        try {
          const asset = await apiClient.getAsset(symbol);
          console.log(`✅ [useAssets] Got real data for ${symbol}:`, asset);
          return asset;
        } catch (error) {
          console.warn(`⚠️ [useAssets] API failed for ${symbol}, using mock data:`, error);
          // Return mock data for development
          const mockAsset = createMockAsset(symbol);
          console.log(`🎭 [useAssets] Using mock data for ${symbol}:`, mockAsset);
          return mockAsset;
        }
      },
      staleTime: 30 * 1000, // Increase stale time to reduce refetching
      refetchInterval: false, // Disable automatic refetching for now
      refetchOnWindowFocus: false, // Don't refetch when window gains focus
      retry: 1, // Only retry once before falling back to mock
    })),
  });
};

// Hook to search assets
export const useAssetSearch = (query: string, enabled = true) => {
  return useQuery<Asset[]>({
    queryKey: ['assetSearch', query],
    queryFn: () => apiClient.searchAssets(query),
    enabled: enabled && query.length > 0,
    staleTime: 30 * 1000, // Cache search results for 30 seconds
  });
};

// Hook to get market hours
export const useMarketHours = () => {
  return useQuery<MarketHours>({
    queryKey: ['marketHours'],
    queryFn: () => apiClient.getMarketHours(),
    staleTime: 60 * 60 * 1000, // Cache for 1 hour
    refetchInterval: 5 * 60 * 1000, // Refresh every 5 minutes
  });
};

// Mock function for top movers (backend doesn't have this endpoint yet)
const getTopMovers = async () => {
  // In a real implementation, this would call the backend
  // For now, we'll fetch some popular symbols and calculate movers
  const popularSymbols = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'META', 'NVDA', 'AMD'];
  const assets = await Promise.all(
    popularSymbols.map(symbol => apiClient.getAsset(symbol).catch(() => null))
  );

  const validAssets = assets.filter((asset): asset is Asset => asset !== null);
  
  // Sort by change percent
  const sorted = validAssets.sort((a, b) => {
    const aChange = a.changePercent || 0;
    const bChange = b.changePercent || 0;
    return Math.abs(bChange) - Math.abs(aChange);
  });

  const gainers = sorted.filter(a => (a.changePercent || 0) > 0).slice(0, 5);
  const losers = sorted.filter(a => (a.changePercent || 0) < 0).slice(0, 5);

  return { gainers, losers };
};

// Hook to get top movers
export const useTopMovers = () => {
  return useQuery({
    queryKey: ['topMovers'],
    queryFn: getTopMovers,
    staleTime: 60 * 1000, // Cache for 1 minute
    refetchInterval: 2 * 60 * 1000, // Refresh every 2 minutes
  });
};

// Hook to check if market is open
export const useIsMarketOpen = () => {
  const { data: marketHours } = useMarketHours();
  
  const isOpen = marketHours?.isOpen || false;
  const isPreMarket = false; // TODO: Calculate based on current time and market hours
  const isAfterHours = false; // TODO: Calculate based on current time and market hours
  
  return {
    isOpen,
    isPreMarket,
    isAfterHours,
    marketHours,
  };
};