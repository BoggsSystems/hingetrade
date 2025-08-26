import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import DebugPanel from '../../components/Debug/DebugPanel';
import { debugLogger } from '../../utils/debugLogger';
import styles from './LandingPage.module.css';

interface MarketData {
  symbol: string;
  price: number;
  change: number;
  changePercent: number;
}

const LandingPage: React.FC = () => {
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const [marketData] = useState<MarketData[]>([
    { symbol: 'SPY', price: 478.32, change: 2.45, changePercent: 0.51 },
    { symbol: 'QQQ', price: 402.18, change: -1.23, changePercent: -0.30 },
    { symbol: 'BTC/USD', price: 68432.50, change: 1245.80, changePercent: 1.85 },
    { symbol: 'ETH/USD', price: 3856.25, change: -32.40, changePercent: -0.83 },
  ]);

  useEffect(() => {
    debugLogger.info('LandingPage useEffect triggered', { isAuthenticated });
    if (isAuthenticated) {
      debugLogger.info('User is authenticated, navigating to dashboard');
      navigate('/dashboard');
    }
  }, [isAuthenticated, navigate]);

  const features = [
    {
      icon: (
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5"/>
          <path d="M12 3C12 3 8 8 8 12C8 16 12 21 12 21" stroke="currentColor" strokeWidth="1.5"/>
          <path d="M12 3C12 3 16 8 16 12C16 16 12 21 12 21" stroke="currentColor" strokeWidth="1.5"/>
          <path d="M3 12H21" stroke="currentColor" strokeWidth="1.5"/>
          <path d="M4.5 8H19.5" stroke="currentColor" strokeWidth="1.5"/>
          <path d="M4.5 16H19.5" stroke="currentColor" strokeWidth="1.5"/>
        </svg>
      ),
      title: 'Every Asset Class',
      description: 'Trade stocks, ETFs, and crypto all in one platform',
    },
    {
      icon: (
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M13 2L3 14H12L11 22L21 10H12L13 2Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      ),
      title: 'Lightning Fast',
      description: 'Execute trades in milliseconds with our advanced infrastructure',
    },
    {
      icon: (
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 2L3.5 7.5V12C3.5 16.5 6.5 20.74 12 22C17.5 20.74 20.5 16.5 20.5 12V7.5L12 2Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          <path d="M9 12L11 14L15 10" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      ),
      title: 'Bank-Level Security',
      description: 'Your assets are protected with institutional-grade security',
    },
    {
      icon: (
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="3" y="3" width="18" height="18" rx="2" stroke="currentColor" strokeWidth="1.5"/>
          <path d="M7 14L10 11L13 13L17 9" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          <circle cx="17" cy="9" r="1" fill="currentColor"/>
          <circle cx="13" cy="13" r="1" fill="currentColor"/>
          <circle cx="10" cy="11" r="1" fill="currentColor"/>
          <circle cx="7" cy="14" r="1" fill="currentColor"/>
        </svg>
      ),
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
            <button onClick={() => navigate('/register')} className={`btn btn-primary btn-large ${styles.getStarted}`}>
              Get Started
            </button>
            <button onClick={() => navigate('/login')} className={`btn btn-secondary btn-large ${styles.signIn}`}>
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
          <button onClick={() => navigate('/register')} className={`btn btn-primary btn-large ${styles.ctaButton}`}>
            Create Free Account
          </button>
        </div>
      </section>
      
      <DebugPanel />
    </div>
  );
};

export default LandingPage;