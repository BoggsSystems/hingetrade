import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAssetSearch, useTopMovers, useAssetsByCategory, useAssetCategories } from '../../hooks';
import styles from './MarketsPage.module.css';

const MarketsPage: React.FC = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [activeCategory, setActiveCategory] = useState('all');

  // Hooks for data fetching
  const { data: categories } = useAssetCategories();
  const { isLoading: searchLoading } = useAssetSearch(searchQuery, searchQuery.length > 2);
  const { data: topMoversData, isLoading: moversLoading } = useTopMovers();
  const { data: categoryAssets, isLoading: categoryLoading } = useAssetsByCategory(activeCategory, searchQuery);

  const topGainers = topMoversData?.gainers || [];
  const topLosers = topMoversData?.losers || [];

  const handleAssetClick = (symbol: string) => {
    navigate(`/trading?symbol=${symbol}`);
  };

  return (
    <div className={styles.markets}>
      <div className={styles.header}>
        <h1>Markets</h1>
        <p className={styles.subtitle}>Explore and discover trading opportunities</p>
      </div>

      <div className={styles.searchSection}>
        <div className={styles.searchBar}>
          <span className={styles.searchIcon}>🔍</span>
          <input
            type="text"
            placeholder="Search stocks, ETFs, crypto..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className={styles.searchInput}
          />
        </div>
      </div>

      <div className={styles.categories}>
        {categories.map((category) => (
          <button
            key={category.id}
            className={`${styles.categoryButton} ${
              activeCategory === category.id ? styles.active : ''
            }`}
            onClick={() => setActiveCategory(category.id)}
          >
            {category.label}
          </button>
        ))}
      </div>

      <div className={styles.marketMovers}>
        <div className={styles.moversSection}>
          <h2>🚀 Top Gainers</h2>
          <div className={styles.moversList}>
            {moversLoading ? (
              <>
                {[1, 2, 3].map((i) => (
                  <div key={i} className={styles.moverItemSkeleton} />
                ))}
              </>
            ) : topGainers.length > 0 ? (
              topGainers.map((stock) => (
                <div 
                  key={stock.symbol} 
                  className={styles.moverItem}
                  onClick={() => handleAssetClick(stock.symbol)}
                >
                  <div className={styles.stockInfo}>
                    <div className={styles.symbol}>{stock.symbol}</div>
                    <div className={styles.name}>{stock.name}</div>
                  </div>
                  <div className={styles.priceInfo}>
                    <div className={styles.price}>${(stock.price || 0).toFixed(2)}</div>
                    <div className={`${styles.change} ${styles.positive}`}>
                      +{Math.abs(stock.changePercent || 0).toFixed(2)}%
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className={styles.emptyState}>No data available</div>
            )}
          </div>
        </div>

        <div className={styles.moversSection}>
          <h2>📉 Top Losers</h2>
          <div className={styles.moversList}>
            {moversLoading ? (
              <>
                {[1, 2, 3].map((i) => (
                  <div key={i} className={styles.moverItemSkeleton} />
                ))}
              </>
            ) : topLosers.length > 0 ? (
              topLosers.map((stock) => (
                <div 
                  key={stock.symbol} 
                  className={styles.moverItem}
                  onClick={() => handleAssetClick(stock.symbol)}
                >
                  <div className={styles.stockInfo}>
                    <div className={styles.symbol}>{stock.symbol}</div>
                    <div className={styles.name}>{stock.name}</div>
                  </div>
                  <div className={styles.priceInfo}>
                    <div className={styles.price}>${(stock.price || 0).toFixed(2)}</div>
                    <div className={`${styles.change} ${styles.negative}`}>
                      {(stock.changePercent || 0).toFixed(2)}%
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className={styles.emptyState}>No data available</div>
            )}
          </div>
        </div>
      </div>

      <div className={styles.allAssets}>
        <h2>{searchQuery ? 'Search Results' : 'Popular Assets'}</h2>
        <div className={styles.assetGrid}>
          {categoryLoading || searchLoading ? (
            <>
              {[1, 2, 3, 4, 5, 6].map((i) => (
                <div key={i} className={styles.assetCardSkeleton} />
              ))}
            </>
          ) : (
            categoryAssets?.map((asset) => (
              <div key={asset.symbol} className={styles.assetCard}>
                <div className={styles.assetHeader}>
                  <span className={styles.assetSymbol}>{asset.symbol}</span>
                  <span className={`badge badge-${asset.class === 'crypto' ? 'crypto' : asset.symbol.includes('ETF') ? 'etf' : 'stocks'}`}>
                    {asset.class === 'crypto' ? 'Crypto' : asset.symbol.includes('ETF') ? 'ETF' : 'Stock'}
                  </span>
                </div>
                <div className={styles.assetName}>{asset.name}</div>
                <div className={styles.assetPrice}>${(asset.price || 0).toFixed(2)}</div>
                <div className={`${styles.assetChange} ${(asset.changePercent || 0) >= 0 ? styles.positive : styles.negative}`}>
                  {(asset.changePercent || 0) >= 0 ? '+' : ''}{(asset.changePercent || 0).toFixed(2)}%
                </div>
                <button 
                  className={styles.tradeButton}
                  onClick={() => handleAssetClick(asset.symbol)}
                >
                  Trade
                </button>
              </div>
            ))
          )}
        </div>
        {!categoryLoading && !searchLoading && categoryAssets?.length === 0 && (
          <div className={styles.noResults}>
            <p>No assets found matching your criteria</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default MarketsPage;