import React from 'react';
import type { OrderFormData, OrderType, OrderTimeInForce, Asset, Account } from '../../types';
import styles from './OrderForm.module.css';

interface OrderFormProps {
  orderData: OrderFormData;
  onChange: (data: OrderFormData) => void;
  asset?: Asset;
  account?: Account;
  onPreview: () => void;
  isLoading: boolean;
}

const OrderForm: React.FC<OrderFormProps> = ({
  orderData,
  onChange,
  asset,
  account,
  onPreview,
  isLoading
}) => {
  const handleInputChange = (field: keyof OrderFormData, value: any) => {
    onChange({ ...orderData, [field]: value });
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

  const orderValue = calculateOrderValue();
  const buyingPower = calculateBuyingPower();
  const hasInsufficientFunds = orderData.side === 'buy' && orderValue > buyingPower;

  return (
    <form className={styles.orderForm} onSubmit={(e) => { e.preventDefault(); onPreview(); }}>
      <div className={styles.formSection}>
        <div className={styles.sideSelector}>
          <button
            type="button"
            className={`${styles.sideButton} ${orderData.side === 'buy' ? styles.buy : ''}`}
            onClick={() => handleInputChange('side', 'buy')}
          >
            Buy
          </button>
          <button
            type="button"
            className={`${styles.sideButton} ${orderData.side === 'sell' ? styles.sell : ''}`}
            onClick={() => handleInputChange('side', 'sell')}
          >
            Sell
          </button>
        </div>
      </div>

      <div className={styles.formSection}>
        <label className={styles.label}>Order Type</label>
        <select
          className={styles.select}
          value={orderData.type}
          onChange={(e) => handleInputChange('type', e.target.value as OrderType)}
        >
          <option value="market">Market Order</option>
          <option value="limit">Limit Order</option>
          <option value="stop">Stop Loss</option>
          <option value="stop_limit">Stop Limit</option>
        </select>
      </div>

      <div className={styles.formSection}>
        <label className={styles.label}>Quantity</label>
        <input
          type="number"
          className={styles.input}
          value={orderData.qty}
          onChange={(e) => handleInputChange('qty', e.target.value)}
          placeholder="0"
          min="0"
          step="0.001"
          required
        />
      </div>

      {(orderData.type === 'limit' || orderData.type === 'stop_limit') && (
        <div className={styles.formSection}>
          <label className={styles.label}>Limit Price</label>
          <input
            type="number"
            className={styles.input}
            value={orderData.limitPrice}
            onChange={(e) => handleInputChange('limitPrice', e.target.value)}
            placeholder="0.00"
            min="0"
            step="0.01"
            required
          />
        </div>
      )}

      {(orderData.type === 'stop' || orderData.type === 'stop_limit') && (
        <div className={styles.formSection}>
          <label className={styles.label}>Stop Price</label>
          <input
            type="number"
            className={styles.input}
            value={orderData.stopPrice}
            onChange={(e) => handleInputChange('stopPrice', e.target.value)}
            placeholder="0.00"
            min="0"
            step="0.01"
            required
          />
        </div>
      )}

      <div className={styles.formSection}>
        <label className={styles.label}>Time in Force</label>
        <select
          className={styles.select}
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
        <div className={styles.formSection}>
          <label className={styles.checkboxLabel}>
            <input
              type="checkbox"
              checked={orderData.extendedHours}
              onChange={(e) => handleInputChange('extendedHours', e.target.checked)}
              className={styles.checkbox}
            />
            <span>Extended Hours Trading</span>
          </label>
        </div>
      )}

      <div className={styles.orderSummary}>
        <div className={styles.summaryRow}>
          <span>Order Value</span>
          <span className={styles.summaryValue}>${orderValue.toFixed(2)}</span>
        </div>
        {orderData.side === 'buy' && (
          <div className={styles.summaryRow}>
            <span>Buying Power</span>
            <span className={styles.summaryValue}>${buyingPower.toFixed(2)}</span>
          </div>
        )}
      </div>

      {hasInsufficientFunds && (
        <div className={styles.error}>
          Insufficient buying power for this order
        </div>
      )}

      <button
        type="submit"
        className={`${styles.submitButton} ${orderData.side === 'buy' ? styles.buyButton : styles.sellButton}`}
        disabled={isLoading || !orderData.qty || parseFloat(orderData.qty) <= 0 || hasInsufficientFunds}
      >
        {isLoading ? 'Processing...' : 'Preview Order'}
      </button>
    </form>
  );
};

export default OrderForm;