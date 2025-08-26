import React, { useEffect } from 'react';
import styles from './LegalPages.module.css';

const PrivacyPolicyPage: React.FC = () => {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  return (
    <div className={styles.legalContainer}>
      <div className={styles.legalContent}>
        <h1>Privacy Policy</h1>
        <p className={styles.effectiveDate}>Effective Date: {new Date().toLocaleDateString()}</p>
        
        <section className={styles.section}>
          <h2>1. Introduction</h2>
          <p>
            HingeTrade, Inc. ("we," "our," or "us") respects your privacy and is committed to protecting 
            your personal information. This Privacy Policy explains how we collect, use, disclose, and 
            safeguard your information when you use our trading platform.
          </p>
        </section>

        <section className={styles.section}>
          <h2>2. Information We Collect</h2>
          
          <h3>Personal Information</h3>
          <p>When you register for an account, we collect:</p>
          <ul>
            <li>Full name and date of birth</li>
            <li>Social Security Number (for tax reporting)</li>
            <li>Contact information (email, phone number, address)</li>
            <li>Government-issued ID information</li>
            <li>Employment and financial information</li>
            <li>Bank account information for funding</li>
          </ul>

          <h3>Trading Information</h3>
          <ul>
            <li>Transaction history and order details</li>
            <li>Portfolio holdings and performance</li>
            <li>Investment preferences and risk tolerance</li>
          </ul>

          <h3>Technical Information</h3>
          <ul>
            <li>IP address and device information</li>
            <li>Browser type and operating system</li>
            <li>Usage data and analytics</li>
            <li>Cookies and similar technologies</li>
          </ul>
        </section>

        <section className={styles.section}>
          <h2>3. How We Use Your Information</h2>
          <p>We use your information to:</p>
          <ul>
            <li>Verify your identity and comply with KYC regulations</li>
            <li>Process your trades and maintain your account</li>
            <li>Provide customer support and respond to inquiries</li>
            <li>Send important account notifications and updates</li>
            <li>Detect and prevent fraud and unauthorized access</li>
            <li>Comply with legal and regulatory requirements</li>
            <li>Improve our services and develop new features</li>
            <li>Send marketing communications (with your consent)</li>
          </ul>
        </section>

        <section className={styles.section}>
          <h2>4. Information Sharing and Disclosure</h2>
          <p>We may share your information with:</p>
          
          <h3>Service Providers</h3>
          <ul>
            <li>Alpaca Markets (our clearing broker)</li>
            <li>Banking partners for payment processing</li>
            <li>Identity verification services</li>
            <li>Cloud storage and infrastructure providers</li>
          </ul>

          <h3>Legal and Regulatory</h3>
          <ul>
            <li>Government agencies as required by law</li>
            <li>In response to subpoenas or court orders</li>
            <li>To comply with regulatory requirements (SEC, FINRA)</li>
            <li>To protect our rights and prevent illegal activities</li>
          </ul>

          <p>We do not sell your personal information to third parties.</p>
        </section>

        <section className={styles.section}>
          <h2>5. Data Security</h2>
          <p>
            We implement industry-standard security measures to protect your information:
          </p>
          <ul>
            <li>256-bit SSL encryption for data transmission</li>
            <li>Encrypted storage of sensitive information</li>
            <li>Multi-factor authentication options</li>
            <li>Regular security audits and penetration testing</li>
            <li>Employee access controls and training</li>
          </ul>
          <p>
            However, no method of transmission or storage is 100% secure. We cannot guarantee 
            absolute security of your information.
          </p>
        </section>

        <section className={styles.section}>
          <h2>6. Data Retention</h2>
          <p>
            We retain your information for as long as necessary to:
          </p>
          <ul>
            <li>Maintain your account and provide services</li>
            <li>Comply with legal and regulatory requirements</li>
            <li>Resolve disputes and enforce our agreements</li>
          </ul>
          <p>
            Financial records are typically retained for 7 years after account closure as required by law.
          </p>
        </section>

        <section className={styles.section}>
          <h2>7. Your Rights and Choices</h2>
          <p>You have the right to:</p>
          <ul>
            <li>Access and review your personal information</li>
            <li>Correct inaccurate or incomplete information</li>
            <li>Request deletion of your account (subject to legal requirements)</li>
            <li>Opt-out of marketing communications</li>
            <li>Download your data in a portable format</li>
          </ul>
          <p>
            To exercise these rights, contact us at privacy@hingetrade.com.
          </p>
        </section>

        <section className={styles.section}>
          <h2>8. California Privacy Rights</h2>
          <p>
            California residents have additional rights under the California Consumer Privacy Act (CCPA):
          </p>
          <ul>
            <li>Right to know what personal information we collect</li>
            <li>Right to delete personal information</li>
            <li>Right to opt-out of sale (we do not sell personal information)</li>
            <li>Right to non-discrimination for exercising privacy rights</li>
          </ul>
        </section>

        <section className={styles.section}>
          <h2>9. Cookies and Tracking Technologies</h2>
          <p>
            We use cookies and similar technologies to:
          </p>
          <ul>
            <li>Remember your preferences and settings</li>
            <li>Authenticate your sessions</li>
            <li>Analyze usage patterns and improve our services</li>
            <li>Prevent fraud and enhance security</li>
          </ul>
          <p>
            You can control cookies through your browser settings, but disabling them may limit 
            functionality.
          </p>
        </section>

        <section className={styles.section}>
          <h2>10. International Users</h2>
          <p>
            Our services are intended for use in the United States. If you access the Platform from 
            outside the U.S., your information may be transferred to and processed in the U.S.
          </p>
        </section>

        <section className={styles.section}>
          <h2>11. Children's Privacy</h2>
          <p>
            Our services are not intended for users under 18. We do not knowingly collect information 
            from children. If we discover we have collected information from a child, we will delete it.
          </p>
        </section>

        <section className={styles.section}>
          <h2>12. Changes to This Policy</h2>
          <p>
            We may update this Privacy Policy from time to time. We will notify you of material changes 
            by email or through the Platform. Your continued use constitutes acceptance of the updated policy.
          </p>
        </section>

        <section className={styles.section}>
          <h2>13. Contact Us</h2>
          <p>
            If you have questions about this Privacy Policy or our data practices, contact us at:
          </p>
          <p>
            Email: privacy@hingetrade.com<br />
            Data Protection Officer: dpo@hingetrade.com<br />
            <br />
            HingeTrade, Inc.<br />
            123 Trading Street<br />
            New York, NY 10001<br />
            Phone: 1-800-HINGETRADE
          </p>
        </section>
      </div>
    </div>
  );
};

export default PrivacyPolicyPage;