import React, { useEffect } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import './MockPanels.css';

const MockChartPanel: React.FC<IPanelComponentProps> = ({
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
    <div className="mock-panel mock-chart-panel">
      <div className="mock-panel-header">
        <h3>Chart Panel</h3>
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
        <div className="mock-chart-area">
          <div className="chart-placeholder">
            <div className="chart-line"></div>
            <div className="chart-line"></div>
            <div className="chart-line"></div>
            <p>Chart for {symbol}</p>
          </div>
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

MockChartPanel.displayName = 'Mock Chart Panel';

export default MockChartPanel;