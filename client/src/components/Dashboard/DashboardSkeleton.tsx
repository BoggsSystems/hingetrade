import React from 'react';
import styles from './DashboardSkeleton.module.css';

const DashboardSkeleton: React.FC = () => {
  return (
    <div className={styles.skeleton}>
      <div className={styles.header}>
        <div className={styles.titleSkeleton} />
        <div className={styles.subtitleSkeleton} />
      </div>

      <div className={styles.metricsGrid}>
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className={styles.metricCard}>
            <div className={styles.metricTitle} />
            <div className={styles.metricValue} />
            <div className={styles.metricChange} />
          </div>
        ))}
      </div>

      <div className={styles.mainContent}>
        <div className={styles.leftColumn}>
          <div className={styles.card}>
            <div className={styles.cardTitle} />
            <div className={styles.chartSkeleton} />
          </div>
          <div className={styles.card}>
            <div className={styles.cardTitle} />
            <div className={styles.listSkeleton}>
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className={styles.listItem} />
              ))}
            </div>
          </div>
        </div>
        <div className={styles.rightColumn}>
          <div className={styles.card}>
            <div className={styles.cardTitle} />
            <div className={styles.listSkeleton}>
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className={styles.listItem} />
              ))}
            </div>
          </div>
          <div className={styles.card}>
            <div className={styles.cardTitle} />
            <div className={styles.listSkeleton}>
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className={styles.listItem} />
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardSkeleton;