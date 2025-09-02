import React, { useState } from 'react';
import styles from './WatchlistSettings.module.css';

interface WatchlistSettingsProps {
  isOpen: boolean;
  onClose: () => void;
  currentSettings: {
    maxRows: number;
    showPerformanceBar: boolean;
    density: 'compact' | 'normal' | 'comfortable';
    refreshInterval: number;
  };
  onSave: (settings: WatchlistSettingsProps['currentSettings']) => void;
}

const WatchlistSettings: React.FC<WatchlistSettingsProps> = ({
  isOpen,
  onClose,
  currentSettings,
  onSave,
}) => {
  const [settings, setSettings] = useState(currentSettings);

  const handleSave = () => {
    onSave(settings);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className={styles.overlay} onClick={onClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <h3 className={styles.title}>⚙️ Watchlist Settings</h3>
          <button 
            className={styles.closeButton}
            onClick={onClose}
          >
            ✕
          </button>
        </div>

        <div className={styles.content}>
          <div className={styles.settingGroup}>
            <label className={styles.label}>Display Settings</label>
            
            <div className={styles.setting}>
              <label className={styles.settingLabel}>
                Max rows to display:
              </label>
              <select
                value={settings.maxRows}
                onChange={(e) => setSettings(prev => ({ 
                  ...prev, 
                  maxRows: parseInt(e.target.value) 
                }))}
                className={styles.select}
              >
                <option value={5}>5 rows</option>
                <option value={8}>8 rows</option>
                <option value={10}>10 rows</option>
                <option value={15}>15 rows</option>
                <option value={20}>20 rows</option>
              </select>
            </div>

            <div className={styles.setting}>
              <label className={styles.settingLabel}>
                Density:
              </label>
              <select
                value={settings.density}
                onChange={(e) => setSettings(prev => ({ 
                  ...prev, 
                  density: e.target.value as typeof settings.density
                }))}
                className={styles.select}
              >
                <option value="compact">Compact</option>
                <option value="normal">Normal</option>
                <option value="comfortable">Comfortable</option>
              </select>
            </div>

            <div className={styles.setting}>
              <label className={styles.checkboxLabel}>
                <input
                  type="checkbox"
                  checked={settings.showPerformanceBar}
                  onChange={(e) => setSettings(prev => ({ 
                    ...prev, 
                    showPerformanceBar: e.target.checked 
                  }))}
                  className={styles.checkbox}
                />
                Show performance indicator
              </label>
            </div>
          </div>

          <div className={styles.settingGroup}>
            <label className={styles.label}>Data Settings</label>
            
            <div className={styles.setting}>
              <label className={styles.settingLabel}>
                Refresh interval:
              </label>
              <select
                value={settings.refreshInterval}
                onChange={(e) => setSettings(prev => ({ 
                  ...prev, 
                  refreshInterval: parseInt(e.target.value) 
                }))}
                className={styles.select}
              >
                <option value={1000}>1 second</option>
                <option value={5000}>5 seconds</option>
                <option value={10000}>10 seconds</option>
                <option value={30000}>30 seconds</option>
                <option value={60000}>1 minute</option>
              </select>
            </div>
          </div>
        </div>

        <div className={styles.footer}>
          <button 
            className={styles.cancelButton}
            onClick={onClose}
          >
            Cancel
          </button>
          <button 
            className={styles.saveButton}
            onClick={handleSave}
          >
            Save Settings
          </button>
        </div>
      </div>
    </div>
  );
};

export default WatchlistSettings;