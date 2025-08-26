import React from 'react';
import styles from '../../pages/Legal/LegalPages.module.css';

const TermsOfServiceContent: React.FC = () => {
  return (
    <>
      <p className={styles.effectiveDate}>Effective Date: {new Date().toLocaleDateString()}</p>
      
      <section className={styles.section}>
        <h2>1. Acceptance of Terms</h2>
        <p>
          By accessing or using HingeTrade ("the Platform"), you agree to be bound by these Terms of Service ("Terms"). 
          If you do not agree to these Terms, you may not access or use the Platform.
        </p>
      </section>

      <section className={styles.section}>
        <h2>2. Description of Services</h2>
        <p>
          HingeTrade provides a web-based trading platform that allows users to:
        </p>
        <ul>
          <li>Trade stocks, ETFs, and cryptocurrencies</li>
          <li>Access real-time market data and analytics</li>
          <li>Manage investment portfolios</li>
          <li>Execute orders through our partner broker, Alpaca Markets</li>
        </ul>
      </section>

      <section className={styles.section}>
        <h2>3. Account Registration and Security</h2>
        <p>To use our trading services, you must:</p>
        <ul>
          <li>Be at least 18 years of age</li>
          <li>Provide accurate and complete information during registration</li>
          <li>Complete our Know Your Customer (KYC) verification process</li>
          <li>Maintain the security of your account credentials</li>
          <li>Notify us immediately of any unauthorized access</li>
        </ul>
      </section>

      <section className={styles.section}>
        <h2>4. Trading Rules and Regulations</h2>
        <p>
          All trading activities on the Platform are subject to applicable federal and state laws, 
          including regulations from the Securities and Exchange Commission (SEC) and Financial 
          Industry Regulatory Authority (FINRA). You agree to:
        </p>
        <ul>
          <li>Comply with all applicable laws and regulations</li>
          <li>Not engage in market manipulation or fraudulent activities</li>
          <li>Not use the Platform for money laundering or terrorist financing</li>
          <li>Accept responsibility for all trading decisions and their outcomes</li>
        </ul>
      </section>

      <section className={styles.section}>
        <h2>5. Brokerage Services</h2>
        <p>
          Securities brokerage services are provided by Alpaca Securities LLC, member FINRA/SIPC. 
          Cryptocurrency execution and custody services are provided by Alpaca Crypto LLC, member FINRA/SIPC. 
          These are separate but affiliated entities.
        </p>
      </section>

      <section className={styles.section}>
        <h2>6. Fees and Charges</h2>
        <p>
          Our fee structure includes:
        </p>
        <ul>
          <li>Commission-free trading for stocks and ETFs</li>
          <li>Cryptocurrency trading fees as disclosed in our fee schedule</li>
          <li>Regulatory and exchange fees may apply</li>
          <li>We reserve the right to modify our fee structure with 30 days notice</li>
        </ul>
      </section>

      <section className={styles.section}>
        <h2>7. Risk Disclosure</h2>
        <p>
          <strong>Important:</strong> Trading involves substantial risk and is not suitable for all investors. 
          You may lose some or all of your invested capital. Consider your investment objectives and risk 
          tolerance before trading. Past performance is not indicative of future results.
        </p>
      </section>

      <section className={styles.section}>
        <h2>8. Market Data</h2>
        <p>
          Market data is provided for informational purposes only and is not intended for trading purposes. 
          We do not guarantee the accuracy, completeness, or timeliness of any market data.
        </p>
      </section>

      <section className={styles.section}>
        <h2>9. Prohibited Activities</h2>
        <p>You may not:</p>
        <ul>
          <li>Use automated systems or bots without our express written permission</li>
          <li>Attempt to reverse engineer or hack the Platform</li>
          <li>Share your account credentials or allow others to trade on your behalf</li>
          <li>Use the Platform for any illegal or unauthorized purpose</li>
        </ul>
      </section>

      <section className={styles.section}>
        <h2>10. Intellectual Property</h2>
        <p>
          All content on the Platform, including text, graphics, logos, and software, is the property 
          of HingeTrade or its licensors and is protected by intellectual property laws.
        </p>
      </section>

      <section className={styles.section}>
        <h2>11. Disclaimer of Warranties</h2>
        <p>
          THE PLATFORM IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. 
          WE DO NOT GUARANTEE CONTINUOUS, UNINTERRUPTED, OR SECURE ACCESS TO THE PLATFORM.
        </p>
      </section>

      <section className={styles.section}>
        <h2>12. Limitation of Liability</h2>
        <p>
          TO THE MAXIMUM EXTENT PERMITTED BY LAW, HINGETRADE SHALL NOT BE LIABLE FOR ANY INDIRECT, 
          INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE PLATFORM.
        </p>
      </section>

      <section className={styles.section}>
        <h2>13. Indemnification</h2>
        <p>
          You agree to indemnify and hold harmless HingeTrade, its affiliates, and their respective 
          officers, directors, employees, and agents from any claims arising from your use of the Platform.
        </p>
      </section>

      <section className={styles.section}>
        <h2>14. Termination</h2>
        <p>
          We reserve the right to suspend or terminate your account at any time for violation of these 
          Terms or for any other reason at our sole discretion.
        </p>
      </section>

      <section className={styles.section}>
        <h2>15. Governing Law</h2>
        <p>
          These Terms shall be governed by and construed in accordance with the laws of the State of 
          Delaware, without regard to its conflict of law provisions.
        </p>
      </section>

      <section className={styles.section}>
        <h2>16. Changes to Terms</h2>
        <p>
          We may update these Terms from time to time. We will notify you of any material changes by 
          posting the new Terms on this page and updating the effective date.
        </p>
      </section>

      <section className={styles.section}>
        <h2>17. Contact Information</h2>
        <p>
          If you have any questions about these Terms, please contact us at:
        </p>
        <p>
          Email: legal@hingetrade.com<br />
          Address: HingeTrade, Inc.<br />
          123 Trading Street<br />
          New York, NY 10001
        </p>
      </section>
    </>
  );
};

export default TermsOfServiceContent;