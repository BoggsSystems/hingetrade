import React from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import RecentActivity from '../Dashboard/RecentActivity';

const RecentActivityPanel: React.FC<IPanelComponentProps> = ({
  onReady,
}) => {
  React.useEffect(() => {
    onReady?.();
  }, [onReady]);

  return <RecentActivity />;
};

RecentActivityPanel.displayName = 'Recent Activity';

export default RecentActivityPanel;