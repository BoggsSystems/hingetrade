import React from 'react';
import type { OrderFormData, Asset } from '../../types';
import styles from './OrderPreview.module.css';

interface OrderPreviewProps {
  orderData: OrderFormData;
  asset?: Asset;
  onConfirm: () => void;
  onCancel: () => void;
  isLoading: boolean;
}

const OrderPreview: React.FC<OrderPreviewProps> = ({
  orderData,
  asset,
  onConfirm,
  onCancel,
  isLoading
}) => {
  const calculateOrderValue = () => {
    const qty = parseFloat(orderData.qty || '0') || 0;
    const price = orderData.type === 'limit' 
      ? parseFloat(orderData.limitPrice || '0')
      : (asset?.price ? parseFloat(asset.price.toString()) : 0);
    return qty * price;
  };

  const getOrderTypeDescription = () => {
    switch (orderData.type) {
      case 'market':
        return 'Market Order - Execute immediately at current market price';
      case 'limit':
        return `Limit Order - Execute at $${orderData.limitPrice} or better`;
      case 'stop':
        return `Stop Loss - Trigger market order when price reaches $${orderData.stopPrice}`;
      case 'stop_limit':
        return `Stop Limit - Trigger limit order at $${orderData.limitPrice} when price reaches $${orderData.stopPrice}`;
      default:
        return '';
    }
  };

  const getTimeInForceDescription = () => {
    switch (orderData.timeInForce) {
      case 'day':
        return 'Valid for current trading day';
      case 'gtc':
        return 'Good until canceled';
      case 'ioc':
        return 'Immediate or cancel';
      case 'fok':
        return 'Fill or kill';
      default:
        return '';
    }
  };

  const formatNumber = (num: number) => {
    return num.toFixed(2);
  };

  const orderValue = calculateOrderValue();

  return (
    <div className={styles.overlay}>
      <div className={styles.modal}>
        <h2 className={styles.title}>Review Order</h2>
        
        <div className={styles.orderSummary}>
          <div className={styles.assetInfo}>
            <h3>{asset?.symbol}</h3>
            <p className={styles.assetName}>{asset?.name}</p>
          </div>

          <div className={`${styles.sideIndicator} ${orderData.side === 'buy' ? styles.buy : styles.sell}`}>
            {orderData.side === 'buy' ? 'BUY' : 'SELL'}
          </div>
        </div>

        <div className={styles.orderDetails}>
          <div className={styles.detailRow}>
            <span className={styles.detailLabel}>Order Type</span>
            <div className={styles.detailValue}>
              <strong>{orderData.type.toUpperCase()}</strong>
              <p className={styles.description}>{getOrderTypeDescription()}</p>
            </div>
          </div>

          <div className={styles.detailRow}>
            <span className={styles.detailLabel}>Quantity</span>
            <span className={styles.detailValue}>{orderData.qty}</span>
          </div>

          {orderData.type === 'market' && (
            <div className={styles.detailRow}>
              <span className={styles.detailLabel}>Estimated Price</span>
              <span className={styles.detailValue}>${formatNumber(asset?.price ? parseFloat(asset.price.toString()) : 0)}</span>
            </div>
          )}

          {(orderData.type === 'limit' || orderData.type === 'stop_limit') && (
            <div className={styles.detailRow}>
              <span className={styles.detailLabel}>Limit Price</span>
              <span className={styles.detailValue}>${orderData.limitPrice}</span>
            </div>
          )}

          {(orderData.type === 'stop' || orderData.type === 'stop_limit') && (
            <div className={styles.detailRow}>
              <span className={styles.detailLabel}>Stop Price</span>
              <span className={styles.detailValue}>${orderData.stopPrice}</span>
            </div>
          )}

          <div className={styles.detailRow}>
            <span className={styles.detailLabel}>Time in Force</span>
            <div className={styles.detailValue}>
              <strong>{orderData.timeInForce.toUpperCase()}</strong>
              <p className={styles.description}>{getTimeInForceDescription()}</p>
            </div>
          </div>

          {orderData.extendedHours && (
            <div className={styles.detailRow}>
              <span className={styles.detailLabel}>Extended Hours</span>
              <span className={styles.detailValue}>Enabled</span>
            </div>
          )}

          <div className={styles.totalRow}>
            <span className={styles.detailLabel}>Estimated Total</span>
            <span className={styles.totalValue}>${formatNumber(orderValue)}</span>
          </div>
        </div>

        <div className={styles.disclaimer}>
          <p>By placing this order, you agree to the terms and conditions.</p>
          {orderData.type === 'market' && (
            <p className={styles.warning}>
              Note: Market orders may execute at a different price than shown.
            </p>
          )}
        </div>

        <div className={styles.actions}>
          <button 
            className={styles.cancelButton} 
            onClick={onCancel}
            disabled={isLoading}
          >
            Cancel
          </button>
          <button 
            className={`${styles.confirmButton} ${orderData.side === 'buy' ? styles.buyButton : styles.sellButton}`}
            onClick={onConfirm}
            disabled={isLoading}
          >
            {isLoading ? 'Processing...' : `Confirm ${orderData.side === 'buy' ? 'Buy' : 'Sell'}`}
          </button>
        </div>
      </div>
    </div>
  );
};

export default OrderPreview;