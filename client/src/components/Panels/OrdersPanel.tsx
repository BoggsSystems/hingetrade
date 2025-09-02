import React, { useState, useEffect } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import { useAuth } from '../../contexts/AuthContext';
import './Panels.css';

export type OrderStatus = 'new' | 'partially_filled' | 'filled' | 'done_for_day' | 'canceled' | 'expired' | 'replaced' | 'pending_cancel' | 'pending_replace' | 'accepted' | 'pending_new' | 'accepted_for_bidding' | 'stopped' | 'rejected' | 'suspended' | 'calculated';
export type OrderSide = 'buy' | 'sell';
export type OrderType = 'market' | 'limit' | 'stop' | 'stop_limit' | 'trailing_stop';
export type TimeInForce = 'day' | 'gtc' | 'ioc' | 'fok' | 'opg' | 'cls';

export interface Order {
  id: string;
  client_order_id: string;
  created_at: string;
  updated_at: string;
  submitted_at: string;
  filled_at?: string;
  expired_at?: string;
  canceled_at?: string;
  failed_at?: string;
  replaced_at?: string;
  replaced_by?: string;
  replaces?: string;
  asset_id: string;
  symbol: string;
  asset_class: string;
  notional?: string;
  qty: string;
  filled_qty: string;
  filled_avg_price?: string;
  order_class: string;
  order_type: OrderType;
  type: OrderType;
  side: OrderSide;
  time_in_force: TimeInForce;
  limit_price?: string;
  stop_price?: string;
  status: OrderStatus;
  extended_hours: boolean;
  legs?: Order[];
  trail_percent?: string;
  trail_price?: string;
  hwm?: string;
}

