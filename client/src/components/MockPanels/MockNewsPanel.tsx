import React, { useEffect } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import './MockPanels.css';

const MockNewsPanel: React.FC<IPanelComponentProps> = ({
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

  const mockNews = [
    {
      time: '10:30 AM',
      headline: `${symbol} Announces Quarterly Earnings Beat`,
      source: 'Reuters',
    },
    {
      time: '9:45 AM',
      headline: 'Market Analysis: Tech Stocks Rally',
      source: 'Bloomberg',
    },
    {
      time: '9:15 AM',
      headline: `Analyst Upgrades ${symbol} to Buy`,
      source: 'CNBC',
    },
    {
      time: '8:30 AM',
      headline: 'Fed Minutes Released, Markets React',
      source: 'WSJ',
    },
  ];

  return (
    <div className="mock-panel mock-news-panel">
      <div className="mock-panel-header">
        <h3>News Panel</h3>
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
        <div className="news-list">
          {mockNews.map((item, idx) => (
            <div key={idx} className="news-item">
              <div className="news-time">{item.time}</div>
              <div className="news-content">
                <div className="news-headline">{item.headline}</div>
                <div className="news-source">{item.source}</div>
              </div>
            </div>
          ))}
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

MockNewsPanel.displayName = 'Mock News Panel';

export default MockNewsPanel;