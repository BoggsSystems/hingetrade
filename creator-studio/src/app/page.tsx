'use client';

import Link from 'next/link'
import { Play, Users, DollarSign, BarChart3, Video, Zap } from 'lucide-react'
import styles from './page.module.css'
import { useAuth } from '@/contexts/AuthContext'
import { useRouter, useSearchParams } from 'next/navigation'
import { useEffect, useState } from 'react'
import RegistrationModal from '@/components/modals/RegistrationModal'
import LoginModal from '@/components/modals/LoginModal'

export default function HomePage() {
  const { isAuthenticated, isLoading } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [isRegistrationModalOpen, setIsRegistrationModalOpen] = useState(false);
  const [isLoginModalOpen, setIsLoginModalOpen] = useState(false);
  
  const redirectTo = searchParams.get('redirect');

  useEffect(() => {
    if (!isLoading && isAuthenticated) {
      // Use redirect parameter if available, otherwise go to dashboard
      router.push(redirectTo || '/dashboard');
    }
  }, [isAuthenticated, isLoading, router, redirectTo]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="loading-spinner">Loading...</div>
      </div>
    );
  }

  if (isAuthenticated) {
    return null; // Will redirect to dashboard
  }
  return (
    <div className={styles.homepage}>
      {/* Header */}
      <header className={styles.header}>
        <div className="container">
          <div className={styles.headerContent}>
            <div className={styles.logo}>
              <div className={styles.logoIcon}>
                <Video className="h-5 w-5 text-white" />
              </div>
              <h1 className={styles.logoText}>Creator Studio</h1>
            </div>
            <nav className={styles.nav}>
              <button 
                onClick={() => setIsLoginModalOpen(true)}
                className={styles.navLink}
                style={{ background: 'none', border: 'none', cursor: 'pointer' }}
              >
                Sign In
              </button>
              <button 
                onClick={() => setIsRegistrationModalOpen(true)}
                className="btn btn-primary"
              >
                Get Started
              </button>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className={styles.hero}>
        <div className="container">
          <div className={styles.heroContent}>
            <h1 className={styles.heroTitle}>
              Create. Educate.{' '}
              <span className={styles.heroAccent}>Monetize.</span>
            </h1>
            <p className={styles.heroDescription}>
              Transform your trading expertise into engaging video content. 
              Share insights, build your audience, and earn revenue through 
              the HingeTrade Creator Studio.
            </p>
            <div className={styles.heroActions}>
              <button 
                onClick={() => setIsRegistrationModalOpen(true)}
                className="btn btn-primary btn-lg"
              >
                <Play className="mr-2 h-5 w-5" />
                Start Creating
              </button>
              <Link href="/demo" className="btn btn-ghost btn-lg">
                Watch Demo
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className={styles.features}>
        <div className="container">
          <div className={styles.featuresHeader}>
            <h2 className={styles.featuresTitle}>
              Everything you need to succeed as a creator
            </h2>
            <p className={styles.featuresDescription}>
              Professional tools designed for trading educators and content creators.
            </p>
          </div>
          
          <div className={styles.featuresGrid}>
            {/* Video Creation */}
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>
                <Video className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
              </div>
              <h3 className={styles.featureTitle}>
                Professional Video Tools
              </h3>
              <p className={styles.featureDescription}>
                Record directly in your browser or upload videos. AI-powered 
                transcription and chart synchronization included.
              </p>
            </div>

            {/* AI Enhancement */}
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>
                <Zap className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
              </div>
              <h3 className={styles.featureTitle}>
                AI-Powered Enhancement
              </h3>
              <p className={styles.featureDescription}>
                Automatic symbol detection, technical indicator recognition, 
                and chart context generation for your trading videos.
              </p>
            </div>

            {/* Audience Building */}
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>
                <Users className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
              </div>
              <h3 className={styles.featureTitle}>
                Audience Building
              </h3>
              <p className={styles.featureDescription}>
                Build your community with subscriber tiers, exclusive content, 
                and direct audience engagement tools.
              </p>
            </div>

            {/* Monetization */}
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>
                <DollarSign className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
              </div>
              <h3 className={styles.featureTitle}>
                Multiple Revenue Streams
              </h3>
              <p className={styles.featureDescription}>
                Earn through subscriptions, sponsorships, tips, and 
                copy-trading revenue sharing.
              </p>
            </div>

            {/* Analytics */}
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>
                <BarChart3 className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
              </div>
              <h3 className={styles.featureTitle}>
                Advanced Analytics
              </h3>
              <p className={styles.featureDescription}>
                Track performance, understand your audience, and optimize 
                your content strategy with detailed insights.
              </p>
            </div>

            {/* Compliance */}
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>
                <Play className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
              </div>
              <h3 className={styles.featureTitle}>
                Compliance Ready
              </h3>
              <p className={styles.featureDescription}>
                Built-in compliance tools ensure your content meets 
                financial education standards and disclosure requirements.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className={styles.cta}>
        <div className="container">
          <div className={styles.ctaContent}>
            <h2 className={styles.ctaTitle}>
              Ready to start your creator journey?
            </h2>
            <p className={styles.ctaDescription}>
              Join thousands of trading educators already using Creator Studio.
            </p>
            <div>
              <button 
                onClick={() => setIsRegistrationModalOpen(true)}
                className="btn btn-primary btn-lg"
              >
                Create Your Account
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className={styles.footer}>
        <div className="container">
          <div className={styles.footerContent}>
            <p>&copy; 2024 HingeTrade. All rights reserved.</p>
            <div className={styles.footerLinks}>
              <Link href="/terms" className={styles.footerLink}>Terms</Link>
              <Link href="/privacy" className={styles.footerLink}>Privacy</Link>
              <Link href="/support" className={styles.footerLink}>Support</Link>
            </div>
          </div>
        </div>
      </footer>

      {/* Registration Modal */}
      <RegistrationModal
        isOpen={isRegistrationModalOpen}
        onClose={() => setIsRegistrationModalOpen(false)}
        onSuccess={() => {
          setIsRegistrationModalOpen(false);
          // Router push will be handled by the auth context automatically
        }}
        onSwitchToLogin={() => {
          setIsRegistrationModalOpen(false);
          setIsLoginModalOpen(true);
        }}
        redirectTo={redirectTo}
      />

      {/* Login Modal */}
      <LoginModal
        isOpen={isLoginModalOpen}
        onClose={() => setIsLoginModalOpen(false)}
        onSuccess={() => {
          setIsLoginModalOpen(false);
          // Router push will be handled by the auth context automatically
        }}
        onSwitchToRegister={() => {
          setIsLoginModalOpen(false);
          setIsRegistrationModalOpen(true);
        }}
        redirectTo={redirectTo}
      />
    </div>
  )
}