const OrdersPanel: React.FC<IPanelComponentProps> = ({
  config,
  symbol,
  onSymbolChange,
  onReady,
}) => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<'all' | 'open' | 'filled' | 'cancelled'>('all');
  const [symbolFilter, setSymbolFilter] = useState<string>('');
  const [sortField, setSortField] = useState<keyof Order>('created_at');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc');
  const { getAccessToken } = useAuth();

  useEffect(() => {
    onReady?.();
  }, [onReady]);

  useEffect(() => {
    fetchOrders();
  }, []);

  useEffect(() => {
    if (symbol) {
      setSymbolFilter(symbol);
    }
  }, [symbol]);

  const fetchOrders = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const token = await getAccessToken();
      if (!token) {
        throw new Error('No access token available');
      }

      const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:5001/api';
      const response = await fetch(`${apiBaseUrl}/orders`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch orders: ${response.statusText}`);
      }

      const data = await response.json();
      setOrders(data.orders || []);
    } catch (err) {
      console.error('Error fetching orders:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch orders');
      // Fallback to mock data for development
      setOrders(generateMockOrders());
    } finally {
      setIsLoading(false);
    }
  };

  const generateMockOrders = (): Order[] => [
    {
      id: '1',
      client_order_id: 'client_1',
      created_at: new Date(Date.now() - 1000 * 60 * 30).toISOString(),
      updated_at: new Date(Date.now() - 1000 * 60 * 25).toISOString(),
      submitted_at: new Date(Date.now() - 1000 * 60 * 30).toISOString(),
      filled_at: new Date(Date.now() - 1000 * 60 * 25).toISOString(),
      asset_id: 'aapl_id',
      symbol: 'AAPL',
      asset_class: 'us_equity',
      qty: '100',
      filled_qty: '100',
      filled_avg_price: '190.25',
      order_class: 'simple',
      order_type: 'market',
      type: 'market',
      side: 'buy',
      time_in_force: 'day',
      status: 'filled',
      extended_hours: false
    },
    {
      id: '2',
      client_order_id: 'client_2',
      created_at: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
      updated_at: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
      submitted_at: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
      asset_id: 'googl_id',
      symbol: 'GOOGL',
      asset_class: 'us_equity',
      qty: '50',
      filled_qty: '25',
      filled_avg_price: '275.50',
      order_class: 'simple',
      order_type: 'limit',
      type: 'limit',
      side: 'buy',
      time_in_force: 'gtc',
      limit_price: '275.00',
      status: 'partially_filled',
      extended_hours: false
    },
    {
      id: '3',
      client_order_id: 'client_3',
      created_at: new Date(Date.now() - 1000 * 60 * 15).toISOString(),
      updated_at: new Date(Date.now() - 1000 * 60 * 15).toISOString(),
      submitted_at: new Date(Date.now() - 1000 * 60 * 15).toISOString(),
      asset_id: 'msft_id',
      symbol: 'MSFT',
      asset_class: 'us_equity',
      qty: '75',
      filled_qty: '0',
      order_class: 'simple',
      order_type: 'limit',
      type: 'limit',
      side: 'sell',
      time_in_force: 'day',
      limit_price: '355.00',
      status: 'new',
      extended_hours: false
    },
    {
      id: '4',
      client_order_id: 'client_4',
      created_at: new Date(Date.now() - 1000 * 60 * 60 * 4).toISOString(),
      updated_at: new Date(Date.now() - 1000 * 60 * 60 * 3).toISOString(),
      submitted_at: new Date(Date.now() - 1000 * 60 * 60 * 4).toISOString(),
      canceled_at: new Date(Date.now() - 1000 * 60 * 60 * 3).toISOString(),
      asset_id: 'tsla_id',
      symbol: 'TSLA',
      asset_class: 'us_equity',
      qty: '30',
      filled_qty: '0',
      order_class: 'simple',
      order_type: 'stop',
      type: 'stop',
      side: 'sell',
      time_in_force: 'gtc',
      stop_price: '240.00',
      status: 'canceled',
      extended_hours: false
    }
  ];

  const cancelOrder = async (orderId: string) => {
    try {
      const token = await getAccessToken();
      if (!token) {
        throw new Error('No access token available');
      }

      const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:5001/api';
      const response = await fetch(`${apiBaseUrl}/orders/${orderId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to cancel order: ${response.statusText}`);
      }

      // Refresh orders after cancellation
      fetchOrders();
    } catch (err) {
      console.error('Error cancelling order:', err);
      // For mock data, just update the order status locally
      setOrders(prev => prev.map(order => 
        order.id === orderId 
          ? { ...order, status: 'canceled' as OrderStatus, canceled_at: new Date().toISOString() }
          : order
      ));
    }
  };

  const getFilteredOrders = () => {
    return orders.filter(order => {
      // Status filter
      const statusMatch = (() => {
        switch (statusFilter) {
          case 'open':
            return ['new', 'partially_filled', 'accepted', 'pending_new'].includes(order.status);
          case 'filled':
            return order.status === 'filled';
          case 'cancelled':
            return ['canceled', 'expired', 'rejected'].includes(order.status);
          default:
            return true;
        }
      })();

      // Symbol filter
      const symbolMatch = !symbolFilter || order.symbol.toLowerCase().includes(symbolFilter.toLowerCase());

      return statusMatch && symbolMatch;
    }).sort((a, b) => {
      const aValue = a[sortField];
      const bValue = b[sortField];
      
      if (aValue === undefined && bValue === undefined) return 0;
      if (aValue === undefined) return 1;
      if (bValue === undefined) return -1;
      
      const result = aValue < bValue ? -1 : aValue > bValue ? 1 : 0;
      return sortDirection === 'asc' ? result : -result;
    });
  };

  const handleSort = (field: keyof Order) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('desc');
    }
  };

  const handleSymbolClick = (orderSymbol: string) => {
    onSymbolChange?.(orderSymbol);
  };

  const formatCurrency = (value?: string) => {
    if (!value) return '--';
    return `$${parseFloat(value).toFixed(2)}`;
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: false 
    });
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const today = new Date();
    const isToday = date.toDateString() === today.toDateString();
    
    if (isToday) {
      return formatTime(dateString);
    }
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getStatusColor = (status: OrderStatus) => {
    switch (status) {
      case 'filled':
        return 'var(--success)';
      case 'partially_filled':
        return 'var(--warning)';
      case 'new':
      case 'accepted':
      case 'pending_new':
        return 'var(--primary)';
      case 'canceled':
      case 'expired':
      case 'rejected':
        return 'var(--error)';
      default:
        return 'var(--text-secondary)';
    }
  };

  const getStatusLabel = (status: OrderStatus) => {
    switch (status) {
      case 'new': return 'Open';
      case 'partially_filled': return 'Partial';
      case 'filled': return 'Filled';
      case 'canceled': return 'Cancelled';
      case 'expired': return 'Expired';
      case 'rejected': return 'Rejected';
      case 'pending_cancel': return 'Cancelling';
      case 'pending_replace': return 'Replacing';
      case 'accepted': return 'Accepted';
      case 'pending_new': return 'Pending';
      default: return status;
    }
  };

  const getFillPercentage = (order: Order) => {
    const qty = parseFloat(order.qty);
    const filledQty = parseFloat(order.filled_qty);
    return qty > 0 ? (filledQty / qty) * 100 : 0;
  };

  const getOrderCounts = () => {
    const filtered = getFilteredOrders();
    return {
      total: filtered.length,
      open: filtered.filter(o => ['new', 'partially_filled', 'accepted', 'pending_new'].includes(o.status)).length,
      filled: filtered.filter(o => o.status === 'filled').length,
      cancelled: filtered.filter(o => ['canceled', 'expired', 'rejected'].includes(o.status)).length
    };
  };

  if (isLoading) {
    return (
      <div className="orders-panel">
        <div className="panel-loading">
          <div className="spinner" />
          <span>Loading orders...</span>
        </div>
      </div>
    );
  }

  if (error && orders.length === 0) {
    return (
      <div className="orders-panel">
        <div className="panel-error">
          <p>Failed to load orders</p>
          <button onClick={fetchOrders} className="retry-button">
            Retry
          </button>
        </div>
      </div>
    );
  }

  const filteredOrders = getFilteredOrders();
  const counts = getOrderCounts();

  return (
    <div className="orders-panel">
      <div className="orders-content">
        {/* Status Filter Tabs */}
        <div className="filter-tabs">
          <button
            className={`filter-tab ${statusFilter === 'all' ? 'active' : ''}`}
            onClick={() => setStatusFilter('all')}
          >
            All ({counts.total})
          </button>
          <button
            className={`filter-tab ${statusFilter === 'open' ? 'active' : ''}`}
            onClick={() => setStatusFilter('open')}
          >
            Open ({counts.open})
          </button>
          <button
            className={`filter-tab ${statusFilter === 'filled' ? 'active' : ''}`}
            onClick={() => setStatusFilter('filled')}
          >
            Filled ({counts.filled})
          </button>
          <button
            className={`filter-tab ${statusFilter === 'cancelled' ? 'active' : ''}`}
            onClick={() => setStatusFilter('cancelled')}
          >
            Cancelled ({counts.cancelled})
          </button>
        </div>

        {/* Symbol Filter */}
        <div className="symbol-filter">
          <input
            type="text"
            placeholder="Filter by symbol..."
            value={symbolFilter}
            onChange={(e) => setSymbolFilter(e.target.value)}
            className="symbol-filter-input"
          />
          {symbolFilter && (
            <button
              onClick={() => setSymbolFilter('')}
              className="clear-symbol-filter"
            >
              ×
            </button>
          )}
        </div>

        {/* Orders Table */}
        <div className="orders-table">
          {filteredOrders.length > 0 ? (
            <>
              <div className="orders-table-header">
                <div className="header-cell time" onClick={() => handleSort('created_at')}>
                  Time {sortField === 'created_at' && (sortDirection === 'asc' ? '↑' : '↓')}
                </div>
                <div className="header-cell symbol" onClick={() => handleSort('symbol')}>
                  Symbol {sortField === 'symbol' && (sortDirection === 'asc' ? '↑' : '↓')}
                </div>
                <div className="header-cell side" onClick={() => handleSort('side')}>
                  Side {sortField === 'side' && (sortDirection === 'asc' ? '↑' : '↓')}
                </div>
                <div className="header-cell quantity" onClick={() => handleSort('qty')}>
                  Qty {sortField === 'qty' && (sortDirection === 'asc' ? '↑' : '↓')}
                </div>
                <div className="header-cell filled">Filled</div>
                <div className="header-cell type" onClick={() => handleSort('order_type')}>
                  Type {sortField === 'order_type' && (sortDirection === 'asc' ? '↑' : '↓')}
                </div>
                <div className="header-cell price">Price</div>
                <div className="header-cell status" onClick={() => handleSort('status')}>
                  Status {sortField === 'status' && (sortDirection === 'asc' ? '↑' : '↓')}
                </div>
                <div className="header-cell actions">Actions</div>
              </div>
              <div className="orders-table-body">
                {filteredOrders.map((order) => {
                  const fillPercentage = getFillPercentage(order);
                  const canCancel = ['new', 'partially_filled', 'accepted', 'pending_new'].includes(order.status);
                  
                  return (
                    <div key={order.id} className="orders-table-row">
                      <div className="table-cell time">
                        {formatDate(order.created_at)}
                      </div>
                      <div 
                        className="table-cell symbol clickable"
                        onClick={() => handleSymbolClick(order.symbol)}
                      >
                        {order.symbol}
                      </div>
                      <div className={`table-cell side ${order.side}`}>
                        {order.side.toUpperCase()}
                      </div>
                      <div className="table-cell quantity">
                        {order.qty}
                      </div>
                      <div className="table-cell filled">
                        <div className="fill-info">
                          <span>{order.filled_qty}</span>
                          {fillPercentage > 0 && (
                            <div className="fill-bar">
                              <div 
                                className="fill-progress" 
                                style={{ width: `${fillPercentage}%` }}
                              />
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="table-cell type">
                        <div className="order-type-info">
                          <span>{order.order_type.replace('_', ' ').toUpperCase()}</span>
                          {order.time_in_force !== 'day' && (
                            <span className="tif">{order.time_in_force.toUpperCase()}</span>
                          )}
                        </div>
                      </div>
                      <div className="table-cell price">
                        {order.limit_price && formatCurrency(order.limit_price)}
                        {order.stop_price && (
                          <div className="stop-price">
                            Stop: {formatCurrency(order.stop_price)}
                          </div>
                        )}
                        {order.filled_avg_price && (
                          <div className="avg-price">
                            Avg: {formatCurrency(order.filled_avg_price)}
                          </div>
                        )}
                      </div>
                      <div className="table-cell status">
                        <span 
                          className="status-badge"
                          style={{ color: getStatusColor(order.status) }}
                        >
                          {getStatusLabel(order.status)}
                        </span>
                      </div>
                      <div className="table-cell actions">
                        {canCancel && (
                          <button
                            onClick={() => cancelOrder(order.id)}
                            className="cancel-button"
                            title="Cancel Order"
                          >
                            Cancel
                          </button>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </>
          ) : (
            <div className="no-orders">
              <p>No orders found</p>
              <p className="hint">
                {statusFilter === 'all' 
                  ? 'Your orders will appear here'
                  : `No ${statusFilter} orders found`
                }
              </p>
            </div>
          )}
        </div>

        {config.linkGroup && (
          <div className="link-indicator">
            Linked to: {config.linkGroup}
          </div>
        )}
      </div>
    </div>
  );
};

OrdersPanel.displayName = 'Orders';

export default OrdersPanel;