import React from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { useKycStatus } from '../../hooks/useKycStatus';
import { usePortfolio } from '../../hooks';
import MetricCard from '../../components/Common/MetricCard';
import PortfolioChart from '../../components/Dashboard/PortfolioChart';
import RecentActivity from '../../components/Dashboard/RecentActivity';
import WatchlistWidget from '../../components/Dashboard/WatchlistWidget';
import MarketOverview from '../../components/Dashboard/MarketOverview';
import DashboardSkeleton from '../../components/Dashboard/DashboardSkeleton';
import styles from './DashboardPage.module.css';

const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const { kycStatus } = useKycStatus();
  const { metrics, isLoading, error } = usePortfolio();

  if (isLoading) {
    return <DashboardSkeleton />;
  }

  if (error) {
    return (
      <div className={styles.error}>
        <h2>Unable to load portfolio data</h2>
        <p>Please check your connection and try again.</p>
      </div>
    );
  }

  return (
    <div className={styles.dashboard}>
      <div className={styles.header}>
        <h1>Welcome back, {user?.username}!</h1>
        <p className={styles.subtitle}>Here's your portfolio overview</p>
        {kycStatus && kycStatus !== 'Approved' && (
          <div className={styles.kycWarning}>
            <p>⚠️ KYC Status: {kycStatus}. Some features may be restricted.</p>
          </div>
        )}
      </div>

      <div className={styles.metricsGrid}>
        <MetricCard
          title="Portfolio Value"
          value={`$${metrics.portfolioValue.toLocaleString()}`}
          change={metrics.dayChange}
          changePercent={metrics.dayChangePercent}
        />
        <MetricCard
          title="Day's Gain/Loss"
          value={`$${Math.abs(metrics.dayChange).toLocaleString()}`}
          change={metrics.dayChange}
          changePercent={metrics.dayChangePercent}
          showSign
        />
        <MetricCard
          title="Total Return"
          value={`$${metrics.totalUnrealizedPL.toLocaleString()}`}
          subtitle={`${metrics.totalReturnPercent > 0 ? '+' : ''}${metrics.totalReturnPercent.toFixed(2)}%`}
          isPositive={metrics.totalUnrealizedPL > 0}
        />
        <MetricCard
          title="Buying Power"
          value={`$${metrics.buyingPower.toLocaleString()}`}
          subtitle="Available to trade"
        />
      </div>

      <div className={styles.mainContent}>
        <div className={styles.leftColumn}>
          <div className={styles.card}>
            <h2>Portfolio Performance</h2>
            <PortfolioChart />
          </div>
          <div className={styles.card}>
            <h2>Recent Activity</h2>
            <RecentActivity />
          </div>
        </div>
        <div className={styles.rightColumn}>
          <div className={styles.card}>
            <h2>Watchlist</h2>
            <WatchlistWidget />
          </div>
          <div className={styles.card}>
            <h2>Market Overview</h2>
            <MarketOverview />
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;