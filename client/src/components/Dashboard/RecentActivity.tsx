import React from 'react';
import { useRecentActivity } from '../../hooks';
import styles from './RecentActivity.module.css';

interface Activity {
  id: string;
  type: 'buy' | 'sell' | 'dividend' | 'deposit';
  symbol?: string;
  description: string;
  amount: number;
  timestamp: string;
}

const RecentActivity: React.FC = () => {
  const { activities, isLoading, error } = useRecentActivity();

  if (isLoading) {
    return (
      <div className={styles.activityList}>
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className={styles.activityItemSkeleton} />
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className={styles.errorState}>
        <p>Unable to load recent activity</p>
      </div>
    );
  }

  if (activities.length === 0) {
    return (
      <div className={styles.emptyState}>
        <p>No recent trading activity</p>
        <p className={styles.hint}>Your trades will appear here</p>
      </div>
    );
  }
  const getActivityIcon = (type: Activity['type']) => {
    switch (type) {
      case 'buy':
        return '🛒';
      case 'sell':
        return '💰';
      case 'dividend':
        return '💵';
      case 'deposit':
        return '💳';
    }
  };

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    
    if (diffHours < 1) {
      return 'Just now';
    } else if (diffHours < 24) {
      return `${diffHours} hours ago`;
    } else if (diffHours < 48) {
      return 'Yesterday';
    } else {
      return date.toLocaleDateString();
    }
  };

  return (
    <div className={styles.activityList}>
      {activities.map((activity) => (
        <div key={activity.id} className={styles.activityItem}>
          <div className={styles.activityIcon}>{getActivityIcon(activity.type)}</div>
          <div className={styles.activityDetails}>
            <div className={styles.description}>
              {activity.description}
              {activity.symbol && (
                <span className={styles.symbol}> {activity.symbol}</span>
              )}
            </div>
            <div className={styles.timestamp}>{formatTimestamp(activity.timestamp)}</div>
          </div>
          <div
            className={`${styles.amount} ${
              activity.amount >= 0 ? styles.positive : styles.negative
            }`}
          >
            {activity.amount >= 0 ? '+' : ''}${Math.abs(activity.amount).toLocaleString()}
          </div>
        </div>
      ))}
    </div>
  );
};

export default RecentActivity;