interface LogEntry {
  timestamp: string;
  level: 'info' | 'warn' | 'error' | 'debug';
  message: string;
  data?: any;
  stack?: string;
}

class DebugLogger {
  private static instance: DebugLogger;
  private readonly storageKey = 'debug_logs';
  private readonly maxLogs = 1000; // Keep only last 1000 logs

  static getInstance(): DebugLogger {
    if (!DebugLogger.instance) {
      DebugLogger.instance = new DebugLogger();
    }
    return DebugLogger.instance;
  }

  private getLogs(): LogEntry[] {
    try {
      const stored = localStorage.getItem(this.storageKey);
      return stored ? JSON.parse(stored) : [];
    } catch {
      return [];
    }
  }

  private saveLogs(logs: LogEntry[]): void {
    try {
      // Keep only the most recent logs
      const trimmed = logs.slice(-this.maxLogs);
      localStorage.setItem(this.storageKey, JSON.stringify(trimmed));
    } catch (error) {
      console.warn('Failed to save debug logs:', error);
    }
  }

  log(level: LogEntry['level'], message: string, data?: any): void {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      data: data ? JSON.parse(JSON.stringify(data)) : undefined,
      stack: level === 'error' ? new Error().stack : undefined
    };

    // Also log to console
    console[level](`[${entry.timestamp}] ${message}`, data || '');

    // Save to localStorage
    const logs = this.getLogs();
    logs.push(entry);
    this.saveLogs(logs);
  }

  info(message: string, data?: any): void {
    this.log('info', message, data);
  }

  warn(message: string, data?: any): void {
    this.log('warn', message, data);
  }

  error(message: string, data?: any): void {
    this.log('error', message, data);
  }

  debug(message: string, data?: any): void {
    this.log('debug', message, data);
  }

  getStoredLogs(): LogEntry[] {
    return this.getLogs();
  }

  exportLogs(): string {
    const logs = this.getLogs();
    return logs.map(log => 
      `[${log.timestamp}] ${log.level.toUpperCase()}: ${log.message}` + 
      (log.data ? ` | Data: ${JSON.stringify(log.data)}` : '') +
      (log.stack ? ` | Stack: ${log.stack}` : '')
    ).join('\n');
  }

  clearLogs(): void {
    localStorage.removeItem(this.storageKey);
  }

  // Download logs as a file
  downloadLogs(): void {
    const logs = this.exportLogs();
    const blob = new Blob([logs], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `debug-logs-${new Date().toISOString().replace(/[:.]/g, '-')}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }
}

// Global debug logger instance
export const debugLogger = DebugLogger.getInstance();

// Add global access for easy debugging in browser console
(window as any).debugLogger = debugLogger;

// Add convenience functions to window for easy console access
(window as any).viewLogs = () => {
  const logs = debugLogger.getStoredLogs();
  console.group('🐛 Debug Logs');
  logs.forEach(log => {
    const style = log.level === 'error' ? 'color: #ff6b6b' : 
                  log.level === 'warn' ? 'color: #feca57' :
                  log.level === 'debug' ? 'color: #54a0ff' : 'color: #5f27cd';
    console.log(`%c[${log.timestamp}] ${log.level.toUpperCase()}: ${log.message}`, style);
    if (log.data) console.log('Data:', log.data);
    if (log.stack) console.log('Stack:', log.stack);
  });
  console.groupEnd();
  console.log('💡 Use downloadLogs() to save logs to file');
  return logs;
};

(window as any).downloadLogs = () => {
  debugLogger.downloadLogs();
  console.log('📁 Logs downloaded!');
};

(window as any).clearLogs = () => {
  debugLogger.clearLogs();
  console.log('🗑️ Logs cleared!');
};