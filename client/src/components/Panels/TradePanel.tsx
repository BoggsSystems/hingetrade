import React, { useEffect, useState } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import type { OrderFormData, OrderType, OrderTimeInForce, Asset, Account } from '../../types';
import SymbolAutocomplete from '../Common/SymbolAutocomplete';
import { useAsset, useAccount, useCreateOrder } from '../../hooks';
import './Panels.css';

const TradePanel: React.FC<IPanelComponentProps> = ({
  config,
  symbol = 'AAPL',
  onSymbolChange,
  onReady,
}) => {
  const [orderData, setOrderData] = useState<OrderFormData>({
    symbol: symbol,
    side: 'buy',
    type: 'market',
    qty: '',
    limitPrice: '',
    stopPrice: '',
    timeInForce: 'day',
    extendedHours: false
  });
  const [showOrderPreview, setShowOrderPreview] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const { data: asset, isLoading: assetLoading } = useAsset(symbol);
  const { data: account } = useAccount();
  const createOrder = useCreateOrder();

  useEffect(() => {
    onReady?.();
  }, [onReady]);

  const handleSymbolChange = (newSymbol: string) => {
    setOrderData(prev => ({ ...prev, symbol: newSymbol }));
    onSymbolChange?.(newSymbol);
  };

  const handleInputChange = (field: keyof OrderFormData, value: any) => {
    setOrderData(prev => ({ ...prev, [field]: value }));
  };

  const calculateOrderValue = () => {
    const qty = parseFloat(orderData.qty || '0') || 0;
    const price = orderData.type === 'limit' 
      ? parseFloat(orderData.limitPrice || '0')
      : (asset?.price ? parseFloat(asset.price.toString()) : 0);
    return qty * price;
  };

  const calculateBuyingPower = () => {
    if (!account) return 0;
    return parseFloat(account.buyingPower?.toString() || '0');
  };

  const handlePreviewOrder = () => {
    setShowOrderPreview(true);
  };

  const handleSubmitOrder = async () => {
    setIsLoading(true);
    try {
      await createOrder.mutateAsync(orderData);
      setShowOrderPreview(false);
      // Reset form or show success message
    } catch (error) {
      console.error('Order submission failed:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const orderValue = calculateOrderValue();
  const buyingPower = calculateBuyingPower();
  const hasInsufficientFunds = orderData.side === 'buy' && orderValue > buyingPower;

  return (
    <div className="trade-panel">
      <div className="trade-panel-content">
        <div className="trade-form">
          <div className="form-group">
            <label>Symbol:</label>
            <SymbolAutocomplete
              onSymbolSelect={handleSymbolChange}
              placeholder="Search symbol..."
              mode="immediate"
              value={symbol}
            />
          </div>
          
          <div className="form-group">
            <div className="side-selector">
              <button
                type="button"
                className={`side-button ${orderData.side === 'buy' ? 'buy active' : 'buy'}`}
                onClick={() => handleInputChange('side', 'buy')}
              >
                Buy
              </button>
              <button
                type="button"
                className={`side-button ${orderData.side === 'sell' ? 'sell active' : 'sell'}`}
                onClick={() => handleInputChange('side', 'sell')}
              >
                Sell
              </button>
            </div>
          </div>

          <div className="form-group">
            <label>Order Type:</label>
            <select 
              value={orderData.type} 
              onChange={(e) => handleInputChange('type', e.target.value as OrderType)}
            >
              <option value="market">Market Order</option>
              <option value="limit">Limit Order</option>
              <option value="stop">Stop Loss</option>
              <option value="stop_limit">Stop Limit</option>
            </select>
          </div>

          <div className="form-group">
            <label>Quantity:</label>
            <input 
              type="number" 
              value={orderData.qty}
              onChange={(e) => handleInputChange('qty', e.target.value)}
              placeholder="0"
              min="0"
              step="0.001"
            />
          </div>

          {(orderData.type === 'limit' || orderData.type === 'stop_limit') && (
            <div className="form-group">
              <label>Limit Price:</label>
              <input
                type="number"
                value={orderData.limitPrice}
                onChange={(e) => handleInputChange('limitPrice', e.target.value)}
                placeholder="0.00"
                min="0"
                step="0.01"
              />
            </div>
          )}

          {(orderData.type === 'stop' || orderData.type === 'stop_limit') && (
            <div className="form-group">
              <label>Stop Price:</label>
              <input
                type="number"
                value={orderData.stopPrice}
                onChange={(e) => handleInputChange('stopPrice', e.target.value)}
                placeholder="0.00"
                min="0"
                step="0.01"
              />
            </div>
          )}

          <div className="form-group">
            <label>Time in Force:</label>
            <select
              value={orderData.timeInForce}
              onChange={(e) => handleInputChange('timeInForce', e.target.value as OrderTimeInForce)}
            >
              <option value="day">Day</option>
              <option value="gtc">Good Till Canceled</option>
              <option value="ioc">Immediate or Cancel</option>
              <option value="fok">Fill or Kill</option>
            </select>
          </div>

          {asset?.class === 'us_equity' && (
            <div className="form-group">
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  checked={orderData.extendedHours}
                  onChange={(e) => handleInputChange('extendedHours', e.target.checked)}
                />
                <span>Extended Hours Trading</span>
              </label>
            </div>
          )}

          <div className="order-summary">
            <div className="summary-row">
              <span>Order Value:</span>
              <span className="summary-value">${orderValue.toFixed(2)}</span>
            </div>
            {orderData.side === 'buy' && (
              <div className="summary-row">
                <span>Buying Power:</span>
                <span className="summary-value">${buyingPower.toFixed(2)}</span>
              </div>
            )}
          </div>

          {hasInsufficientFunds && (
            <div className="error">
              Insufficient buying power for this order
            </div>
          )}

          <button 
            className={`trade-button ${orderData.side}`}
            onClick={handlePreviewOrder}
            disabled={isLoading || !orderData.qty || parseFloat(orderData.qty) <= 0 || hasInsufficientFunds}
          >
            {isLoading ? 'Processing...' : `Preview ${orderData.side === 'buy' ? 'Buy' : 'Sell'} Order`}
          </button>
        </div>
        
        {config.linkGroup && (
          <div className="link-indicator">
            Linked to: {config.linkGroup}
          </div>
        )}
      </div>
    </div>
  );
};

TradePanel.displayName = 'Trade Panel';

export default TradePanel;