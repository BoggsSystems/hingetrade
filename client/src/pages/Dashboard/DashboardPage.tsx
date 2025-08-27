import React, { useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import useLayoutStore from '../../store/layoutStore';
import LayoutContainer from '../../components/Layout/LayoutContainer';
import type { Panel } from '../../types/layout';
import styles from './DashboardPage.module.css';

const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const { 
    layouts, 
    activeLayoutId, 
    createLayout, 
    addPanel, 
    setActiveLayout,
    createLinkGroup,
    unsavedChanges,
    saveLayout,
    saveLayoutAs
  } = useLayoutStore();

  // Initialize with default layout on first load
  useEffect(() => {
    if (layouts.length === 0) {
      const layoutId = createLayout('Main Workspace');
      setActiveLayout(layoutId);
      
      // Create default link groups
      createLinkGroup('Primary', '#4CAF50');
      createLinkGroup('Secondary', '#2196F3');
      createLinkGroup('Tertiary', '#FF9800');
      
      // Add default trading panels
      const defaultPanels: Panel[] = [
        {
          id: `panel-${Date.now()}-1`,
          position: { x: 0, y: 0, w: 3, h: 4, minW: 2, minH: 3 },
          config: { type: 'watchlist', title: 'Watchlist' }
        },
        {
          id: `panel-${Date.now()}-2`,
          position: { x: 3, y: 0, w: 6, h: 6, minW: 4, minH: 4 },
          config: { type: 'chart', title: 'Price Chart' }
        },
        {
          id: `panel-${Date.now()}-3`,
          position: { x: 9, y: 0, w: 3, h: 4, minW: 2, minH: 3 },
          config: { type: 'quote', title: 'Quote' }
        },
        {
          id: `panel-${Date.now()}-4`,
          position: { x: 0, y: 4, w: 3, h: 5, minW: 2, minH: 3 },
          config: { type: 'portfolio', title: 'Portfolio Overview' }
        },
        {
          id: `panel-${Date.now()}-5`,
          position: { x: 3, y: 6, w: 6, h: 4, minW: 4, minH: 3 },
          config: { type: 'positions', title: 'Positions' }
        },
        {
          id: `panel-${Date.now()}-6`,
          position: { x: 9, y: 4, w: 3, h: 6, minW: 2, minH: 4 },
          config: { type: 'trade', title: 'Order Entry' }
        },
        {
          id: `panel-${Date.now()}-7`,
          position: { x: 0, y: 9, w: 4, h: 4, minW: 3, minH: 3 },
          config: { type: 'market-overview', title: 'Market Overview' }
        },
        {
          id: `panel-${Date.now()}-8`,
          position: { x: 4, y: 10, w: 4, h: 3, minW: 3, minH: 2 },
          config: { type: 'recent-activity', title: 'Recent Activity' }
        },
        {
          id: `panel-${Date.now()}-9`,
          position: { x: 8, y: 10, w: 4, h: 3, minW: 3, minH: 2 },
          config: { type: 'news', title: 'Market News' }
        },
      ];
      
      defaultPanels.forEach(panel => addPanel(panel));
    }
  }, []);

  const handleCreateLayout = () => {
    const name = prompt('Enter layout name:');
    if (name) {
      const layoutId = createLayout(name);
      setActiveLayout(layoutId);
    }
  };

  const handleSaveLayout = () => {
    if (activeLayoutId) {
      saveLayout();
    }
  };

  const handleSaveLayoutAs = () => {
    const name = prompt('Save layout as:');
    if (name) {
      saveLayoutAs(name);
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
              {layouts.map(layout => (
                <option key={layout.id} value={layout.id}>
                  {layout.name}
                </option>
              ))}
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
    </div>
  );
};

export default DashboardPage;