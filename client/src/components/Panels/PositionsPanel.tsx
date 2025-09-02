import React, { useState, useEffect } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import { useAuth } from '../../contexts/AuthContext';
import './Panels.css';

interface Position {
  symbol: string;
  qty: number;
  side: 'long' | 'short';
  market_value: number;
  cost_basis: number;
  unrealized_pl: number;
  unrealized_plpc: number;
  current_price: number;
  lastday_price: number;
  change_today: number;
  asset_class: string;
  avg_entry_price: number;
}

const PositionsPanel: React.FC<IPanelComponentProps> = ({
  config,
  symbol,
  onSymbolChange,
  onReady,
}) => {
  const [positions, setPositions] = useState<Position[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { getAccessToken } = useAuth();

  useEffect(() => {
    onReady?.();
  }, [onReady]);

  useEffect(() => {
    fetchPositions();
  }, []);

  const fetchPositions = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const token = await getAccessToken();
      if (!token) {
        throw new Error('No access token available');
      }

      const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:5001/api';
      const response = await fetch(`${apiBaseUrl}/positions`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch positions: ${response.statusText}`);
      }

      const data = await response.json();
      setPositions(data.positions || []);
    } catch (err) {
      console.error('Error fetching positions:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch positions');
      // Fallback to mock data for development
      setPositions(generateMockPositions());
    } finally {
      setIsLoading(false);
    }
  };

  const generateMockPositions = (): Position[] => [
    {
      symbol: 'AAPL',
      qty: 50,
      side: 'long',
      market_value: 9500.00,
      cost_basis: 9000.00,
      unrealized_pl: 500.00,
      unrealized_plpc: 5.56,
      current_price: 190.00,
      lastday_price: 188.50,
      change_today: 1.50,
      asset_class: 'us_equity',
      avg_entry_price: 180.00
    },
    {
      symbol: 'GOOGL',
      qty: 10,
      side: 'long',
      market_value: 2750.00,
      cost_basis: 2800.00,
      unrealized_pl: -50.00,
      unrealized_plpc: -1.79,
      current_price: 275.00,
      lastday_price: 276.20,
      change_today: -1.20,
      asset_class: 'us_equity',
      avg_entry_price: 280.00
    },
    {
      symbol: 'MSFT',
      qty: 25,
      side: 'long',
      market_value: 8750.00,
      cost_basis: 8250.00,
      unrealized_pl: 500.00,
      unrealized_plpc: 6.06,
      current_price: 350.00,
      lastday_price: 348.75,
      change_today: 1.25,
      asset_class: 'us_equity',
      avg_entry_price: 330.00
    },
    {
      symbol: 'TSLA',
      qty: 15,
      side: 'long',
      market_value: 3750.00,
      cost_basis: 4200.00,
      unrealized_pl: -450.00,
      unrealized_plpc: -10.71,
      current_price: 250.00,
      lastday_price: 252.30,
      change_today: -2.30,
      asset_class: 'us_equity',
      avg_entry_price: 280.00
    }
  ];

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2
    }).format(value);
  };

  const formatPercent = (value: number) => {
    return `${value >= 0 ? '+' : ''}${value.toFixed(2)}%`;
  };

  const formatNumber = (value: number, decimals = 0) => {
    return new Intl.NumberFormat('en-US', {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals
    }).format(value);
  };

  const handlePositionClick = (position: Position) => {
    onSymbolChange?.(position.symbol);
  };

  const getTotalValue = () => {
    return positions.reduce((total, pos) => total + pos.market_value, 0);
  };

  const getTotalUnrealizedPL = () => {
    return positions.reduce((total, pos) => total + pos.unrealized_pl, 0);
  };

  const getTotalUnrealizedPLPC = () => {
    const totalCostBasis = positions.reduce((total, pos) => total + pos.cost_basis, 0);
    const totalUnrealized = getTotalUnrealizedPL();
    return totalCostBasis > 0 ? (totalUnrealized / totalCostBasis) * 100 : 0;
  };

  if (isLoading) {
    return (
      <div className="positions-panel">
        <div className="panel-loading">
          <div className="spinner" />
          <span>Loading positions...</span>
        </div>
      </div>
    );
  }

  if (error && positions.length === 0) {
    return (
      <div className="positions-panel">
        <div className="panel-error">
          <p>Failed to load positions</p>
          <button onClick={fetchPositions} className="retry-button">
            Retry
          </button>
        </div>
      </div>
    );
  }

  const totalValue = getTotalValue();
  const totalUnrealizedPL = getTotalUnrealizedPL();
  const totalUnrealizedPLPC = getTotalUnrealizedPLPC();

  return (
    <div className="positions-panel">
      <div className="positions-content">
        {positions.length > 0 && (
          <div className="positions-summary">
            <div className="summary-item">
              <span className="summary-label">Total Value</span>
              <span className="summary-value">{formatCurrency(totalValue)}</span>
            </div>
            <div className="summary-item">
              <span className="summary-label">Total P&L</span>
              <span className={`summary-value ${totalUnrealizedPL >= 0 ? 'positive' : 'negative'}`}>
                {formatCurrency(totalUnrealizedPL)} ({formatPercent(totalUnrealizedPLPC)})
              </span>
            </div>
          </div>
        )}

        <div className="positions-table">
          {positions.length > 0 ? (
            <>
              <div className="table-header">
                <div className="header-cell symbol">Symbol</div>
                <div className="header-cell qty">Qty</div>
                <div className="header-cell price">Price</div>
                <div className="header-cell value">Value</div>
                <div className="header-cell pl">P&L</div>
                <div className="header-cell change">Today</div>
              </div>
              <div className="table-body">
                {positions.map((position) => (
                  <div 
                    key={position.symbol} 
                    className={`table-row ${symbol === position.symbol ? 'selected' : ''}`}
                    onClick={() => handlePositionClick(position)}
                  >
                    <div className="table-cell symbol">
                      <div className="symbol-info">
                        <span className="symbol-name">{position.symbol}</span>
                        <span className="position-side">{position.side}</span>
                      </div>
                    </div>
                    <div className="table-cell qty">
                      {formatNumber(Math.abs(position.qty))}
                    </div>
                    <div className="table-cell price">
                      {formatCurrency(position.current_price)}
                    </div>
                    <div className="table-cell value">
                      {formatCurrency(Math.abs(position.market_value))}
                    </div>
                    <div className={`table-cell pl ${position.unrealized_pl >= 0 ? 'positive' : 'negative'}`}>
                      <div className="pl-info">
                        <span className="pl-amount">{formatCurrency(position.unrealized_pl)}</span>
                        <span className="pl-percent">{formatPercent(position.unrealized_plpc)}</span>
                      </div>
                    </div>
                    <div className={`table-cell change ${position.change_today >= 0 ? 'positive' : 'negative'}`}>
                      {formatCurrency(position.change_today)}
                    </div>
                  </div>
                ))}
              </div>
            </>
          ) : (
            <div className="no-positions">
              <p>No positions found</p>
              <p className="hint">Your open positions will appear here</p>
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

PositionsPanel.displayName = 'Positions Panel';

export default PositionsPanel;