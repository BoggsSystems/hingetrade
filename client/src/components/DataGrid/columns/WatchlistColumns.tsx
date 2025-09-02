import React from 'react';
import type { ColumnDef } from '@tanstack/react-table';
import type { Asset } from '../../../types';
import styles from './WatchlistColumns.module.css';

export interface WatchlistRowData extends Asset {
  change?: number;
  changePercent?: number;
  volume?: number;
  marketCap?: number;
  lastUpdated?: string;
  bid?: number;
  ask?: number;
  dayLow?: number;
  dayHigh?: number;
  fiftyTwoWeekLow?: number;
  fiftyTwoWeekHigh?: number;
  peRatio?: number;
  dividendYield?: number;
  lastTradeTime?: string;
  avgVolume?: number;
  beta?: number;
}

interface ActionButtonsProps {
  symbol: string;
  onTrade?: (symbol: string) => void;
  onChart?: (symbol: string) => void;
  onAlert?: (symbol: string) => void;
  onRemove?: (symbol: string) => void;
}

const ActionButtons: React.FC<ActionButtonsProps> = ({ 
  symbol, 
  onTrade, 
  onChart, 
  onAlert, 
  onRemove 
}) => (
  <div className={styles.actionButtons}>
    <button 
      className={`${styles.actionButton} ${styles.buyButton}`}
      onClick={(e) => { e.stopPropagation(); onTrade?.(symbol); }}
      title="Buy"
    >
      📈 Buy
    </button>
    <button 
      className={`${styles.actionButton} ${styles.sellButton}`}
      onClick={(e) => { e.stopPropagation(); onTrade?.(symbol); }}
      title="Sell"
    >
      📉 Sell
    </button>
    <button 
      className={`${styles.actionButton} ${styles.optionsButton}`}
      onClick={(e) => { e.stopPropagation(); onTrade?.(symbol); }}
      title="Options"
    >
      ⚙️ Options
    </button>
    {onChart && (
      <button 
        className={`${styles.actionButton} ${styles.chartButton}`}
        onClick={(e) => { e.stopPropagation(); onChart(symbol); }}
        title="View Chart"
      >
        📊
      </button>
    )}
    {onAlert && (
      <button 
        className={`${styles.actionButton} ${styles.alertButton}`}
        onClick={(e) => { e.stopPropagation(); onAlert(symbol); }}
        title="Set Alert"
      >
        🔔
      </button>
    )}
    {onRemove && (
      <button 
        className={`${styles.actionButton} ${styles.removeButton}`}
        onClick={(e) => { e.stopPropagation(); onRemove(symbol); }}
        title="Remove from watchlist"
      >
        🗑️
      </button>
    )}
  </div>
);

interface ColumnConfig {
  onTrade?: (symbol: string) => void;
  onChart?: (symbol: string) => void;
  onAlert?: (symbol: string) => void;
  onRemove?: (symbol: string) => void;
  onSymbolClick?: (symbol: string) => void;
}

