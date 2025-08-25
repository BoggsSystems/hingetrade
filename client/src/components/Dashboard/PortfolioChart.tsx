import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import styles from './PortfolioChart.module.css';

// Mock data - in real app, this would come from API
const data = [
  { date: 'Mon', value: 120000 },
  { date: 'Tue', value: 121500 },
  { date: 'Wed', value: 119800 },
  { date: 'Thu', value: 122300 },
  { date: 'Fri', value: 125430 },
];

const PortfolioChart: React.FC = () => {
  return (
    <div className={styles.chartContainer}>
      <div className={styles.timeframeSelector}>
        <button className={`${styles.timeframe} ${styles.active}`}>1D</button>
        <button className={styles.timeframe}>1W</button>
        <button className={styles.timeframe}>1M</button>
        <button className={styles.timeframe}>3M</button>
        <button className={styles.timeframe}>1Y</button>
        <button className={styles.timeframe}>ALL</button>
      </div>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data} margin={{ top: 10, right: 10, left: 10, bottom: 10 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
          <XAxis
            dataKey="date"
            stroke="var(--color-text-light)"
            style={{ fontSize: 'var(--font-sm)' }}
          />
          <YAxis
            stroke="var(--color-text-light)"
            style={{ fontSize: 'var(--font-sm)' }}
            tickFormatter={(value) => `$${(value / 1000).toFixed(0)}k`}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: 'var(--color-panel)',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-sm)',
            }}
            labelStyle={{ color: 'var(--color-text)' }}
            formatter={(value: number) => [`$${value.toLocaleString()}`, 'Portfolio Value']}
          />
          <Line
            type="monotone"
            dataKey="value"
            stroke="var(--color-positive)"
            strokeWidth={2}
            dot={false}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default PortfolioChart;