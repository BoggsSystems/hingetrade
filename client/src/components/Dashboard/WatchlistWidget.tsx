import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useDefaultWatchlist, useAssets } from '../../hooks';
import styles from './WatchlistWidget.module.css';

const WatchlistWidget: React.FC = () => {
  const navigate = useNavigate();
  const { watchlist, isLoading: watchlistLoading } = useDefaultWatchlist();
  const symbols = watchlist?.items || [];
  const assetsQueries = useAssets(symbols.slice(0, 5)); // Show only first 5

  const isLoading = watchlistLoading || assetsQueries.some(q => q.isLoading);

  if (isLoading) {
    return (
      <div className={styles.watchlist}>
        {[1, 2, 3, 4, 5].map((i) => (
          <div key={i} className={styles.watchlistItemSkeleton} />
        ))}
      </div>
    );
  }

  const watchlistItems = assetsQueries
    .map(query => query.data)
    .filter((asset): asset is NonNullable<typeof asset> => asset != null)
    .map(asset => ({
      symbol: asset.symbol,
      name: asset.name,
      price: asset.price || 0,
      change: (asset.price || 0) - (asset.price || 0) / (1 + (asset.changePercent || 0) / 100),
      changePercent: asset.changePercent || 0,
    }));

  if (watchlistItems.length === 0) {
    return (
      <div className={styles.watchlist}>
        <div className={styles.emptyState}>
          <p>No items in your watchlist</p>
          <button 
            className={styles.addButton}
            onClick={() => navigate('/markets')}
          >
            Add Symbols
          </button>
        </div>
      </div>
    );
  }
  return (
    <div className={styles.watchlist}>
      {watchlistItems.map((item) => (
        <div key={item.symbol} className={styles.watchlistItem}>
          <div className={styles.symbolInfo}>
            <div className={styles.symbol}>{item.symbol}</div>
            <div className={styles.name}>{item.name}</div>
          </div>
          <div className={styles.priceInfo}>
            <div className={styles.price}>${item.price.toFixed(2)}</div>
            <div
              className={`${styles.change} ${
                item.change >= 0 ? styles.positive : styles.negative
              }`}
            >
              {item.change >= 0 ? '+' : ''}{item.change.toFixed(2)} ({item.changePercent.toFixed(2)}%)
            </div>
          </div>
        </div>
      ))}
      <button 
        className={styles.viewAllButton}
        onClick={() => navigate('/watchlist')}
      >
        View All →
      </button>
    </div>
  );
};

export default WatchlistWidget;