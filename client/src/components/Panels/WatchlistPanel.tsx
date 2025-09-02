import React from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import WatchlistPanelComponent from '../Watchlist/WatchlistPanel';

const WatchlistPanel: React.FC<IPanelComponentProps> = (props) => {
  return <WatchlistPanelComponent {...props} />;
};

WatchlistPanel.displayName = 'Watchlist';

export default WatchlistPanel;