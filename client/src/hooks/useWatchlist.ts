import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import apiClient from '../services/api';
import type { Watchlist } from '../types';

// Hook to get all watchlists
export const useWatchlists = () => {
  return useQuery<Watchlist[]>({
    queryKey: ['watchlists'],
    queryFn: () => apiClient.getWatchlists(),
    staleTime: 30 * 1000, // Consider data fresh for 30 seconds
  });
};

// Hook to create a new watchlist
export const useCreateWatchlist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (name: string) => apiClient.createWatchlist(name),
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
    mutationFn: ({ watchlistId, symbol }: { watchlistId: string; symbol: string }) =>
      apiClient.addToWatchlist(watchlistId, symbol),
    onSuccess: () => {
      // Invalidate and refetch watchlists
      queryClient.invalidateQueries({ queryKey: ['watchlists'] });
    },
  });
};

// Hook to remove symbol from watchlist
export const useRemoveFromWatchlist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ watchlistId, symbol }: { watchlistId: string; symbol: string }) =>
      apiClient.removeFromWatchlist(watchlistId, symbol),
    onSuccess: () => {
      // Invalidate and refetch watchlists
      queryClient.invalidateQueries({ queryKey: ['watchlists'] });
    },
  });
};

// Hook to delete a watchlist
export const useDeleteWatchlist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (watchlistId: string) => 
      apiClient.instance.delete(`/watchlists/${watchlistId}`),
    onSuccess: () => {
      // Invalidate and refetch watchlists
      queryClient.invalidateQueries({ queryKey: ['watchlists'] });
    },
  });
};

// Hook to get the default watchlist or create one if none exists
export const useDefaultWatchlist = () => {
  const { data: watchlists, isLoading } = useWatchlists();
  const createWatchlist = useCreateWatchlist();

  // Find or create default watchlist
  const defaultWatchlist = watchlists?.find(w => w.name === 'Default') || watchlists?.[0];

  const ensureDefaultWatchlist = async () => {
    if (!watchlists || watchlists.length === 0) {
      return await createWatchlist.mutateAsync('Default');
    }
    return defaultWatchlist;
  };

  return {
    watchlist: defaultWatchlist,
    isLoading,
    ensureDefaultWatchlist,
  };
};