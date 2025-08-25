import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useAsset, useCreateOrder, useAccount } from '../../hooks';
import type { OrderFormData, OrderSide, OrderType, OrderTimeInForce } from '../../types';
import OrderForm from '../../components/Trading/OrderForm';
import AssetDetails from '../../components/Trading/AssetDetails';
import OrderPreview from '../../components/Trading/OrderPreview';
import styles from './TradingPage.module.css';

const TradingPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const symbolParam = searchParams.get('symbol') || '';
  const [symbol, setSymbol] = useState(symbolParam);
  const [showPreview, setShowPreview] = useState(false);
  
  const { data: asset, isLoading: assetLoading } = useAsset(symbol);
  const { data: account } = useAccount();
  const createOrder = useCreateOrder();

  const [orderData, setOrderData] = useState<OrderFormData>({
    symbol: symbol,
    side: 'buy' as OrderSide,
    type: 'market' as OrderType,
    timeInForce: 'day' as OrderTimeInForce,
    qty: '',
    limitPrice: '',
    stopPrice: '',
    extendedHours: false,
  });

  useEffect(() => {
    if (symbolParam) {
      setSymbol(symbolParam);
      setOrderData(prev => ({ ...prev, symbol: symbolParam }));
    }
  }, [symbolParam]);

  const handleOrderSubmit = async () => {
    try {
      await createOrder.mutateAsync(orderData);
      // Reset form after successful order
      setOrderData(prev => ({
        ...prev,
        qty: '',
        limitPrice: '',
        stopPrice: '',
      }));
      setShowPreview(false);
    } catch (error) {
      console.error('Order failed:', error);
    }
  };

  return (
    <div className={styles.trading}>
      <div className={styles.header}>
        <h1>Trade</h1>
      </div>

      <div className={styles.tradingLayout}>
        <div className={styles.leftColumn}>
          <AssetDetails 
            symbol={symbol} 
            onSymbolChange={setSymbol}
            asset={asset}
            isLoading={assetLoading}
          />
        </div>

        <div className={styles.rightColumn}>
          <div className={styles.orderPanel}>
            <h2>Place Order</h2>
            <OrderForm
              orderData={orderData}
              onChange={setOrderData}
              asset={asset}
              account={account}
              onPreview={() => setShowPreview(true)}
              isLoading={createOrder.isPending}
            />
          </div>
        </div>
      </div>

      {showPreview && (
        <OrderPreview
          orderData={orderData}
          asset={asset}
          onConfirm={handleOrderSubmit}
          onCancel={() => setShowPreview(false)}
          isLoading={createOrder.isPending}
        />
      )}
    </div>
  );
};

export default TradingPage;