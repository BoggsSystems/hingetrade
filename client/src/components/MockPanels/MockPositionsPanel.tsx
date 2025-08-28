import React, { useEffect } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import './MockPanels.css';

const MockPositionsPanel: React.FC<IPanelComponentProps> = ({
  config,
  onReady,
}) => {
  useEffect(() => {
    onReady?.();
  }, [onReady]);

  const mockPositions = [
    { symbol: 'AAPL', shares: 100, price: 150.25, pnl: '+$523.00' },
    { symbol: 'GOOGL', shares: 50, price: 2750.00, pnl: '-$125.00' },
    { symbol: 'MSFT', shares: 75, price: 325.50, pnl: '+$1,250.00' },
  ];

  return (
    <div className="mock-panel mock-positions-panel">
      <div className="mock-panel-content">
        <table className="mock-table">
          <thead>
            <tr>
              <th>Symbol</th>
              <th>Shares</th>
              <th>Price</th>
              <th>P&L</th>
            </tr>
          </thead>
          <tbody>
            {mockPositions.map((pos, idx) => (
              <tr key={idx}>
                <td>{pos.symbol}</td>
                <td>{pos.shares}</td>
                <td>${pos.price}</td>
                <td className={pos.pnl.startsWith('+') ? 'positive' : 'negative'}>
                  {pos.pnl}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {config.linkGroup && (
          <div className="link-indicator">
            Linked to: {config.linkGroup}
          </div>
        )}
      </div>
    </div>
  );
};

MockPositionsPanel.displayName = 'Mock Positions Panel';

export default MockPositionsPanel;