export const createWatchlistColumns = (config: ColumnConfig = {}): ColumnDef<WatchlistRowData>[] => {
  const { onTrade, onChart, onAlert, onRemove, onSymbolClick } = config;

  return [
    // Selection column (checkbox)
    {
      id: 'select',
      header: ({ table }) => {
        const checkbox = React.useRef<HTMLInputElement>(null);
        React.useEffect(() => {
          if (checkbox.current) {
            checkbox.current.indeterminate = table.getIsSomePageRowsSelected();
          }
        }, [table.getIsSomePageRowsSelected()]);
        
        return (
          <input
            ref={checkbox}
            type="checkbox"
            className={styles.checkbox}
            checked={table.getIsAllPageRowsSelected()}
            onChange={table.getToggleAllPageRowsSelectedHandler()}
          />
        );
      },
      cell: ({ row }) => (
        <input
          type="checkbox"
          className={styles.checkbox}
          checked={row.getIsSelected()}
          onChange={row.getToggleSelectedHandler()}
          onClick={(e) => e.stopPropagation()}
        />
      ),
      enableSorting: false,
      size: 40,
    },
    
    // Symbol column with trend indicator
    {
      id: 'symbol',
      accessorKey: 'symbol',
      header: 'Symbol',
      cell: ({ getValue, row }) => {
        const symbol = getValue() as string;
        const changePercent = row.original.changePercent || 0;
        const trendIcon = changePercent > 0 ? '↗️' : changePercent < 0 ? '↘️' : '↔️';
        
        return (
          <div className={styles.symbolCell}>
            <span 
              className={`${styles.symbol} ${onSymbolClick ? styles.clickable : ''}`}
              onClick={onSymbolClick ? (e) => { e.stopPropagation(); onSymbolClick(symbol); } : undefined}
            >
              {symbol} {trendIcon}
            </span>
          </div>
        );
      },
      size: 100,
    },

    // Company name column
    {
      id: 'name',
      accessorKey: 'name',
      header: 'Company',
      cell: ({ getValue }) => (
        <div className={styles.nameCell}>
          <span className={styles.companyName}>{getValue() as string}</span>
        </div>
      ),
      size: 200,
    },

    // Price column
    {
      id: 'price',
      accessorKey: 'price',
      header: 'Price',
      cell: ({ getValue }) => {
        const price = getValue() as number;
        return (
          <div className={styles.priceCell}>
            <span className={styles.price}>
              ${price ? price.toFixed(2) : '--'}
            </span>
          </div>
        );
      },
      size: 100,
    },

    // Change ($) column
    {
      id: 'change',
      accessorFn: (row) => {
        if (!row.price || !row.changePercent) return 0;
        return row.price * (row.changePercent / 100);
      },
      header: 'Change',
      cell: ({ getValue }) => {
        const change = getValue() as number;
        const isPositive = change > 0;
        const isNegative = change < 0;
        
        return (
          <div className={styles.changeCell}>
            <span className={`${styles.change} ${
              isPositive ? styles.positive : isNegative ? styles.negative : ''
            }`}>
              {change > 0 ? '+' : ''}${change.toFixed(2)}
            </span>
          </div>
        );
      },
      size: 100,
    },

    // Change (%) column
    {
      id: 'changePercent',
      accessorKey: 'changePercent',
      header: '% Change',
      cell: ({ getValue }) => {
        const changePercent = getValue() as number;
        const isPositive = changePercent > 0;
        const isNegative = changePercent < 0;
        const emoji = isPositive ? '📈' : isNegative ? '📉' : '➖';
        
        return (
          <div className={styles.changePercentCell}>
            <span className={`${styles.changePercent} ${
              isPositive ? styles.positive : isNegative ? styles.negative : ''
            }`}>
              {changePercent > 0 ? '+' : ''}{changePercent.toFixed(2)}% {emoji}
            </span>
          </div>
        );
      },
      size: 120,
    },

    // Volume column
    {
      id: 'volume',
      accessorKey: 'volume',
      header: 'Volume',
      cell: ({ getValue }) => {
        const volume = getValue() as number;
        if (!volume) return <span className={styles.noData}>--</span>;
        
        const formatVolume = (vol: number) => {
          if (vol >= 1000000) return `${(vol / 1000000).toFixed(1)}M`;
          if (vol >= 1000) return `${(vol / 1000).toFixed(1)}K`;
          return vol.toString();
        };
        
        return (
          <div className={styles.volumeCell}>
            <span className={styles.volume}>{formatVolume(volume)}</span>
          </div>
        );
      },
      size: 100,
    },

    // Bid/Ask column
    {
      id: 'bidAsk',
      header: 'Bid/Ask',
      cell: ({ row }) => {
        const bid = row.original.bid;
        const ask = row.original.ask;
        const spread = bid && ask ? ((ask - bid) / bid * 100) : null;
        
        return (
          <div className={styles.bidAskCell}>
            <div className={styles.bidAskPrices}>
              <span className={styles.bid}>${bid?.toFixed(2) || '--'}</span>
              <span className={styles.askSeparator}>/</span>
              <span className={styles.ask}>${ask?.toFixed(2) || '--'}</span>
            </div>
            {spread && (
              <div className={styles.spread}>
                <span className={styles.spreadValue}>{spread.toFixed(3)}%</span>
              </div>
            )}
          </div>
        );
      },
      size: 120,
    },

    // Day Range column
    {
      id: 'dayRange',
      header: 'Day Range',
      cell: ({ row }) => {
        const dayLow = row.original.dayLow;
        const dayHigh = row.original.dayHigh;
        const price = row.original.price;
        
        if (!dayLow || !dayHigh) {
          return <span className={styles.noData}>--</span>;
        }
        
        // Calculate position within range for visual indicator
        const rangePosition = price ? ((price - dayLow) / (dayHigh - dayLow)) * 100 : 50;
        
        return (
          <div className={styles.dayRangeCell}>
            <div className={styles.rangeText}>
              ${dayLow.toFixed(2)} - ${dayHigh.toFixed(2)}
            </div>
            <div className={styles.rangeBar}>
              <div 
                className={styles.rangeIndicator}
                style={{ left: `${Math.max(0, Math.min(100, rangePosition))}%` }}
              />
            </div>
          </div>
        );
      },
      size: 140,
    },

    // Volume column (enhanced)
    {
      id: 'volume',
      accessorKey: 'volume',
      header: 'Volume',
      cell: ({ getValue, row }) => {
        const volume = getValue() as number;
        const avgVolume = row.original.avgVolume;
        
        if (!volume) return <span className={styles.noData}>--</span>;
        
        const formatVolume = (vol: number) => {
          if (vol >= 1000000) return `${(vol / 1000000).toFixed(1)}M`;
          if (vol >= 1000) return `${(vol / 1000).toFixed(1)}K`;
          return vol.toString();
        };
        
        // Volume relative to average
        const volumeRatio = avgVolume ? volume / avgVolume : 1;
        const isHighVolume = volumeRatio > 1.5;
        const isLowVolume = volumeRatio < 0.5;
        
        return (
          <div className={styles.volumeCell}>
            <span className={`${styles.volume} ${
              isHighVolume ? styles.highVolume : isLowVolume ? styles.lowVolume : ''
            }`}>
              {formatVolume(volume)}
              {isHighVolume && ' 🔥'}
              {isLowVolume && ' 🐌'}
            </span>
            {avgVolume && (
              <div className={styles.volumeRatio}>
                {(volumeRatio * 100).toFixed(0)}% avg
              </div>
            )}
          </div>
        );
      },
      size: 100,
    },

    // Market Cap column
    {
      id: 'marketCap',
      accessorKey: 'marketCap',
      header: 'Market Cap',
      cell: ({ getValue }) => {
        const marketCap = getValue() as number;
        if (!marketCap) return <span className={styles.noData}>--</span>;
        
        const formatMarketCap = (cap: number) => {
          if (cap >= 1000000000000) return `${(cap / 1000000000000).toFixed(1)}T`;
          if (cap >= 1000000000) return `${(cap / 1000000000).toFixed(1)}B`;
          if (cap >= 1000000) return `${(cap / 1000000).toFixed(1)}M`;
          return cap.toString();
        };
        
        // Market cap categories
        let sizeIndicator = '';
        if (marketCap >= 200000000000) sizeIndicator = ' 🏢'; // Mega cap
        else if (marketCap >= 10000000000) sizeIndicator = ' 🏭'; // Large cap
        else if (marketCap >= 2000000000) sizeIndicator = ' 🏪'; // Mid cap
        else if (marketCap >= 300000000) sizeIndicator = ' 🏬'; // Small cap
        else sizeIndicator = ' 🏠'; // Micro cap
        
        return (
          <div className={styles.marketCapCell}>
            <span className={styles.marketCap}>${formatMarketCap(marketCap)}{sizeIndicator}</span>
          </div>
        );
      },
      size: 120,
    },

    // P/E Ratio column
    {
      id: 'peRatio',
      accessorKey: 'peRatio',
      header: 'P/E',
      cell: ({ getValue }) => {
        const peRatio = getValue() as number;
        if (!peRatio || peRatio <= 0) return <span className={styles.noData}>--</span>;
        
        // P/E evaluation indicators
        let peIndicator = '';
        if (peRatio < 15) peIndicator = ' 💰'; // Value
        else if (peRatio > 30) peIndicator = ' 🚀'; // Growth
        
        return (
          <div className={styles.peRatioCell}>
            <span className={styles.peRatio}>{peRatio.toFixed(1)}{peIndicator}</span>
          </div>
        );
      },
      size: 80,
    },

    // Dividend Yield column
    {
      id: 'dividendYield',
      accessorKey: 'dividendYield',
      header: 'Div Yield',
      cell: ({ getValue }) => {
        const dividendYield = getValue() as number;
        if (!dividendYield || dividendYield <= 0) return <span className={styles.noData}>--</span>;
        
        // Dividend categories
        let divIndicator = '';
        if (dividendYield > 4) divIndicator = ' 💎'; // High yield
        else if (dividendYield > 2) divIndicator = ' 💰'; // Good yield
        
        return (
          <div className={styles.dividendYieldCell}>
            <span className={styles.dividendYield}>{dividendYield.toFixed(2)}%{divIndicator}</span>
          </div>
        );
      },
      size: 90,
    },

    // Beta column
    {
      id: 'beta',
      accessorKey: 'beta',
      header: 'Beta',
      cell: ({ getValue }) => {
        const beta = getValue() as number;
        if (!beta) return <span className={styles.noData}>--</span>;
        
        // Beta risk indicators
        let betaIndicator = '';
        if (beta > 1.5) betaIndicator = ' ⚡'; // High volatility
        else if (beta < 0.5) betaIndicator = ' 🛡️'; // Low volatility
        else if (beta < 0) betaIndicator = ' 🔄'; // Inverse correlation
        
        return (
          <div className={styles.betaCell}>
            <span className={`${styles.beta} ${
              beta > 1.2 ? styles.highBeta : beta < 0.8 ? styles.lowBeta : ''
            }`}>
              {beta.toFixed(2)}{betaIndicator}
            </span>
          </div>
        );
      },
      size: 80,
    },

    // 52-Week Range column
    {
      id: 'fiftyTwoWeekRange',
      header: '52W Range',
      cell: ({ row }) => {
        const low52 = row.original.fiftyTwoWeekLow;
        const high52 = row.original.fiftyTwoWeekHigh;
        const price = row.original.price;
        
        if (!low52 || !high52) {
          return <span className={styles.noData}>--</span>;
        }
        
        // Calculate position within 52-week range
        const rangePosition = price ? ((price - low52) / (high52 - low52)) * 100 : 50;
        let positionIndicator = '';
        if (rangePosition > 80) positionIndicator = ' 🔥'; // Near 52W high
        else if (rangePosition < 20) positionIndicator = ' ❄️'; // Near 52W low
        
        return (
          <div className={styles.fiftyTwoWeekCell}>
            <div className={styles.rangeText}>
              ${low52.toFixed(2)} - ${high52.toFixed(2)}
            </div>
            <div className={styles.rangeBar}>
              <div 
                className={styles.rangeIndicator}
                style={{ left: `${Math.max(0, Math.min(100, rangePosition))}%` }}
              />
            </div>
            <div className={styles.rangePosition}>
              {rangePosition.toFixed(0)}%{positionIndicator}
            </div>
          </div>
        );
      },
      size: 160,
    },

    // Last Trade Time column
    {
      id: 'lastTradeTime',
      accessorKey: 'lastTradeTime',
      header: 'Last Trade',
      cell: ({ getValue }) => {
        const lastTradeTime = getValue() as string;
        if (!lastTradeTime) return <span className={styles.noData}>--</span>;
        
        const formatTradeTime = (timeStr: string) => {
          const date = new Date(timeStr);
          const now = new Date();
          const diffMs = now.getTime() - date.getTime();
          const diffMinutes = Math.floor(diffMs / 60000);
          
          if (diffMinutes < 1) return 'Just now';
          if (diffMinutes < 60) return `${diffMinutes}m ago`;
          if (diffMinutes < 1440) return `${Math.floor(diffMinutes / 60)}h ago`;
          return date.toLocaleDateString();
        };
        
        return (
          <div className={styles.lastTradeCell}>
            <span className={styles.lastTradeTime}>{formatTradeTime(lastTradeTime)}</span>
          </div>
        );
      },
      size: 100,
    },

    // Actions column
    {
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <ActionButtons 
          symbol={row.original.symbol}
          onTrade={onTrade}
          onChart={onChart}
          onAlert={onAlert}
          onRemove={onRemove}
        />
      ),
      enableSorting: false,
      size: 140,
    },
  ];
};

