import React, { useEffect, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import useLayoutStore from '../../store/layoutStore';
import LayoutContainer from '../../components/Layout/LayoutContainer';
import SaveLayoutModal from '../../components/Common/SaveLayoutModal';
import type { Panel } from '../../types/layout';
import styles from './DashboardPage.module.css';

const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const [showSaveLayoutModal, setShowSaveLayoutModal] = useState(false);
  const [showNewLayoutModal, setShowNewLayoutModal] = useState(false);
  const { 
    layouts, 
    activeLayoutId,
    createLayout, 
    addPanel, 
    setActiveLayout,
    createLinkGroup,
    unsavedChanges,
    saveLayout,
    saveLayoutAs,
    loadLayouts,
    isLoading,
    error
  } = useLayoutStore();

  // Load layouts on mount and when user changes
  useEffect(() => {
    console.log('DashboardPage: useEffect - loading layouts for user:', user?.id);
    if (user?.id) {
      loadLayouts();
    }
    
    return () => {
      console.log('DashboardPage: cleanup - component unmounting');
    };
  }, [user?.id, loadLayouts]);

  // Create default layout if none exist after loading
  useEffect(() => {
    console.log('DashboardPage: createDefaultLayout logic COMMENTED OUT');
    return;
    if (!isLoading && layouts.length === 0) {
      const createDefaultLayout = async () => {
        try {
          const layoutId = await createLayout('Main Workspace');
          setActiveLayout(layoutId);
          
          // Create default link groups
          createLinkGroup('Primary', '#4CAF50');
          createLinkGroup('Secondary', '#2196F3');
          createLinkGroup('Tertiary', '#FF9800');
          
          // Add default trading panels with unique timestamps
          const timestamp = Date.now();
          const defaultPanels: Panel[] = [
            {
              id: `panel-${timestamp}-1`,
              position: { x: 0, y: 0, w: 3, h: 4, minW: 2, minH: 3 },
              config: { type: 'watchlist', title: 'Watchlist' }
            },
            {
              id: `panel-${timestamp}-2`,
              position: { x: 3, y: 0, w: 6, h: 6, minW: 4, minH: 4 },
              config: { type: 'chart', title: 'Price Chart' }
            },
            {
              id: `panel-${timestamp}-3`,
              position: { x: 9, y: 0, w: 3, h: 4, minW: 2, minH: 3 },
              config: { type: 'quote', title: 'Quote' }
            },
            {
              id: `panel-${timestamp}-4`,
              position: { x: 0, y: 4, w: 3, h: 5, minW: 2, minH: 3 },
              config: { type: 'portfolio', title: 'Portfolio Overview' }
            },
            {
              id: `panel-${timestamp}-5`,
              position: { x: 3, y: 6, w: 6, h: 4, minW: 4, minH: 3 },
              config: { type: 'positions', title: 'Positions' }
            },
            {
              id: `panel-${timestamp}-6`,
              position: { x: 9, y: 4, w: 3, h: 6, minW: 2, minH: 4 },
              config: { type: 'trade', title: 'Order Entry' }
            },
            {
              id: `panel-${timestamp}-7`,
              position: { x: 0, y: 9, w: 4, h: 4, minW: 3, minH: 3 },
              config: { type: 'market-overview', title: 'Market Overview' }
            },
            {
              id: `panel-${timestamp}-8`,
              position: { x: 4, y: 10, w: 4, h: 3, minW: 3, minH: 2 },
              config: { type: 'recent-activity', title: 'Recent Activity' }
            },
            {
              id: `panel-${timestamp}-9`,
              position: { x: 8, y: 10, w: 4, h: 3, minW: 3, minH: 2 },
              config: { type: 'news', title: 'Market News' }
            },
          ];
          
          defaultPanels.forEach((panel, index) => {
            setTimeout(() => addPanel(panel), index * 10);
          });
        } catch (error) {
          console.error('Failed to create default layout:', error);
        }
      };
      
      createDefaultLayout();
    }
  }, [isLoading, layouts.length, createLayout, setActiveLayout, createLinkGroup, addPanel]);

  const handleCreateLayout = () => {
    setShowNewLayoutModal(true);
  };

  const handleConfirmNewLayout = async (name: string) => {
    try {
      const layoutId = await createLayout(name);
      setActiveLayout(layoutId);
      setShowNewLayoutModal(false);
    } catch (error) {
      console.error('Failed to create layout:', error);
    }
  };

  const handleSaveLayout = async () => {
    if (activeLayoutId) {
      try {
        await saveLayout();
      } catch (error) {
        console.error('Failed to save layout:', error);
      }
    }
  };

  const handleSaveLayoutAs = () => {
    setShowSaveLayoutModal(true);
  };

  const handleConfirmSaveAs = async (name: string) => {
    try {
      await saveLayoutAs(name);
      setShowSaveLayoutModal(false);
    } catch (error) {
      console.error('Failed to save layout as:', error);
    }
  };

  const handleAddPanel = (type: string) => {
    if (!activeLayoutId) return;
    
    const panelTypeNames: Record<string, string> = {
      'watchlist': 'Watchlist',
      'chart': 'Chart',
      'quote': 'Quote',
      'trade': 'Trade',
      'positions': 'Positions',
      'news': 'News',
      'portfolio': 'Portfolio',
      'market-overview': 'Market Overview',
      'recent-activity': 'Recent Activity'
    };
    
    const newPanel: Panel = {
      id: `panel-${Date.now()}`,
      position: { 
        x: 0, 
        y: 0, 
        w: 4, 
        h: 6, 
        minW: 2, 
        minH: 3 
      },
      config: { 
        type, 
        title: panelTypeNames[type] || type 
      }
    };
    
    addPanel(newPanel);
  };

  // Removed auto-save - now only saves when user clicks Save button

  if (isLoading) {
    return (
      <div className={styles.dashboard}>
        <div className={styles.loadingContainer}>
          <p>Loading layouts...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={styles.dashboard}>
        <div className={styles.errorContainer}>
          <p>Error: {error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.dashboard}>
      <div className={styles.layoutHeader}>
        <div className={styles.welcomeSection}>
          <h1>Welcome back, {user?.username}!</h1>
          <p className={styles.subtitle}>Your Trading Workspace</p>
        </div>
        
        <div className={styles.layoutControls}>
          <div className={styles.layoutSelector}>
            <select 
              value={activeLayoutId || ''} 
              onChange={(e) => setActiveLayout(e.target.value)}
              className={styles.layoutSelect}
            >
              {layouts.length === 0 && (
                <option value="">No layouts</option>
              )}
              {layouts.map(layout => {
                console.log('Layout in dropdown:', layout);
                return (
                  <option key={layout.id} value={layout.id}>
                    {layout.name || 'Unnamed Layout'}
                  </option>
                );
              })}
            </select>
            <button onClick={handleCreateLayout} className={styles.iconButton} title="New Layout">
              +
            </button>
          </div>
          
          <div className={styles.layoutActions}>
            {unsavedChanges && (
              <span className={styles.unsavedIndicator}>●</span>
            )}
            <button onClick={handleSaveLayout} className={styles.actionButton}>
              Save
            </button>
            <button onClick={handleSaveLayoutAs} className={styles.actionButton}>
              Save As
            </button>
          </div>

          <div className={styles.panelAdder}>
            <select 
              onChange={(e) => {
                if (e.target.value) {
                  handleAddPanel(e.target.value);
                  e.target.value = '';
                }
              }}
              className={styles.addPanelSelect}
              defaultValue=""
            >
              <option value="" disabled>Add Panel...</option>
              <option value="watchlist">Watchlist</option>
              <option value="chart">Chart</option>
              <option value="quote">Quote</option>
              <option value="trade">Trade</option>
              <option value="positions">Positions</option>
              <option value="portfolio">Portfolio</option>
              <option value="news">News</option>
              <option value="market-overview">Market Overview</option>
              <option value="recent-activity">Recent Activity</option>
            </select>
          </div>
        </div>
      </div>
      
      <div className={styles.layoutContainer}>
        <LayoutContainer />
      </div>

      <SaveLayoutModal
        isOpen={showSaveLayoutModal}
        title="Save layout as:"
        placeholder="Enter layout name"
        confirmText="OK"
        cancelText="Cancel"
        onConfirm={handleConfirmSaveAs}
        onCancel={() => setShowSaveLayoutModal(false)}
      />

      <SaveLayoutModal
        isOpen={showNewLayoutModal}
        title="Enter layout name:"
        placeholder="New layout name"
        confirmText="OK"
        cancelText="Cancel"
        onConfirm={handleConfirmNewLayout}
        onCancel={() => setShowNewLayoutModal(false)}
      />
    </div>
  );
};

export default DashboardPage;