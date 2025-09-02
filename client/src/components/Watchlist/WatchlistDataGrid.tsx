import React, { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import DataTable from '../DataGrid/DataTable';
import { createWatchlistColumns, type WatchlistRowData } from '../DataGrid/columns/WatchlistColumns';
import { useDefaultWatchlist, useAssets, useRemoveFromWatchlist } from '../../hooks';
import styles from './WatchlistDataGrid.module.css';

interface WatchlistDataGridProps {
  density?: 'compact' | 'normal' | 'comfortable';
  enableSelection?: boolean;
  enablePagination?: boolean;
  className?: string;
  onSymbolSelect?: (symbol: string) => void;
}

const WatchlistDataGrid: React.FC<WatchlistDataGridProps> = ({
  density = 'normal',
  enableSelection = true,
  enablePagination = false,
  className = '',
  onSymbolSelect,
}) => {
  const navigate = useNavigate();
  const { watchlist, isLoading: watchlistLoading } = useDefaultWatchlist();
  const removeFromWatchlist = useRemoveFromWatchlist();
  
  const [selectedSymbols, setSelectedSymbols] = useState<Record<string, boolean>>({});
  const [filterText, setFilterText] = useState('');

  const symbols = watchlist?.items || [];
  const assetsQueries = useAssets(symbols);

  const isLoading = watchlistLoading || assetsQueries.some(q => q.isLoading);

  // Transform data for the grid
  const watchlistData: WatchlistRowData[] = useMemo(() => {
    return assetsQueries
      .map(query => query.data)
      .filter((asset): asset is NonNullable<typeof asset> => asset != null)
      .map(asset => ({
        ...asset,
        change: asset.price && asset.changePercent 
          ? asset.price * (asset.changePercent / 100) 
          : undefined,
      }))
      .filter(item => {
        if (!filterText) return true;
        const searchTerm = filterText.toLowerCase();
        return (
          item.symbol.toLowerCase().includes(searchTerm) ||
          item.name.toLowerCase().includes(searchTerm)
        );
      });
  }, [assetsQueries, filterText]);

  // Column actions
  const handleTrade = (symbol: string) => {
    navigate(`/trade?symbol=${symbol}`);
  };

  const handleChart = (symbol: string) => {
    // TODO: Open chart panel or navigate to chart page
    console.log('Opening chart for:', symbol);
  };

  const handleAlert = (symbol: string) => {
    // TODO: Open alert creation modal
    console.log('Setting alert for:', symbol);
  };

  const handleRemove = async (symbol: string) => {
    if (!watchlist) return;
    
    try {
      await removeFromWatchlist.mutateAsync({
        watchlistId: watchlist.id,
        symbol,
      });
    } catch (error) {
      console.error('Failed to remove symbol:', error);
    }
  };

  const handleSymbolClick = (symbol: string) => {
    if (onSymbolSelect) {
      onSymbolSelect(symbol);
    } else {
      // Default behavior: navigate to trade page
      handleTrade(symbol);
    }
  };

  const handleRowSelectionChange = (selection: Record<string, boolean>) => {
    setSelectedSymbols(selection);
  };

  const handleBulkRemove = async () => {
    if (!watchlist) return;
    
    const symbolsToRemove = Object.keys(selectedSymbols).filter(key => selectedSymbols[key]);
    
    for (const symbol of symbolsToRemove) {
      try {
        await removeFromWatchlist.mutateAsync({
          watchlistId: watchlist.id,
          symbol,
        });
      } catch (error) {
        console.error(`Failed to remove symbol ${symbol}:`, error);
      }
    }
    
    setSelectedSymbols({});
  };

  const columns = useMemo(() => 
    createWatchlistColumns({
      onTrade: handleTrade,
      onChart: handleChart,
      onAlert: handleAlert,
      onRemove: handleRemove,
      onSymbolClick: handleSymbolClick,
    }),
    [watchlist]
  );

  const selectedCount = Object.values(selectedSymbols).filter(Boolean).length;

  return (
    <div className={`${styles.watchlistDataGrid} ${className}`}>
      {/* Toolbar */}
      <div className={styles.toolbar}>
        <div className={styles.leftSection}>
          <div className={styles.searchContainer}>
            <input
              type="text"
              placeholder="Filter symbols..."
              value={filterText}
              onChange={(e) => setFilterText(e.target.value)}
              className={styles.searchInput}
            />
            <span className={styles.searchIcon}>🔍</span>
          </div>
          
          {watchlist && (
            <div className={styles.watchlistInfo}>
              <span className={styles.watchlistName}>
                📊 {watchlist.name} ({symbols.length} symbols)
              </span>
            </div>
          )}
        </div>

        <div className={styles.rightSection}>
          {selectedCount > 0 && (
            <div className={styles.bulkActions}>
              <span className={styles.selectedCount}>
                {selectedCount} selected
              </span>
              <button 
                className={styles.bulkButton}
                onClick={handleBulkRemove}
                disabled={removeFromWatchlist.isPending}
              >
                🗑️ Remove
              </button>
              <button 
                className={styles.bulkButton}
                onClick={() => {
                  const symbols = Object.keys(selectedSymbols).filter(key => selectedSymbols[key]);
                  navigate(`/compare?symbols=${symbols.join(',')}`);
                }}
              >
                📊 Compare
              </button>
            </div>
          )}
          
          <button 
            className={styles.addButton}
            onClick={() => navigate('/markets')}
          >
            + Add Symbol
          </button>
        </div>
      </div>

      {/* Performance Summary */}
      {!isLoading && watchlistData.length > 0 && (
        <div className={styles.performanceSummary}>
          <div className={styles.summaryCard}>
            <span className={styles.summaryLabel}>Total Value Impact</span>
            <span className={styles.summaryValue}>
              {(() => {
                const totalChange = watchlistData.reduce((sum, item) => {
                  return sum + (item.change || 0);
                }, 0);
                const isPositive = totalChange > 0;
                return (
                  <span className={isPositive ? styles.positive : styles.negative}>
                    {totalChange > 0 ? '+' : ''}${totalChange.toFixed(2)} 
                    {isPositive ? ' 📈' : ' 📉'}
                  </span>
                );
              })()}
            </span>
          </div>
          
          <div className={styles.summaryCard}>
            <span className={styles.summaryLabel}>Gainers</span>
            <span className={styles.summaryValue}>
              {watchlistData.filter(item => (item.changePercent || 0) > 0).length}
            </span>
          </div>
          
          <div className={styles.summaryCard}>
            <span className={styles.summaryLabel}>Losers</span>
            <span className={styles.summaryValue}>
              {watchlistData.filter(item => (item.changePercent || 0) < 0).length}
            </span>
          </div>
        </div>
      )}

      {/* Data Grid */}
      <DataTable
        data={watchlistData}
        columns={columns}
        isLoading={isLoading}
        enableSorting={true}
        enableFiltering={false}
        enableRowSelection={enableSelection}
        enablePagination={enablePagination}
        density={density}
        onRowSelectionChange={handleRowSelectionChange}
        className={styles.dataTable}
      />

      {/* Empty State */}
      {!isLoading && symbols.length === 0 && (
        <div className={styles.emptyState}>
          <div className={styles.emptyIcon}>📊</div>
          <h3>No symbols in your watchlist</h3>
          <p>Start tracking your favorite stocks, ETFs, and crypto</p>
          <button 
            className={styles.primaryButton}
            onClick={() => navigate('/markets')}
          >
            Browse Markets
          </button>
        </div>
      )}
    </div>
  );
};

export default WatchlistDataGrid;