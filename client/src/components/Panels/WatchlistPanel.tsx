import React from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import WatchlistWidget from '../Dashboard/WatchlistWidget';

const WatchlistPanel: React.FC<IPanelComponentProps> = ({
  onReady,
}) => {
  React.useEffect(() => {
    onReady?.();
  }, [onReady]);

  return <WatchlistWidget />;
};

WatchlistPanel.displayName = 'Watchlist';

export default WatchlistPanel;