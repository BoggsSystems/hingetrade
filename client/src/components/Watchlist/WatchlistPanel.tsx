import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import DataTable from '../DataGrid/DataTable';
import { createWatchlistColumns, type WatchlistRowData } from '../DataGrid/columns/WatchlistColumns';
import { useDefaultWatchlist, useAssets, useAddToWatchlist, useRemoveFromWatchlist } from '../../hooks';
import type { IPanelComponentProps } from '../../types/panel';
import WatchlistSettings from './WatchlistSettings';
import SymbolAutocomplete from '../Common/SymbolAutocomplete';
import styles from './WatchlistPanel.module.css';

interface WatchlistPanelProps extends IPanelComponentProps {
  maxRows?: number;
}

const WatchlistPanel: React.FC<WatchlistPanelProps> = ({
  config,
  onSymbolChange,
  onReady,
  onConfigChange,
  maxRows = 8,
}) => {
  const navigate = useNavigate();
  const { watchlist, isLoading: watchlistLoading } = useDefaultWatchlist();
  const addToWatchlist = useAddToWatchlist();
  const removeFromWatchlist = useRemoveFromWatchlist();
  
  const [showSettings, setShowSettings] = useState(false);
  const [panelSettings, setPanelSettings] = useState({
    maxRows: maxRows,
    showPerformanceBar: true,
    density: 'normal' as 'compact' | 'normal' | 'comfortable',
    refreshInterval: 5000,
  });
  
  const symbols = watchlist?.items?.slice(0, panelSettings.maxRows) || [];
  const assetsQueries = useAssets(symbols);

  const isLoading = watchlistLoading || assetsQueries.some(q => q.isLoading);

  React.useEffect(() => {
    onReady?.();
  }, [onReady]);

  // Transform data for the grid
  const watchlistData: WatchlistRowData[] = React.useMemo(() => {
    const transformedData = assetsQueries
      .map(query => query.data)
      .filter((asset): asset is NonNullable<typeof asset> => asset != null)
      .map(asset => ({
        ...asset,
        change: asset.price && asset.changePercent 
          ? asset.price * (asset.changePercent / 100) 
          : undefined,
      }));
    
    console.log('🔍 [WatchlistPanel] Transformed data:', transformedData);
    return transformedData;
  }, [assetsQueries]);

  // Debug logging after watchlistData is defined
  console.log('🔍 [WatchlistPanel] symbols:', symbols, 'watchlistData.length:', watchlistData.length);

  const handleRowClick = (row: WatchlistRowData) => {
    if (onSymbolChange) {
      onSymbolChange(row.symbol);
    } else {
      // Default behavior: navigate to trade page
      navigate(`/trade?symbol=${row.symbol}`);
    }
  };

  const handleTrade = (symbol: string) => {
    navigate(`/trade?symbol=${symbol}`);
  };

  const handleChart = (symbol: string) => {
    console.log('Opening chart for:', symbol);
  };

  const handleAlert = (symbol: string) => {
    console.log('Setting alert for:', symbol);
  };

  const handleRemove = async (symbol: string) => {
    if (!watchlist) return;
    
    try {
      await removeFromWatchlist.mutateAsync({
        watchlistId: watchlist.id,
        symbol,
      });
      console.log('✅ [WatchlistPanel] Successfully removed symbol:', symbol);
    } catch (error) {
      console.error('❌ [WatchlistPanel] Failed to remove symbol:', error);
    }
  };

  const columns = React.useMemo(() => 
    createWatchlistColumns({
      onTrade: handleTrade,
      onChart: handleChart,
      onAlert: handleAlert,
      onRemove: handleRemove,
      onSymbolClick: (symbol) => {
        if (onSymbolChange) {
          onSymbolChange(symbol);
        }
      },
    }),
    [onSymbolChange, watchlist]
  );

  const totalSymbols = watchlist?.items?.length || 0;

  return (
    <div className={`${styles.watchlistPanel} ${config.linkGroup ? styles.linked : ''}`}>
      {/* Header */}
      <div className={styles.panelHeader}>
        <div className={styles.headerLeft}>
          <SymbolAutocomplete
            mode="populate"
            onSymbolSelect={async (symbol) => {
              console.log('🏠 [WatchlistPanel] onSymbolSelect called with symbol:', symbol);
              console.log('🏠 [WatchlistPanel] watchlist:', watchlist);
              console.log('🏠 [WatchlistPanel] addToWatchlist:', addToWatchlist);
              
              if (!watchlist) {
                console.error('❌ [WatchlistPanel] No watchlist available');
                return;
              }
              
              try {
                console.log('🏠 [WatchlistPanel] Calling addToWatchlist.mutateAsync...');
                const result = await addToWatchlist.mutateAsync({
                  watchlistId: watchlist.id,
                  symbol,
                });
                console.log('✅ [WatchlistPanel] Symbol added to watchlist successfully, result:', result);
                
                // Optionally update linked panels
                if (onSymbolChange) {
                  console.log('🏠 [WatchlistPanel] Updating linked panels with symbol:', symbol);
                  onSymbolChange(symbol);
                }
              } catch (error) {
                console.error('❌ [WatchlistPanel] Failed to add symbol to watchlist:', error);
                console.error('❌ [WatchlistPanel] Error details:', {
                  message: error.message,
                  response: error.response?.data,
                  status: error.response?.status
                });
              }
            }}
            placeholder="Add symbol..."
          />
        </div>
        
        <div className={styles.headerRight}>
          {config.linkGroup && (
            <div 
              className={styles.linkIndicator}
              style={{ backgroundColor: '#007bff' }}
              title={`Linked group: ${config.linkGroup}`}
            />
          )}
          
          <button 
            className={styles.settingsButton}
            onClick={() => setShowSettings(true)}
            title="Settings"
          >
            ⚙️
          </button>
        </div>
      </div>

      {/* Performance indicator */}
      {panelSettings.showPerformanceBar && !isLoading && watchlistData.length > 0 && (
        <div className={styles.performanceBar}>
          {(() => {
            const totalChange = watchlistData.reduce((sum, item) => {
              return sum + (item.change || 0);
            }, 0);
            const avgChangePercent = watchlistData.reduce((sum, item) => {
              return sum + (item.changePercent || 0);
            }, 0) / watchlistData.length;
            
            const isPositive = totalChange > 0;
            
            return (
              <div className={`${styles.performanceIndicator} ${isPositive ? styles.positive : styles.negative}`}>
                <span className={styles.performanceValue}>
                  {totalChange > 0 ? '+' : ''}${totalChange.toFixed(2)}
                </span>
                <span className={styles.performancePercent}>
                  ({avgChangePercent > 0 ? '+' : ''}{avgChangePercent.toFixed(1)}%)
                </span>
                <span className={styles.performanceIcon}>
                  {isPositive ? '📈' : '📉'}
                </span>
              </div>
            );
          })()}
        </div>
      )}

      {/* Data Grid */}
      <div className={styles.gridContainer}>
        <DataTable
          data={watchlistData}
          columns={columns}
          isLoading={isLoading}
          enableSorting={true}
          enableFiltering={false}
          enableRowSelection={false}
          enablePagination={false}
          density={panelSettings.density}
          onRowClick={handleRowClick}
          className={styles.dataTable}
        />
      </div>



      {/* Empty State */}
      {!isLoading && symbols.length === 0 && (
        <div className={styles.emptyState}>
          <div className={styles.emptyIcon}>📊</div>
          <p className={styles.emptyText}>No symbols tracked</p>
          <p className={styles.emptyHint}>Use the search box above to add symbols</p>
        </div>
      )}

      {/* Settings Modal */}
      <WatchlistSettings
        isOpen={showSettings}
        onClose={() => setShowSettings(false)}
        currentSettings={panelSettings}
        onSave={(newSettings) => {
          setPanelSettings(newSettings);
          if (onConfigChange) {
            onConfigChange({
              settings: {
                maxRows: newSettings.maxRows,
                showPerformanceBar: newSettings.showPerformanceBar,
                density: newSettings.density,
                refreshInterval: newSettings.refreshInterval,
              }
            });
          }
        }}
      />
    </div>
  );
};

WatchlistPanel.displayName = 'Watchlist';

export default WatchlistPanel;