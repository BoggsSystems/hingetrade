import React, { useState, useCallback } from 'react';
import useLayoutStore, { useActiveLayout } from '../../store/layoutStore';
import type { Panel } from '../../types/layout';
import type { IPanelComponentProps } from '../../types/panel';
import {
  MockQuotePanel,
  MockChartPanel,
  MockPositionsPanel,
  MockTradePanel,
  MockNewsPanel,
} from '../MockPanels';
import {
  WatchlistPanel,
  PortfolioPanel,
  MarketOverviewPanel,
  RecentActivityPanel,
} from '../Panels';
import ConfirmModal from '../Common/ConfirmModal';
import './PanelWrapper.css';

interface PanelWrapperProps {
  panel: Panel;
}

// Panel registry mapping panel types to components
const panelComponents: Record<string, React.FC<IPanelComponentProps>> = {
  // Real panels
  watchlist: WatchlistPanel,
  portfolio: PortfolioPanel,
  'market-overview': MarketOverviewPanel,
  'recent-activity': RecentActivityPanel,
  
  // Mock panels (will be replaced with real implementations)
  quote: MockQuotePanel,
  chart: MockChartPanel,
  positions: MockPositionsPanel,
  trade: MockTradePanel,
  news: MockNewsPanel,
};

const PanelWrapper: React.FC<PanelWrapperProps> = ({ panel }) => {
  const { 
    removePanel, 
    updatePanel,
    assignPanelToLinkGroup,
    propagateSymbol
  } = useLayoutStore();
  
  const activeLayout = useActiveLayout();
  
  const [isMinimized, setIsMinimized] = useState(false);
  const [localSymbol, setLocalSymbol] = useState('');
  const [showCloseConfirm, setShowCloseConfirm] = useState(false);

  // Get the linked symbol from the link group if panel is linked
  const linkedSymbol = React.useMemo(() => {
    if (!panel.config.linkGroup || !activeLayout) return localSymbol;
    const linkGroup = activeLayout.linkGroups.find(g => g.id === panel.config.linkGroup);
    return linkGroup?.symbol || localSymbol;
  }, [panel.config.linkGroup, activeLayout, localSymbol]);

  const handleClose = useCallback(() => {
    setShowCloseConfirm(true);
  }, []);

  const handleConfirmClose = useCallback(() => {
    removePanel(panel.id);
    setShowCloseConfirm(false);
  }, [panel.id, removePanel]);

  const handleCancelClose = useCallback(() => {
    setShowCloseConfirm(false);
  }, []);

  const handleMinimize = useCallback(() => {
    setIsMinimized(!isMinimized);
  }, [isMinimized]);

  const handleMaximize = useCallback(() => {
    // TODO: Implement maximize functionality
    console.log('Maximize panel:', panel.id);
  }, [panel.id]);

  const handleLinkToggle = useCallback(() => {
    if (!activeLayout) return;
    
    if (panel.config.linkGroup) {
      // Unlink
      assignPanelToLinkGroup(panel.id, null);
    } else {
      // For now, just link to the first available group or create one
      let groupId = activeLayout.linkGroups[0]?.id;
      if (!groupId) {
        // Create a default link group if none exists
        // const colors = ['#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336', '#00BCD4'];
        // const color = colors[activeLayout.linkGroups.length % colors.length];
        groupId = `group-${Date.now()}`;
        // Note: In a real implementation, we'd call createLinkGroup here
      }
      assignPanelToLinkGroup(panel.id, groupId);
    }
  }, [panel, activeLayout, assignPanelToLinkGroup]);

  const handleSymbolChange = useCallback((newSymbol: string) => {
    if (panel.config.linkGroup && activeLayout) {
      // Propagate to all panels in the same link group
      propagateSymbol(panel.config.linkGroup, newSymbol);
    } else {
      // Just update local symbol
      setLocalSymbol(newSymbol);
    }
  }, [panel.config.linkGroup, activeLayout, propagateSymbol]);

  const handleConfigChange = useCallback((updates: Partial<typeof panel.config>) => {
    updatePanel(panel.id, {
      config: { ...panel.config, ...updates }
    });
  }, [panel, updatePanel]);

  const PanelComponent = panelComponents[panel.config.type];
  
  if (!PanelComponent) {
    return (
      <div className="panel-wrapper panel-error">
        <div className="panel-header">
          <div className="panel-drag-handle">
            <span className="drag-icon">⋮⋮</span>
          </div>
          <span className="panel-title">Unknown Panel Type: {panel.config.type}</span>
          <button onClick={handleClose} className="panel-close">×</button>
        </div>
        <div className="panel-content">
          <p>Panel type "{panel.config.type}" is not registered</p>
        </div>
      </div>
    );
  }

  const linkGroupColor = activeLayout?.linkGroups.find(
    g => g.id === panel.config.linkGroup
  )?.color;

  return (
    <div 
      className={`panel-wrapper ${isMinimized ? 'minimized' : ''}`}
      style={{
        borderColor: linkGroupColor || undefined,
        borderWidth: linkGroupColor ? '2px' : undefined,
      }}
    >
      <div className="panel-header" style={{ backgroundColor: linkGroupColor || undefined }}>
        <div className="panel-drag-handle">
          <span className="drag-icon">⋮⋮</span>
        </div>
        <span className="panel-title">{panel.config.title || PanelComponent.displayName || 'Panel'}</span>
        <div className="panel-controls">
          <button 
            onClick={handleLinkToggle} 
            className={`panel-link ${panel.config.linkGroup ? 'linked' : ''}`}
            title={panel.config.linkGroup ? 'Unlink panel' : 'Link panel'}
          >
            🔗
          </button>
          <button onClick={handleMinimize} className="panel-minimize">
            {isMinimized ? '▢' : '—'}
          </button>
          <button onClick={handleMaximize} className="panel-maximize">□</button>
          <button onClick={handleClose} className="panel-close">×</button>
        </div>
      </div>
      {!isMinimized && (
        <div className="panel-content">
          <PanelComponent
            id={panel.id}
            config={panel.config}
            symbol={linkedSymbol}
            onSymbolChange={handleSymbolChange}
            onConfigChange={handleConfigChange}
          />
        </div>
      )}
      
      <ConfirmModal
        isOpen={showCloseConfirm}
        title="Close Panel"
        message="Are you sure you want to close this panel?"
        confirmText="Close"
        cancelText="Cancel"
        variant="warning"
        onConfirm={handleConfirmClose}
        onCancel={handleCancelClose}
      />
    </div>
  );
};

export default PanelWrapper;