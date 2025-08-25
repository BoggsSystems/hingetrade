import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { usePortfolio, usePositions, useOrders } from '../../hooks';
import type { Position } from '../../types';
import styles from './PortfolioPage.module.css';

const PortfolioPage: React.FC = () => {
  const navigate = useNavigate();
  const { metrics, isLoading: portfolioLoading, error: portfolioError, positions: portfolioPositions } = usePortfolio();
  const { data: allPositions, isLoading: positionsLoading } = usePositions();
  const { data: orders, isLoading: ordersLoading } = useOrders();
  
  const [activeTab, setActiveTab] = useState<'positions' | 'orders' | 'history'>('positions');

  const positions = portfolioPositions || allPositions || [];
  const openOrders = orders?.filter(o => ['new', 'partially_filled', 'accepted', 'pending_new'].includes(o.status)) || [];
  const filledOrders = orders?.filter(o => ['filled'].includes(o.status)) || [];
  const cancelledOrders = orders?.filter(o => ['canceled', 'rejected', 'expired'].includes(o.status)) || [];

  const formatCurrency = (value: number | string | null) => {
    if (!value) return '$0.00';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(parseFloat(value.toString()));
  };

  const formatPercent = (value: number | string | null) => {
    if (!value) return '0.00%';
    const num = parseFloat(value.toString());
    return `${num >= 0 ? '+' : ''}${num.toFixed(2)}%`;
  };

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleString();
  };


  const calculatePositionReturn = (position: Position) => {
    const currentValue = parseFloat(position.marketValue?.toString() || '0');
    const costBasis = parseFloat(position.costBasis?.toString() || '0');
    if (costBasis === 0) return 0;
    return ((currentValue - costBasis) / costBasis) * 100;
  };

  const handleTradeClick = (symbol: string) => {
    navigate(`/trading?symbol=${symbol}`);
  };

  if (portfolioLoading || positionsLoading || ordersLoading) {
    return (
      <div className={styles.portfolio}>
        <div className={styles.loadingContainer}>
          <div className={styles.spinner} />
          <p>Loading portfolio data...</p>
        </div>
      </div>
    );
  }

  if (portfolioError) {
    return (
      <div className={styles.portfolio}>
        <div className={styles.error}>
          <h2>Unable to load portfolio</h2>
          <p>Please check your connection and try again.</p>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.portfolio}>
      <div className={styles.header}>
        <h1>Portfolio</h1>
        <div className={styles.summary}>
          <div className={styles.summaryItem}>
            <span className={styles.summaryLabel}>Total Value</span>
            <span className={styles.summaryValue}>{formatCurrency(metrics?.portfolioValue || 0)}</span>
          </div>
          <div className={styles.summaryItem}>
            <span className={styles.summaryLabel}>Day Change</span>
            <span className={`${styles.summaryValue} ${(metrics?.dayChange || 0) >= 0 ? styles.positive : styles.negative}`}>
              {formatCurrency(metrics?.dayChange || 0)} ({formatPercent(metrics?.dayChangePercent || 0)})
            </span>
          </div>
          <div className={styles.summaryItem}>
            <span className={styles.summaryLabel}>Total Return</span>
            <span className={`${styles.summaryValue} ${(metrics?.totalUnrealizedPL || 0) >= 0 ? styles.positive : styles.negative}`}>
              {formatCurrency(metrics?.totalUnrealizedPL || 0)} ({formatPercent(metrics?.totalReturnPercent || 0)})
            </span>
          </div>
          <div className={styles.summaryItem}>
            <span className={styles.summaryLabel}>Buying Power</span>
            <span className={styles.summaryValue}>{formatCurrency(metrics?.buyingPower || 0)}</span>
          </div>
        </div>
      </div>

      <div className={styles.tabs}>
        <button 
          className={`${styles.tab} ${activeTab === 'positions' ? styles.active : ''}`}
          onClick={() => setActiveTab('positions')}
        >
          Positions ({positions.length})
        </button>
        <button 
          className={`${styles.tab} ${activeTab === 'orders' ? styles.active : ''}`}
          onClick={() => setActiveTab('orders')}
        >
          Orders ({openOrders.length})
        </button>
        <button 
          className={`${styles.tab} ${activeTab === 'history' ? styles.active : ''}`}
          onClick={() => setActiveTab('history')}
        >
          History
        </button>
      </div>

      <div className={styles.content}>
        {activeTab === 'positions' && (
          <div className={styles.positionsContainer}>
            {positions.length === 0 ? (
              <div className={styles.emptyState}>
                <h3>No positions yet</h3>
                <p>Start building your portfolio by exploring available assets.</p>
                <button 
                  className={styles.ctaButton}
                  onClick={() => navigate('/markets')}
                >
                  Explore Markets
                </button>
              </div>
            ) : (
              <div className={styles.positionsTable}>
                <div className={styles.tableHeader}>
                  <div className={styles.headerCell}>Asset</div>
                  <div className={styles.headerCell}>Quantity</div>
                  <div className={styles.headerCell}>Avg Cost</div>
                  <div className={styles.headerCell}>Current Price</div>
                  <div className={styles.headerCell}>Market Value</div>
                  <div className={styles.headerCell}>Total Return</div>
                  <div className={styles.headerCell}>Actions</div>
                </div>
                {positions.map((position) => {
                  const positionReturn = calculatePositionReturn(position);
                  return (
                    <div key={position.assetId} className={styles.positionRow}>
                      <div className={styles.assetCell}>
                        <div className={styles.symbol}>{position.symbol}</div>
                        <div className={styles.assetClass}>
                          {position.assetClass === 'crypto' ? 'Crypto' : 'Stock'}
                        </div>
                      </div>
                      <div className={styles.cell}>{position.qty}</div>
                      <div className={styles.cell}>{formatCurrency(position.avgEntryPrice || 0)}</div>
                      <div className={styles.cell}>{formatCurrency(position.currentPrice || 0)}</div>
                      <div className={styles.cell}>{formatCurrency(position.marketValue)}</div>
                      <div className={`${styles.cell} ${positionReturn >= 0 ? styles.positive : styles.negative}`}>
                        {formatCurrency(parseFloat(position.unrealizedPl?.toString() || '0'))}
                        <span className={styles.returnPercent}>
                          ({formatPercent(positionReturn)})
                        </span>
                      </div>
                      <div className={styles.cell}>
                        <button 
                          className={styles.tradeButton}
                          onClick={() => handleTradeClick(position.symbol)}
                        >
                          Trade
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {activeTab === 'orders' && (
          <div className={styles.ordersContainer}>
            {openOrders.length === 0 ? (
              <div className={styles.emptyState}>
                <h3>No open orders</h3>
                <p>Your active orders will appear here.</p>
              </div>
            ) : (
              <div className={styles.ordersTable}>
                <div className={styles.tableHeader}>
                  <div className={styles.headerCell}>Symbol</div>
                  <div className={styles.headerCell}>Type</div>
                  <div className={styles.headerCell}>Side</div>
                  <div className={styles.headerCell}>Quantity</div>
                  <div className={styles.headerCell}>Price</div>
                  <div className={styles.headerCell}>Status</div>
                  <div className={styles.headerCell}>Time</div>
                  <div className={styles.headerCell}>Actions</div>
                </div>
                {openOrders.map((order) => (
                  <div key={order.id} className={styles.orderRow}>
                    <div className={styles.cell}>{order.symbol}</div>
                    <div className={styles.cell}>{order.type}</div>
                    <div className={`${styles.cell} ${order.side === 'buy' ? styles.buyText : styles.sellText}`}>
                      {order.side.toUpperCase()}
                    </div>
                    <div className={styles.cell}>{order.qty}</div>
                    <div className={styles.cell}>
                      {order.type === 'market' ? 'Market' : formatCurrency(order.limitPrice || 0)}
                    </div>
                    <div className={styles.cell}>
                      <span className={styles.statusBadge}>{order.status}</span>
                    </div>
                    <div className={styles.cell}>{formatDate(order.createdAt)}</div>
                    <div className={styles.cell}>
                      <button className={styles.cancelButton}>Cancel</button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'history' && (
          <div className={styles.historyContainer}>
            {filledOrders.length === 0 && cancelledOrders.length === 0 ? (
              <div className={styles.emptyState}>
                <h3>No order history</h3>
                <p>Your completed and cancelled orders will appear here.</p>
              </div>
            ) : (
              <div className={styles.ordersTable}>
                <div className={styles.tableHeader}>
                  <div className={styles.headerCell}>Symbol</div>
                  <div className={styles.headerCell}>Type</div>
                  <div className={styles.headerCell}>Side</div>
                  <div className={styles.headerCell}>Quantity</div>
                  <div className={styles.headerCell}>Price</div>
                  <div className={styles.headerCell}>Status</div>
                  <div className={styles.headerCell}>Time</div>
                </div>
                {[...filledOrders, ...cancelledOrders]
                  .sort((a, b) => new Date(b.createdAt || '').getTime() - new Date(a.createdAt || '').getTime())
                  .map((order) => (
                    <div key={order.id} className={styles.orderRow}>
                      <div className={styles.cell}>{order.symbol}</div>
                      <div className={styles.cell}>{order.type}</div>
                      <div className={`${styles.cell} ${order.side === 'buy' ? styles.buyText : styles.sellText}`}>
                        {order.side.toUpperCase()}
                      </div>
                      <div className={styles.cell}>{order.filledQty || order.qty}</div>
                      <div className={styles.cell}>
                        {order.filledAvgPrice ? formatCurrency(order.filledAvgPrice) : 
                         order.type === 'market' ? 'Market' : formatCurrency(order.limitPrice || 0)}
                      </div>
                      <div className={styles.cell}>
                        <span className={`${styles.statusBadge} ${order.status === 'filled' ? styles.filled : styles.cancelled}`}>
                          {order.status}
                        </span>
                      </div>
                      <div className={styles.cell}>{formatDate(order.filledAt || order.createdAt)}</div>
                    </div>
                  ))
                }
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default PortfolioPage;