import React, { useState, useEffect } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import { useAuth } from '../../contexts/AuthContext';
import './Panels.css';

interface NewsItem {
  id: string;
  headline: string;
  summary: string;
  source: string;
  publishedAt: string;
  url?: string;
  symbols?: string[];
  sentiment?: 'positive' | 'negative' | 'neutral';
}

const NewsPanel: React.FC<IPanelComponentProps> = ({
  config,
  symbol,
  onSymbolChange,
  onReady,
}) => {
  const [news, setNews] = useState<NewsItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { getAccessToken } = useAuth();

  useEffect(() => {
    onReady?.();
  }, [onReady]);

  useEffect(() => {
    fetchNews();
  }, [symbol]);

  const fetchNews = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const token = await getAccessToken();
      if (!token) {
        throw new Error('No access token available');
      }

      const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:5001/api';
      const url = symbol 
        ? `${apiBaseUrl}/news?symbols=${encodeURIComponent(symbol)}`
        : `${apiBaseUrl}/news`;
      
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch news: ${response.statusText}`);
      }

      const data = await response.json();
      setNews(data.news || []);
    } catch (err) {
      console.error('Error fetching news:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch news');
      // Fallback to mock data for development
      setNews(generateMockNews(symbol));
    } finally {
      setIsLoading(false);
    }
  };

  const generateMockNews = (currentSymbol?: string): NewsItem[] => {
    const baseNews = [
      {
        id: '1',
        headline: 'Market Opens Higher on Strong Economic Data',
        summary: 'Markets rallied in early trading following better-than-expected economic indicators.',
        source: 'Financial Times',
        publishedAt: new Date(Date.now() - 1000 * 60 * 30).toISOString(), // 30 minutes ago
        sentiment: 'positive' as const,
        symbols: ['SPY', 'QQQ', 'DIA']
      },
      {
        id: '2',
        headline: 'Federal Reserve Signals Potential Rate Changes',
        summary: 'Fed officials hint at monetary policy adjustments in upcoming meetings.',
        source: 'Reuters',
        publishedAt: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(), // 2 hours ago
        sentiment: 'neutral' as const,
        symbols: ['TLT', 'IEF', 'SHY']
      },
      {
        id: '3',
        headline: 'Tech Sector Shows Mixed Performance',
        summary: 'Technology stocks display varied results amid ongoing market volatility.',
        source: 'MarketWatch',
        publishedAt: new Date(Date.now() - 1000 * 60 * 60 * 4).toISOString(), // 4 hours ago
        sentiment: 'neutral' as const,
        symbols: ['AAPL', 'GOOGL', 'MSFT', 'AMZN']
      }
    ];

    if (currentSymbol) {
      // Add symbol-specific news
      baseNews.unshift({
        id: '0',
        headline: `${currentSymbol} Reports Quarterly Results`,
        summary: `${currentSymbol} releases earnings data showing strong performance across key metrics.`,
        source: 'Bloomberg',
        publishedAt: new Date(Date.now() - 1000 * 60 * 15).toISOString(), // 15 minutes ago
        sentiment: 'positive' as const,
        symbols: [currentSymbol]
      });
    }

    return baseNews;
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    return `${diffDays}d ago`;
  };

  const getSentimentColor = (sentiment?: string) => {
    switch (sentiment) {
      case 'positive': return 'var(--success)';
      case 'negative': return 'var(--error)';
      default: return 'var(--text-secondary)';
    }
  };

  const handleNewsClick = (newsItem: NewsItem) => {
    if (newsItem.url) {
      window.open(newsItem.url, '_blank', 'noopener,noreferrer');
    }
  };

  if (isLoading) {
    return (
      <div className="news-panel">
        <div className="panel-loading">
          <div className="spinner" />
          <span>Loading news...</span>
        </div>
      </div>
    );
  }

  if (error && news.length === 0) {
    return (
      <div className="news-panel">
        <div className="panel-error">
          <p>Failed to load news</p>
          <button onClick={fetchNews} className="retry-button">
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="news-panel">
      <div className="news-content">
        {symbol && (
          <div className="news-filter">
            <span className="filter-label">News for {symbol}</span>
            <button 
              onClick={() => onSymbolChange?.('')} 
              className="clear-filter"
              title="Show all news"
            >
              ×
            </button>
          </div>
        )}
        
        <div className="news-list">
          {news.map((item) => (
            <div 
              key={item.id} 
              className="news-item"
              onClick={() => handleNewsClick(item)}
              style={{ cursor: item.url ? 'pointer' : 'default' }}
            >
              <div className="news-header">
                <div className="news-meta">
                  <span className="news-source">{item.source}</span>
                  <span className="news-time">{formatTime(item.publishedAt)}</span>
                  {item.sentiment && (
                    <span 
                      className="news-sentiment"
                      style={{ color: getSentimentColor(item.sentiment) }}
                    >
                      ●
                    </span>
                  )}
                </div>
              </div>
              <h3 className="news-headline">{item.headline}</h3>
              <p className="news-summary">{item.summary}</p>
              {item.symbols && item.symbols.length > 0 && (
                <div className="news-symbols">
                  {item.symbols.slice(0, 3).map((sym) => (
                    <span key={sym} className="symbol-tag">{sym}</span>
                  ))}
                  {item.symbols.length > 3 && (
                    <span className="symbol-tag">+{item.symbols.length - 3}</span>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>

        {news.length === 0 && (
          <div className="no-news">
            <p>No news available</p>
            <p className="hint">
              {symbol ? `No recent news for ${symbol}` : 'No recent market news'}
            </p>
          </div>
        )}

        {config.linkGroup && (
          <div className="link-indicator">
            Linked to: {config.linkGroup}
          </div>
        )}
      </div>
    </div>
  );
};

NewsPanel.displayName = 'News Panel';

export default NewsPanel;