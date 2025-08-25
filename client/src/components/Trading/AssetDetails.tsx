import React, { useState } from 'react';
import type { Asset } from '../../types';
import styles from './AssetDetails.module.css';

interface AssetDetailsProps {
  symbol: string;
  onSymbolChange: (symbol: string) => void;
  asset?: Asset;
  isLoading: boolean;
}

const AssetDetails: React.FC<AssetDetailsProps> = ({
  symbol,
  onSymbolChange,
  asset,
  isLoading
}) => {
  const [searchInput, setSearchInput] = useState(symbol);

  const handleSymbolSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchInput.trim()) {
      onSymbolChange(searchInput.toUpperCase());
    }
  };

  const formatNumber = (num: number | string | null | undefined) => {
    if (!num) return '0.00';
    return parseFloat(num.toString()).toFixed(2);
  };

  const formatPercent = (num: number | string | null | undefined) => {
    if (!num) return '0.00';
    return parseFloat(num.toString()).toFixed(2);
  };

  return (
    <div className={styles.assetDetails}>
      <form className={styles.symbolSearch} onSubmit={handleSymbolSubmit}>
        <input
          type="text"
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          placeholder="Enter symbol (e.g., AAPL, BTC/USD)"
          className={styles.symbolInput}
        />
        <button type="submit" className={styles.searchButton}>
          Search
        </button>
      </form>

      {isLoading && (
        <div className={styles.loading}>
          <div className={styles.loadingSpinner} />
          <p>Loading asset data...</p>
        </div>
      )}

      {!isLoading && asset && (
        <div className={styles.assetInfo}>
          <div className={styles.header}>
            <div>
              <h2 className={styles.symbol}>{asset.symbol}</h2>
              <p className={styles.name}>{asset.name}</p>
            </div>
            <div className={styles.assetClass}>
              <span className={`badge badge-${asset.class === 'crypto' ? 'crypto' : asset.symbol.includes('ETF') ? 'etf' : 'stocks'}`}>
                {asset.class === 'crypto' ? 'Crypto' : asset.symbol.includes('ETF') ? 'ETF' : 'Stock'}
              </span>
            </div>
          </div>

          <div className={styles.priceSection}>
            <div className={styles.currentPrice}>
              <span className={styles.priceLabel}>Current Price</span>
              <span className={styles.priceValue}>${formatNumber(asset.price)}</span>
            </div>
            <div className={`${styles.priceChange} ${parseFloat(asset.changePercent?.toString() || '0') >= 0 ? styles.positive : styles.negative}`}>
              <span className={styles.changeValue}>
                {parseFloat(asset.changePercent?.toString() || '0') >= 0 ? '+' : ''}
                ${formatNumber(0)}
              </span>
              <span className={styles.changePercent}>
                ({parseFloat(asset.changePercent?.toString() || '0') >= 0 ? '+' : ''}
                {formatPercent(asset.changePercent)}%)
              </span>
            </div>
          </div>

          <div className={styles.statsGrid}>
            <div className={styles.statItem}>
              <span className={styles.statLabel}>Open</span>
              <span className={styles.statValue}>${formatNumber(asset.price)}</span>
            </div>
            <div className={styles.statItem}>
              <span className={styles.statLabel}>High</span>
              <span className={styles.statValue}>${formatNumber(asset.price)}</span>
            </div>
            <div className={styles.statItem}>
              <span className={styles.statLabel}>Low</span>
              <span className={styles.statValue}>${formatNumber(asset.price)}</span>
            </div>
            <div className={styles.statItem}>
              <span className={styles.statLabel}>Volume</span>
              <span className={styles.statValue}>{asset.volume?.toLocaleString() || '0'}</span>
            </div>
          </div>

          <div className={styles.tradingInfo}>
            <div className={styles.infoItem}>
              <span className={styles.infoLabel}>Exchange</span>
              <span className={styles.infoValue}>{asset.exchange || 'N/A'}</span>
            </div>
            <div className={styles.infoItem}>
              <span className={styles.infoLabel}>Tradable</span>
              <span className={styles.infoValue}>
                {asset.tradable ? '✅ Yes' : '❌ No'}
              </span>
            </div>
            <div className={styles.infoItem}>
              <span className={styles.infoLabel}>Fractionable</span>
              <span className={styles.infoValue}>
                {asset.fractionable ? '✅ Yes' : '❌ No'}
              </span>
            </div>
          </div>
        </div>
      )}

      {!isLoading && !asset && symbol && (
        <div className={styles.noAsset}>
          <p>Asset not found</p>
          <p className={styles.hint}>Please check the symbol and try again</p>
        </div>
      )}

      {!isLoading && !asset && !symbol && (
        <div className={styles.noAsset}>
          <p>Enter a symbol to get started</p>
          <p className={styles.hint}>Try AAPL, GOOGL, BTC/USD</p>
        </div>
      )}
    </div>
  );
};

export default AssetDetails;