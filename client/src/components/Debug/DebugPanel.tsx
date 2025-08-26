import React, { useState, useEffect } from 'react';
import { debugLogger } from '../../utils/debugLogger';

const DebugPanel: React.FC = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    const refreshLogs = () => {
      setLogs(debugLogger.getStoredLogs());
    };

    refreshLogs();
    
    // Refresh logs every second
    const interval = setInterval(refreshLogs, 1000);
    
    return () => clearInterval(interval);
  }, []);

  const handleDownload = () => {
    debugLogger.downloadLogs();
  };

  const handleClear = () => {
    debugLogger.clearLogs();
    setLogs([]);
  };

  if (!isOpen) {
    return (
      <div 
        style={{
          position: 'fixed',
          bottom: '20px',
          right: '20px',
          zIndex: 9999,
          backgroundColor: '#333',
          color: 'white',
          padding: '8px 12px',
          borderRadius: '4px',
          cursor: 'pointer',
          fontSize: '12px'
        }}
        onClick={() => setIsOpen(true)}
      >
        Debug Panel ({logs.length} logs)
      </div>
    );
  }

  return (
    <div 
      style={{
        position: 'fixed',
        bottom: '20px',
        right: '20px',
        width: '400px',
        height: '300px',
        backgroundColor: '#1a1a1a',
        color: 'white',
        border: '1px solid #333',
        borderRadius: '4px',
        zIndex: 9999,
        display: 'flex',
        flexDirection: 'column',
        fontSize: '11px'
      }}
    >
      <div 
        style={{
          padding: '8px 12px',
          borderBottom: '1px solid #333',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          backgroundColor: '#333'
        }}
      >
        <span>Debug Logs ({logs.length})</span>
        <div style={{ display: 'flex', gap: '8px' }}>
          <button 
            onClick={handleDownload}
            style={{ fontSize: '10px', padding: '2px 6px' }}
          >
            Download
          </button>
          <button 
            onClick={handleClear}
            style={{ fontSize: '10px', padding: '2px 6px' }}
          >
            Clear
          </button>
          <button 
            onClick={() => setIsOpen(false)}
            style={{ fontSize: '10px', padding: '2px 6px' }}
          >
            ×
          </button>
        </div>
      </div>
      <div 
        style={{
          flex: 1,
          overflow: 'auto',
          padding: '8px',
          fontFamily: 'monospace'
        }}
      >
        {logs.slice(-50).map((log, index) => (
          <div 
            key={index}
            style={{
              marginBottom: '4px',
              color: log.level === 'error' ? '#ff6b6b' : 
                    log.level === 'warn' ? '#feca57' :
                    log.level === 'debug' ? '#54a0ff' : '#5f27cd'
            }}
          >
            <strong>[{new Date(log.timestamp).toLocaleTimeString()}]</strong> {log.message}
            {log.data && (
              <div style={{ marginLeft: '20px', color: '#888', fontSize: '10px' }}>
                {JSON.stringify(log.data, null, 1).substring(0, 200)}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default DebugPanel;