import React from 'react';
import styles from './MetricCard.module.css';

interface MetricCardProps {
  title: string;
  value: string;
  subtitle?: string;
  change?: number;
  changePercent?: number;
  showSign?: boolean;
  isPositive?: boolean;
}

const MetricCard: React.FC<MetricCardProps> = ({
  title,
  value,
  subtitle,
  change,
  changePercent,
  showSign = false,
  isPositive,
}) => {
  const hasChange = change !== undefined && changePercent !== undefined;
  const isChangePositive = change !== undefined ? change >= 0 : isPositive;

  return (
    <div className={styles.metricCard}>
      <h3 className={styles.title}>{title}</h3>
      <div className={styles.value}>{value}</div>
      {subtitle && <div className={styles.subtitle}>{subtitle}</div>}
      {hasChange && (
        <div
          className={`${styles.change} ${
            isChangePositive ? styles.positive : styles.negative
          }`}
        >
          <span className={styles.changeAmount}>
            {showSign && change >= 0 ? '+' : ''}${Math.abs(change).toLocaleString()}
          </span>
          <span className={styles.changePercent}>
            ({changePercent >= 0 ? '+' : ''}{changePercent.toFixed(2)}%)
          </span>
        </div>
      )}
    </div>
  );
};

export default MetricCard;