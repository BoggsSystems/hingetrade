import React, { useState, useEffect } from 'react';
import { useQuote } from '../../store/marketDataStore';
import type { PanelConfig } from '../../types/layout';
import SymbolAutocomplete from '../Common/SymbolAutocomplete';
import './QuotePanel.css';

interface QuotePanelProps {
  id: string;
  config: PanelConfig;
  symbol?: string;
  onSymbolChange?: (symbol: string) => void;
  onConfigChange?: (config: Partial<PanelConfig>) => void;
}

export const QuotePanel: React.FC<QuotePanelProps> = ({ config, symbol: propSymbol, onSymbolChange, onConfigChange }) => {
  const [localSymbol, setLocalSymbol] = useState(config.symbol || '');
  const [isEditing, setIsEditing] = useState(!config.symbol && !propSymbol);
  const [tempSymbol, setTempSymbol] = useState('');
  
  // Use prop symbol if available (for link groups), otherwise use local or config symbol
  const symbol = propSymbol || localSymbol || config.symbol;
  const quote = useQuote(symbol);

  useEffect(() => {
    // Update symbol when prop changes (e.g., from link group)
    if (propSymbol && propSymbol !== localSymbol) {
      setLocalSymbol(propSymbol);
      setIsEditing(false);
    }
  }, [propSymbol]);

  useEffect(() => {
    // Initialize from config.symbol on mount or config changes
    if (config.symbol && config.symbol !== localSymbol && !propSymbol) {
      setLocalSymbol(config.symbol);
      setIsEditing(false);
    }
  }, [config.symbol, propSymbol]);

  const handleSymbolSelect = (newSymbol: string) => {
    setLocalSymbol(newSymbol);
    setIsEditing(false);
    
    // Notify parent of symbol change
    if (onSymbolChange) {
      onSymbolChange(newSymbol);
    }
    
    // Update config if handler provided
    if (onConfigChange) {
      onConfigChange({ symbol: newSymbol });
    }
    
    setTempSymbol('');
  };

  const formatPrice = (price: number | undefined) => {
    if (price === undefined) return '—';
    return price.toFixed(2);
  };

  const formatChange = (change: number | undefined, changePercent: number | undefined) => {
    if (change === undefined || changePercent === undefined) return '—';
    const sign = change >= 0 ? '+' : '';
    return `${sign}${change.toFixed(2)} (${sign}${changePercent.toFixed(2)}%)`;
  };

  const formatVolume = (volume: number | undefined) => {
    if (volume === undefined) return '—';
    if (volume >= 1000000) return `${(volume / 1000000).toFixed(1)}M`;
    if (volume >= 1000) return `${(volume / 1000).toFixed(1)}K`;
    return volume.toString();
  };

  if (isEditing) {
    return (
      <div className="quote-panel quote-panel--editing">
        <div className="quote-panel__header">
          <div className="quote-panel__header-left">
            <SymbolAutocomplete
              mode="populate"
              onSymbolSelect={handleSymbolSelect}
              placeholder="Enter symbol (e.g., AAPL)"
              autoFocus
            />
          </div>
          <div className="quote-panel__header-right">
            <button 
              onClick={() => setIsEditing(false)}
              className="quote-panel__cancel-btn"
              title="Cancel"
            >
              ✕
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (!symbol) {
    return (
      <div className="quote-panel quote-panel--empty">
        <button 
          onClick={() => setIsEditing(true)}
          className="quote-panel__add-symbol-btn"
        >
          + Add Symbol
        </button>
      </div>
    );
  }

  const isPositive = (quote?.change ?? 0) >= 0;

  return (
    <div className={`quote-panel ${isPositive ? 'quote-panel--positive' : 'quote-panel--negative'}`}>
      <div className="quote-panel__header">
        <div className="quote-panel__header-left">
          <h3 className="quote-panel__symbol">{symbol}</h3>
        </div>
        <div className="quote-panel__header-right">
          <button 
            onClick={() => {
              setTempSymbol(symbol);
              setIsEditing(true);
            }}
            className="quote-panel__edit-btn"
            title="Change symbol"
          >
            ✎
          </button>
        </div>
      </div>

      <div className="quote-panel__price-section">
        <div className="quote-panel__price">
          ${formatPrice(quote?.price)}
        </div>
        <div className={`quote-panel__change ${isPositive ? 'quote-panel__change--positive' : 'quote-panel__change--negative'}`}>
          {formatChange(quote?.change, quote?.changePercent)}
        </div>
      </div>

      <div className="quote-panel__details">
        <div className="quote-panel__detail-row">
          <span className="quote-panel__detail-label">Bid</span>
          <span className="quote-panel__detail-value">
            ${formatPrice(quote?.bidPrice)} 
            <span className="quote-panel__detail-size">×{quote?.bidSize?.toFixed(0) || '—'}</span>
          </span>
        </div>
        <div className="quote-panel__detail-row">
          <span className="quote-panel__detail-label">Ask</span>
          <span className="quote-panel__detail-value">
            ${formatPrice(quote?.askPrice)} 
            <span className="quote-panel__detail-size">×{quote?.askSize?.toFixed(0) || '—'}</span>
          </span>
        </div>
        <div className="quote-panel__detail-row">
          <span className="quote-panel__detail-label">Volume</span>
          <span className="quote-panel__detail-value">{formatVolume(quote?.volume)}</span>
        </div>
        <div className="quote-panel__detail-row">
          <span className="quote-panel__detail-label">Day Range</span>
          <span className="quote-panel__detail-value">
            ${formatPrice(quote?.dayLow)} - ${formatPrice(quote?.dayHigh)}
          </span>
        </div>
      </div>

      {quote && (
        <div className="quote-panel__timestamp">
          {new Date(quote.timestamp).toLocaleTimeString()}
        </div>
      )}
    </div>
  );
};

export default QuotePanel;