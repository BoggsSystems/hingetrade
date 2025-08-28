import React, { useEffect, useState } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import './MockPanels.css';

const MockTradePanel: React.FC<IPanelComponentProps> = ({
  config,
  symbol = 'AAPL',
  onSymbolChange,
  onReady,
}) => {
  const [orderType, setOrderType] = useState('market');
  const [side, setSide] = useState('buy');
  const [quantity, setQuantity] = useState('100');

  useEffect(() => {
    onReady?.();
  }, [onReady]);

  const handleSymbolChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newSymbol = e.target.value.toUpperCase();
    onSymbolChange?.(newSymbol);
  };

  return (
    <div className="mock-panel mock-trade-panel">
      <div className="mock-panel-content">
        <div className="trade-form">
          <div className="form-group">
            <label>Symbol:</label>
            <input 
              type="text" 
              value={symbol} 
              onChange={handleSymbolChange}
              placeholder="Enter symbol"
            />
          </div>
          
          <div className="form-group">
            <label>Side:</label>
            <select value={side} onChange={(e) => setSide(e.target.value)}>
              <option value="buy">Buy</option>
              <option value="sell">Sell</option>
            </select>
          </div>

          <div className="form-group">
            <label>Order Type:</label>
            <select value={orderType} onChange={(e) => setOrderType(e.target.value)}>
              <option value="market">Market</option>
              <option value="limit">Limit</option>
              <option value="stop">Stop</option>
            </select>
          </div>

          <div className="form-group">
            <label>Quantity:</label>
            <input 
              type="number" 
              value={quantity} 
              onChange={(e) => setQuantity(e.target.value)}
            />
          </div>

          <button className={`trade-button ${side}`}>
            {side === 'buy' ? 'Buy' : 'Sell'} {symbol}
          </button>
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

MockTradePanel.displayName = 'Mock Trade Panel';

export default MockTradePanel;