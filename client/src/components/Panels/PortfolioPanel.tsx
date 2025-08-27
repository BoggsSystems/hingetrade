import React from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import { usePortfolio } from '../../hooks';
import './Panels.css';

const PortfolioPanel: React.FC<IPanelComponentProps> = ({
  onReady,
  onError,
}) => {
  const { metrics, isLoading, error } = usePortfolio();

  React.useEffect(() => {
    if (!isLoading) {
      if (error) {
        onError?.(new Error('Failed to load portfolio data'));
      } else {
        onReady?.();
      }
    }
  }, [isLoading, error, onReady, onError]);

  if (isLoading) {
    return (
      <div className="panel-loading">
        <div className="spinner"></div>
        Loading portfolio...
      </div>
    );
  }

  if (error) {
    return (
      <div className="panel-error">
        <p>Unable to load portfolio data</p>
      </div>
    );
  }

  return (
    <div className="portfolio-panel">
      <div className="portfolio-metrics">
        <div className="metric-item">
          <span className="metric-label">Portfolio Value</span>
          <span className="metric-value">${metrics.portfolioValue.toLocaleString()}</span>
        </div>
        <div className="metric-item">
          <span className="metric-label">Day Change</span>
          <span className={`metric-value ${metrics.dayChange >= 0 ? 'positive' : 'negative'}`}>
            ${Math.abs(metrics.dayChange).toLocaleString()} ({metrics.dayChangePercent.toFixed(2)}%)
          </span>
        </div>
        <div className="metric-item">
          <span className="metric-label">Total Return</span>
          <span className={`metric-value ${metrics.totalUnrealizedPL >= 0 ? 'positive' : 'negative'}`}>
            ${Math.abs(metrics.totalUnrealizedPL).toLocaleString()}
          </span>
        </div>
        <div className="metric-item">
          <span className="metric-label">Buying Power</span>
          <span className="metric-value">${metrics.buyingPower.toLocaleString()}</span>
        </div>
      </div>
    </div>
  );
};

PortfolioPanel.displayName = 'Portfolio Overview';

export default PortfolioPanel;