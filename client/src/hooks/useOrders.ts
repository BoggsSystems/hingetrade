import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import apiClient from '../services/api';
import type { Order, OrderFormData } from '../types';

// Hook to get orders
export const useOrders = (status?: string) => {
  return useQuery<Order[]>({
    queryKey: ['orders', status],
    queryFn: () => apiClient.getOrders(status),
    staleTime: 10 * 1000, // Consider data fresh for 10 seconds
    refetchInterval: 30 * 1000, // Refresh every 30 seconds
  });
};

// Hook to create a new order
export const useCreateOrder = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (orderData: OrderFormData) => apiClient.createOrder(orderData),
    onSuccess: () => {
      // Invalidate and refetch orders and positions
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      queryClient.invalidateQueries({ queryKey: ['positions'] });
      queryClient.invalidateQueries({ queryKey: ['account'] });
    },
  });
};

// Hook to cancel an order
export const useCancelOrder = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (orderId: string) => apiClient.cancelOrder(orderId),
    onSuccess: () => {
      // Invalidate and refetch orders
      queryClient.invalidateQueries({ queryKey: ['orders'] });
    },
  });
};

// Hook to get recent activity (orders and trades)
export const useRecentActivity = () => {
  const { data: orders, isLoading, error } = useOrders();

  // Transform orders into activity items
  const activities = orders?.map(order => ({
    id: order.id,
    type: order.side as 'buy' | 'sell',
    symbol: order.symbol,
    description: `${order.side === 'buy' ? 'Bought' : 'Sold'} ${order.filledQty || order.qty} shares of ${order.symbol}`,
    amount: order.side === 'buy' 
      ? -parseFloat(order.filledQty || order.qty || '0') * parseFloat(order.filledAvgPrice || order.limitPrice || '0')
      : parseFloat(order.filledQty || order.qty || '0') * parseFloat(order.filledAvgPrice || order.limitPrice || '0'),
    timestamp: order.filledAt || order.submittedAt || order.createdAt,
    status: order.status,
  })).filter(activity => ['filled', 'partially_filled'].includes(activity.status))
    .slice(0, 10); // Get last 10 activities

  return {
    activities: activities || [],
    isLoading,
    error,
  };
};

// Hook to calculate order preview (commission, total cost, etc.)
export const useOrderPreview = (orderData: Partial<OrderFormData>) => {
  const { data: asset } = useAsset(orderData.symbol || '');
  
  const qty = parseFloat(orderData.qty || '0');
  const price = orderData.type === 'market' 
    ? asset?.price || 0
    : parseFloat(orderData.limitPrice || '0');

  const subtotal = qty * price;
  const commission = 0; // Alpaca has zero commission
  const total = subtotal + commission;

  return {
    price,
    subtotal,
    commission,
    total,
    isValid: qty > 0 && price > 0,
  };
};

// Import useAsset from market data hooks
import { useAsset } from './useMarketData';