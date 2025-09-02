import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import apiClient from '../services/api';
import watchlistService from '../services/watchlistService';
import type { Watchlist } from '../types';

// Mock watchlist for development
const createMockWatchlist = (): Watchlist => ({
  id: 'mock-watchlist-1',
  accountId: 'mock-account',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  name: 'Default',
  items: [], // Start with empty list, symbols will be added via the UI
});

// Hook to get all watchlists
export const useWatchlists = () => {
  return useQuery<Watchlist[]>({
    queryKey: ['watchlists'],
    queryFn: async () => {
      console.log('🔍 [useWatchlists] Fetching watchlists...');
      
      // Always use the watchlist service which handles both API and localStorage
      const watchlists = await watchlistService.getWatchlists();
      console.log('✅ [useWatchlists] Got watchlists from service:', watchlists);
      return watchlists;
    },
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
    refetchOnMount: false,
    retry: 1,
  });
};

// Hook to create a new watchlist
export const useCreateWatchlist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (name: string) => watchlistService.createWatchlist(name),
    onSuccess: () => {
      // Invalidate and refetch watchlists
      queryClient.invalidateQueries({ queryKey: ['watchlists'] });
    },
  });
};

// Hook to add symbol to watchlist
export const useAddToWatchlist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ watchlistId, symbol }: { watchlistId: string; symbol: string }) => {
      console.log(`🔍 [useAddToWatchlist] Adding ${symbol} to watchlist ${watchlistId}`);
      
      // Use the watchlist service which handles both API and localStorage
      const result = await watchlistService.addToWatchlist(watchlistId, symbol);
      console.log(`✅ [useAddToWatchlist] Successfully added ${symbol} via service`);
      return result;
    },
    onSuccess: () => {
      // Refresh the cache to show the new symbol
      queryClient.invalidateQueries({ queryKey: ['watchlists'] });
    },
    onError: (error, variables) => {
      console.error('❌ [useAddToWatchlist] Failed to add symbol:', error);
    },
  });
};

// Hook to remove symbol from watchlist
export const useRemoveFromWatchlist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ watchlistId, symbol }: { watchlistId: string; symbol: string }) => {
      console.log(`🗑️ [useRemoveFromWatchlist] Removing ${symbol} from watchlist ${watchlistId}`);
      
      // Use the watchlist service which handles both API and localStorage
      const result = await watchlistService.removeFromWatchlist(watchlistId, symbol);
      console.log(`✅ [useRemoveFromWatchlist] Successfully removed ${symbol} via service`);
      return result;
    },
    onSuccess: () => {
      // Refresh the cache to remove the symbol
      queryClient.invalidateQueries({ queryKey: ['watchlists'] });
    },
    onError: (error, variables) => {
      console.error('❌ [useRemoveFromWatchlist] Failed to remove symbol:', error);
    },
  });
};

// Hook to delete a watchlist
export const useDeleteWatchlist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (watchlistId: string) => watchlistService.deleteWatchlist(watchlistId),
    onSuccess: () => {
      // Invalidate and refetch watchlists
      queryClient.invalidateQueries({ queryKey: ['watchlists'] });
    },
  });
};

// Hook to get the default watchlist or create one if none exists
export const useDefaultWatchlist = () => {
  const { data: watchlists, isLoading } = useWatchlists();

  // Find default watchlist, with guaranteed fallback
  const defaultWatchlist = React.useMemo(() => {
    if (!watchlists || watchlists.length === 0) {
      // Return a temporary watchlist while loading
      return createMockWatchlist();
    }
    
    return watchlists.find(w => w.name === 'Default') || watchlists[0];
  }, [watchlists]);
  
  console.log('🔍 [useDefaultWatchlist] Debug:', {
    watchlists,
    defaultWatchlist,
    isLoading,
    watchlistsLength: watchlists?.length,
    hasWatchlist: !!defaultWatchlist
  });

  return {
    watchlist: defaultWatchlist,
    isLoading,
  };
};