import React, { useEffect } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import './MockPanels.css';

const MockQuotePanel: React.FC<IPanelComponentProps> = ({
  id,
  config,
  symbol = 'AAPL',
  onSymbolChange,
  onReady,
}) => {
  useEffect(() => {
    onReady?.();
  }, [onReady]);

  const handleSymbolChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newSymbol = e.target.value.toUpperCase();
    onSymbolChange?.(newSymbol);
  };

  return (
    <div className="mock-panel mock-quote-panel">
      <div className="mock-panel-header">
        <h3>Quote Panel</h3>
        <span className="panel-id">{id}</span>
      </div>
      <div className="mock-panel-content">
        <div className="symbol-input">
          <label>Symbol:</label>
          <input 
            type="text" 
            value={symbol} 
            onChange={handleSymbolChange}
            placeholder="Enter symbol"
          />
        </div>
        <div className="mock-data">
          <div className="mock-price">${Math.random() * 200}.00</div>
          <div className="mock-change">+{(Math.random() * 5).toFixed(2)}%</div>
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

MockQuotePanel.displayName = 'Mock Quote Panel';

export default MockQuotePanel;