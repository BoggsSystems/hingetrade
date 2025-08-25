import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext.dev';
import styles from './LandingPage.module.css';

interface MarketData {
  symbol: string;
  price: number;
  change: number;
  changePercent: number;
}

const LandingPage: React.FC = () => {
  const navigate = useNavigate();
  const { isAuthenticated, login } = useAuth();
  const [marketData] = useState<MarketData[]>([
    { symbol: 'SPY', price: 478.32, change: 2.45, changePercent: 0.51 },
    { symbol: 'QQQ', price: 402.18, change: -1.23, changePercent: -0.30 },
    { symbol: 'BTC/USD', price: 68432.50, change: 1245.80, changePercent: 1.85 },
    { symbol: 'ETH/USD', price: 3856.25, change: -32.40, changePercent: -0.83 },
  ]);

  useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard');
    }
  }, [isAuthenticated, navigate]);

  const features = [
    {
      icon: '🌍',
      title: 'Every Asset Class',
      description: 'Trade stocks, ETFs, and crypto all in one platform',
    },
    {
      icon: '⚡',
      title: 'Lightning Fast',
      description: 'Execute trades in milliseconds with our advanced infrastructure',
    },
    {
      icon: '🛡️',
      title: 'Bank-Level Security',
      description: 'Your assets are protected with institutional-grade security',
    },
    {
      icon: '📊',
      title: 'Advanced Analytics',
      description: 'Make informed decisions with real-time data and insights',
    },
  ];

  return (
    <div className={styles.landing}>
      {/* Hero Section */}
      <section className={styles.hero}>
        <div className={styles.marketTicker}>
          {marketData.map((item) => (
            <div key={item.symbol} className={styles.tickerItem}>
              <span className={styles.symbol}>{item.symbol}</span>
              <span className={styles.price}>${item.price.toFixed(2)}</span>
              <span
                className={`${styles.change} ${
                  item.change > 0 ? styles.positive : styles.negative
                }`}
              >
                {item.change > 0 ? '+' : ''}{item.change.toFixed(2)} ({item.changePercent.toFixed(2)}%)
              </span>
            </div>
          ))}
        </div>

        <div className={styles.heroContent}>
          <h1 className={styles.heroTitle}>
            Trade Every Asset,<br />
            Every Market,<br />
            <span className={styles.highlight}>Your Way</span>
          </h1>
          <p className={styles.heroSubtitle}>
            Professional trading platform with access to stocks, ETFs, and cryptocurrencies.
            Built for traders who demand more.
          </p>
          <div className={styles.heroActions}>
            <button onClick={login} className={`btn btn-primary btn-large ${styles.getStarted}`}>
              Get Started
            </button>
            <button onClick={login} className={`btn btn-secondary btn-large ${styles.signIn}`}>
              Sign In
            </button>
          </div>
        </div>

        <div className={styles.heroVisual}>
          <div className={styles.chartPlaceholder}>
            {/* Placeholder for animated chart or market visualization */}
            <div className={styles.chart}>
              <svg viewBox="0 0 400 200" className={styles.chartSvg}>
                <path
                  d="M0 150 Q50 100 100 120 T200 80 T300 100 T400 60"
                  fill="none"
                  stroke="var(--color-positive)"
                  strokeWidth="2"
                />
                <path
                  d="M0 150 Q50 100 100 120 T200 80 T300 100 T400 60"
                  fill="url(#gradient)"
                  opacity="0.1"
                />
                <defs>
                  <linearGradient id="gradient" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="var(--color-positive)" />
                    <stop offset="100%" stopColor="transparent" />
                  </linearGradient>
                </defs>
              </svg>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className={styles.features}>
        <div className="container">
          <h2 className={styles.sectionTitle}>Why Choose HingeTrade?</h2>
          <div className={styles.featureGrid}>
            {features.map((feature, index) => (
              <div key={index} className={styles.featureCard}>
                <div className={styles.featureIcon}>{feature.icon}</div>
                <h3 className={styles.featureTitle}>{feature.title}</h3>
                <p className={styles.featureDescription}>{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className={styles.cta}>
        <div className="container">
          <h2 className={styles.ctaTitle}>Ready to Start Trading?</h2>
          <p className={styles.ctaDescription}>
            Join thousands of traders who trust HingeTrade for their investment needs.
          </p>
          <button onClick={login} className={`btn btn-primary btn-large ${styles.ctaButton}`}>
            Create Free Account
          </button>
        </div>
      </section>
    </div>
  );
};

export default LandingPage;