// Preset column configurations for different contexts
export const watchlistPanelColumns: ColumnDef<WatchlistRowData>[] = [
  {
    id: 'symbol',
    accessorKey: 'symbol',
    header: 'Symbol',
    cell: ({ getValue, row }) => {
      const symbol = getValue() as string;
      const changePercent = row.original.changePercent || 0;
      const trendIcon = changePercent > 0 ? '↗️' : changePercent < 0 ? '↘️' : '↔️';
      
      return (
        <div className={styles.compactSymbolCell}>
          <span className={styles.symbol}>{symbol} {trendIcon}</span>
        </div>
      );
    },
  },
  {
    id: 'price',
    accessorKey: 'price',
    header: 'Price',
    cell: ({ getValue }) => (
      <span className={styles.price}>
        ${(getValue() as number)?.toFixed(2) || '--'}
      </span>
    ),
  },
  {
    id: 'changePercent',
    accessorKey: 'changePercent',
    header: 'Change',
    cell: ({ getValue }) => {
      const changePercent = getValue() as number;
      const isPositive = changePercent > 0;
      const isNegative = changePercent < 0;
      const emoji = isPositive ? '📈' : isNegative ? '📉' : '➖';
      
      return (
        <span className={`${styles.changePercent} ${
          isPositive ? styles.positive : isNegative ? styles.negative : ''
        }`}>
          {changePercent > 0 ? '+' : ''}{changePercent.toFixed(2)}% {emoji}
        </span>
      );
    },
  },
];

export default { createWatchlistColumns, watchlistPanelColumns };