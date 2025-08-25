import { useQuery } from '@tanstack/react-query';
import apiClient from '../services/api';
import type { Account, Position, PortfolioHistory } from '../types';

// Hook to get account information
export const useAccount = () => {
  return useQuery<Account>({
    queryKey: ['account'],
    queryFn: () => apiClient.getAccount(),
    staleTime: 30 * 1000, // Consider data fresh for 30 seconds
    refetchInterval: 60 * 1000, // Refresh every minute
  });
};

// Hook to get positions
export const usePositions = () => {
  return useQuery<Position[]>({
    queryKey: ['positions'],
    queryFn: () => apiClient.getPositions(),
    staleTime: 10 * 1000, // Consider data fresh for 10 seconds
    refetchInterval: 30 * 1000, // Refresh every 30 seconds
  });
};

// Hook to get portfolio history
export const usePortfolioHistory = (period: string = '1D') => {
  return useQuery<PortfolioHistory[]>({
    queryKey: ['portfolioHistory', period],
    queryFn: () => apiClient.getPortfolioHistory(),
    staleTime: 5 * 60 * 1000, // Consider data fresh for 5 minutes
  });
};

// Combined portfolio data hook
export const usePortfolio = () => {
  const account = useAccount();
  const positions = usePositions();

  // Calculate portfolio metrics
  const portfolioValue = parseFloat(account.data?.portfolioValue || '0');
  const cash = parseFloat(account.data?.cash || '0');
  const equity = parseFloat(account.data?.equity || '0');
  const lastEquity = parseFloat(account.data?.lastEquity || '0');
  
  const dayChange = equity - lastEquity;
  const dayChangePercent = lastEquity > 0 ? (dayChange / lastEquity) * 100 : 0;

  // Calculate total P&L from positions
  let totalUnrealizedPL = 0;
  let totalCostBasis = 0;

  if (positions.data) {
    positions.data.forEach(position => {
      const unrealizedPL = parseFloat(position.unrealizedPl || '0');
      const costBasis = parseFloat(position.costBasis || '0');
      totalUnrealizedPL += unrealizedPL;
      totalCostBasis += costBasis;
    });
  }

  const totalReturnPercent = totalCostBasis > 0 ? (totalUnrealizedPL / totalCostBasis) * 100 : 0;

  return {
    isLoading: account.isLoading || positions.isLoading,
    error: account.error || positions.error,
    account: account.data,
    positions: positions.data || [],
    metrics: {
      portfolioValue,
      cash,
      equity,
      dayChange,
      dayChangePercent,
      totalUnrealizedPL,
      totalReturnPercent,
      buyingPower: parseFloat(account.data?.buyingPower || '0'),
    },
    refetch: () => {
      account.refetch();
      positions.refetch();
    },
  };
};