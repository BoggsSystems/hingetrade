import React from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import MarketOverview from '../Dashboard/MarketOverview';

const MarketOverviewPanel: React.FC<IPanelComponentProps> = ({
  onReady,
}) => {
  React.useEffect(() => {
    onReady?.();
  }, [onReady]);

  return <MarketOverview />;
};

MarketOverviewPanel.displayName = 'Market Overview';

export default MarketOverviewPanel;