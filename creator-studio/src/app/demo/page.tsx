import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Play, ArrowRight, Video, BarChart3, Users, DollarSign } from 'lucide-react'
import styles from './demo.module.css'

export default function DemoPage() {
  return (
    <div className={styles.demoPage}>
      {/* Header */}
      <header className={styles.header}>
        <div className={styles.headerContainer}>
          <div className={styles.headerContent}>
            <Link href="/" className={styles.logo}>
              <div className={styles.logoIcon}>
                <Video className="h-5 w-5 text-white" />
              </div>
              <h1 className={styles.logoText}>Creator Studio</h1>
            </Link>
            <Button asChild>
              <Link href="/auth/signup">Get Started</Link>
            </Button>
          </div>
        </div>
      </header>

      <div className={styles.container}>
        <div className={styles.hero}>
          <h1 className={styles.heroTitle}>
            See Creator Studio in Action
          </h1>
          <p className={styles.heroDescription}>
            Watch how trading educators are transforming their expertise into 
            engaging video content and building sustainable revenue streams.
          </p>
        </div>

        {/* Demo Video Placeholder */}
        <Card className={styles.videoCard}>
          <CardContent className={styles.videoCardContent}>
            <div className={styles.videoContainer}>
              <div className={styles.videoOverlay}>
                <div className={styles.videoPlayArea}>
                  <div className={styles.playButton}>
                    <Play className="h-10 w-10 text-white" />
                  </div>
                  <p className={styles.videoTitle}>
                    Creator Studio Demo Video
                  </p>
                  <p className={styles.videoSubtitle}>
                    Click to watch the 3-minute overview
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Feature Highlights */}
        <div className={styles.features}>
          <Card>
            <CardHeader>
              <div className={styles.featureHeader}>
                <div className={styles.featureIcon}>
                  <Video className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
                </div>
                <CardTitle className={styles.featureTitle}>Content Creation</CardTitle>
              </div>
              <CardDescription className={styles.featureDescription}>
                Professional tools for creating engaging trading content
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className={styles.featureList}>
                <li>• Browser-based video recording</li>
                <li>• AI-powered transcription</li>
                <li>• Automatic symbol detection</li>
                <li>• Chart synchronization</li>
              </ul>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className={styles.featureHeader}>
                <div className={styles.featureIcon}>
                  <DollarSign className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
                </div>
                <CardTitle className={styles.featureTitle}>Monetization</CardTitle>
              </div>
              <CardDescription className={styles.featureDescription}>
                Multiple revenue streams to maximize your earnings
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className={styles.featureList}>
                <li>• Subscription tiers</li>
                <li>• Sponsored content</li>
                <li>• Direct tips from viewers</li>
                <li>• Copy-trading revenue sharing</li>
              </ul>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className={styles.featureHeader}>
                <div className={styles.featureIcon}>
                  <BarChart3 className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
                </div>
                <CardTitle className={styles.featureTitle}>Analytics</CardTitle>
              </div>
              <CardDescription className={styles.featureDescription}>
                Detailed insights to optimize your content strategy
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className={styles.featureList}>
                <li>• Performance metrics</li>
                <li>• Audience demographics</li>
                <li>• Revenue tracking</li>
                <li>• Growth insights</li>
              </ul>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className={styles.featureHeader}>
                <div className={styles.featureIcon}>
                  <Users className="h-6 w-6" style={{ color: 'var(--color-positive)' }} />
                </div>
                <CardTitle className={styles.featureTitle}>Community</CardTitle>
              </div>
              <CardDescription className={styles.featureDescription}>
                Build and engage with your trading community
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className={styles.featureList}>
                <li>• Subscriber management</li>
                <li>• Community features</li>
                <li>• Direct messaging</li>
                <li>• Live interactions</li>
              </ul>
            </CardContent>
          </Card>
        </div>

        {/* CTA Section */}
        <Card className={styles.ctaCard}>
          <CardHeader className={styles.ctaHeader}>
            <CardTitle className={styles.ctaTitle}>
              Ready to start your creator journey?
            </CardTitle>
            <CardDescription className={styles.ctaDescription}>
              Join thousands of trading educators already using Creator Studio
            </CardDescription>
          </CardHeader>
          <CardContent className={styles.ctaContent}>
            <div className={styles.ctaButtons}>
              <Button size="lg" asChild>
                <Link href="/auth/signup">
                  Get Started Free
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Link>
              </Button>
              <Button size="lg" variant="outline" asChild>
                <Link href="/auth/signin">Sign In</Link>
              </Button>
            </div>
            <p className={styles.ctaSubtext}>
              No credit card required • Free to start • Cancel anytime
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}