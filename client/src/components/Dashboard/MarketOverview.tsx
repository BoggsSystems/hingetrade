import React from 'react';
import { useIsMarketOpen, useAssets } from '../../hooks';
import styles from './MarketOverview.module.css';

const MarketOverview: React.FC = () => {
  const { isOpen } = useIsMarketOpen();
  const indexSymbols = ['SPY', 'QQQ', 'DIA', 'IWM'];
  const indexQueries = useAssets(indexSymbols);
  
  const marketStatus = isOpen ? 'Open' : 'Closed';
  
  const marketIndices = indexQueries
    .map((query) => {
      const asset = query.data;
      if (!asset) return null;
      
      const indexNames: Record<string, string> = {
        'SPY': 'S&P 500',
        'QQQ': 'Nasdaq',
        'DIA': 'Dow Jones',
        'IWM': 'Russell 2000'
      };
      
      return {
        name: indexNames[asset.symbol] || asset.symbol,
        value: asset.price || 0,
        change: (asset.price || 0) * (asset.changePercent || 0) / 100,
        changePercent: asset.changePercent || 0,
      };
    })
    .filter((index): index is NonNullable<typeof index> => index !== null);

  const isLoading = indexQueries.some(q => q.isLoading);
  
  return (
    <div className={styles.marketOverview}>
      <div className={styles.marketStatus}>
        <span className={styles.statusLabel}>Market Status:</span>
        <span className={`${styles.status} ${marketStatus === 'Open' ? styles.open : styles.closed}`}>
          {marketStatus}
        </span>
      </div>
      
      <div className={styles.indices}>
        {isLoading ? (
          <>
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className={styles.indexCardSkeleton} />
            ))}
          </>
        ) : (
          marketIndices.map((index) => (
            <div key={index.name} className={styles.indexCard}>
              <div className={styles.indexName}>{index.name}</div>
              <div className={styles.indexValue}>{index.value.toLocaleString()}</div>
              <div
                className={`${styles.indexChange} ${
                  index.change >= 0 ? styles.positive : styles.negative
                }`}
              >
                {index.change >= 0 ? '+' : ''}{index.change.toFixed(2)}
                <span className={styles.changePercent}>
                  ({index.changePercent >= 0 ? '+' : ''}{index.changePercent.toFixed(2)}%)
                </span>
              </div>
            </div>
          ))
        )}
      </div>

      <div className={styles.sectorPerformance}>
        <h4>Top Sectors Today</h4>
        <div className={styles.sectorItem}>
          <span>Technology</span>
          <span className={styles.positive}>+1.25%</span>
        </div>
        <div className={styles.sectorItem}>
          <span>Healthcare</span>
          <span className={styles.positive}>+0.85%</span>
        </div>
        <div className={styles.sectorItem}>
          <span>Financials</span>
          <span className={styles.negative}>-0.42%</span>
        </div>
      </div>
    </div>
  );
};

export default MarketOverview;