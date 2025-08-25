import { useQuery } from '@tanstack/react-query';
import apiClient from '../services/api';
import type { Asset } from '../types';

// Hook to validate if an asset is tradable
export const useAssetValidation = (symbol: string, enabled = true) => {
  return useQuery<Asset>({
    queryKey: ['assetValidation', symbol],
    queryFn: () => apiClient.getAsset(symbol),
    enabled: enabled && !!symbol,
    select: (data) => ({
      ...data,
      isTradable: data.tradable && data.status === 'active',
      canBuyFractional: data.fractionable,
      canShort: data.shortable && data.easyToBorrow,
    }),
  });
};

// Hook to get asset classes and categories
export const useAssetCategories = () => {
  // This would ideally come from the backend
  // For now, return static categories
  return {
    data: [
      { id: 'all', label: 'All Assets', count: 0 },
      { id: 'stocks', label: 'Stocks', count: 0 },
      { id: 'etfs', label: 'ETFs', count: 0 },
      { id: 'crypto', label: 'Crypto', count: 0 },
    ],
    isLoading: false,
  };
};

// Hook to filter assets by category
export const useAssetsByCategory = (category: string, query = '') => {
  return useQuery<Asset[]>({
    queryKey: ['assetsByCategory', category, query],
    queryFn: async () => {
      // If there's a search query, use search endpoint
      if (query) {
        const results = await apiClient.searchAssets(query);
        // Filter by category if not 'all'
        if (category !== 'all') {
          return results.filter((asset: any) => {
            if (category === 'stocks') return asset.class === 'us_equity' && !asset.symbol.includes('ETF');
            if (category === 'etfs') return asset.class === 'us_equity' && asset.symbol.includes('ETF');
            if (category === 'crypto') return asset.class === 'crypto';
            return true;
          });
        }
        return results;
      }
      
      // Without query, return popular assets by category
      const popularByCategory: Record<string, string[]> = {
        all: ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'SPY', 'QQQ', 'BTC/USD', 'ETH/USD'],
        stocks: ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'META', 'NVDA', 'JPM', 'V', 'JNJ'],
        etfs: ['SPY', 'QQQ', 'IWM', 'DIA', 'VTI', 'VOO', 'EEM', 'GLD', 'TLT', 'XLF'],
        crypto: ['BTC/USD', 'ETH/USD'],
      };

      const symbols = popularByCategory[category] || popularByCategory.all;
      const assets = await Promise.all(
        symbols.map(symbol => apiClient.getAsset(symbol).catch(() => null))
      );
      
      return assets.filter((asset): asset is Asset => asset !== null);
    },
    staleTime: 60 * 1000, // Cache for 1 minute
  });
};

// Export all hooks
export * from './useMarketData';
export * from './usePortfolio';
export * from './useWatchlist';
export * from './useOrders';