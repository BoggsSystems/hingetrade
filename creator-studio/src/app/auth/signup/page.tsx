import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Video, Check } from 'lucide-react'
import styles from './signup.module.css'

export default function SignUpPage() {
  return (
    <div className={styles.signupPage}>
      <div className={styles.container}>
        <div className={styles.header}>
          <div className={styles.headerContent}>
            <div className={styles.logo}>
              <div className={styles.logoIcon}>
                <Video className="h-6 w-6 text-white" />
              </div>
              <h1 className={styles.logoText}>Creator Studio</h1>
            </div>
          </div>
          <h2 className={styles.title}>Start your creator journey</h2>
          <p className={styles.subtitle}>
            Join thousands of trading educators already earning with Creator Studio
          </p>
        </div>

        <div className={styles.content}>
          {/* Sign up form */}
          <div className={styles.formSection}>
            <Card>
              <CardHeader>
                <CardTitle className={styles.cardTitle}>Create your account</CardTitle>
                <CardDescription className={styles.cardDescription}>
                  Get started with your free Creator Studio account
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form className={styles.form}>
                  <div className={styles.nameGrid}>
                    <div className={styles.field}>
                      <Label htmlFor="firstName">First name</Label>
                      <Input
                        id="firstName"
                        name="firstName"
                        type="text"
                        required
                        placeholder="John"
                      />
                    </div>
                    <div className={styles.field}>
                      <Label htmlFor="lastName">Last name</Label>
                      <Input
                        id="lastName"
                        name="lastName"
                        type="text"
                        required
                        placeholder="Doe"
                      />
                    </div>
                  </div>

                  <div className={styles.field}>
                    <Label htmlFor="email">Email address</Label>
                    <Input
                      id="email"
                      name="email"
                      type="email"
                      autoComplete="email"
                      required
                      placeholder="john@example.com"
                    />
                  </div>

                  <div className={styles.field}>
                    <Label htmlFor="password">Password</Label>
                    <Input
                      id="password"
                      name="password"
                      type="password"
                      autoComplete="new-password"
                      required
                      placeholder="Create a strong password"
                    />
                    <p className={styles.passwordHint}>
                      Must be at least 8 characters with numbers and letters
                    </p>
                  </div>

                  <div className={styles.field}>
                    <Label htmlFor="confirmPassword">Confirm password</Label>
                    <Input
                      id="confirmPassword"
                      name="confirmPassword"
                      type="password"
                      required
                      placeholder="Confirm your password"
                    />
                  </div>

                  <div className={styles.checkbox}>
                    <input
                      id="terms"
                      name="terms"
                      type="checkbox"
                      className={styles.checkboxInput}
                      required
                    />
                    <label htmlFor="terms" className={styles.checkboxLabel}>
                      I agree to the{' '}
                      <Link href="/terms" className={styles.link}>
                        Terms of Service
                      </Link>{' '}
                      and{' '}
                      <Link href="/privacy" className={styles.link}>
                        Privacy Policy
                      </Link>
                    </label>
                  </div>

                  <Button type="submit" className="w-full">
                    Create account
                  </Button>

                  <div className={styles.signinLink}>
                    <p>
                      Already have an account?{' '}
                      <Link href="/auth/signin" className={styles.link}>
                        Sign in
                      </Link>
                    </p>
                  </div>
                </form>
              </CardContent>
            </Card>
          </div>

          {/* Benefits */}
          <div className={styles.benefitsSection}>
            <div>
              <h3 className={styles.benefitsTitle}>
                What you get with Creator Studio
              </h3>
              <div className={styles.benefits}>
                <div className={styles.benefit}>
                  <div className={styles.benefitIcon}>
                    <Check className="w-4 h-4" style={{ color: 'var(--color-positive)' }} />
                  </div>
                  <div>
                    <h4 className={styles.benefitTitle}>Professional Video Tools</h4>
                    <p className={styles.benefitDescription}>
                      Record, upload, and edit trading videos with AI-powered enhancements
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <div className="flex-shrink-0 w-6 h-6 bg-green-100 rounded-full flex items-center justify-center mt-0.5">
                    <Check className="w-4 h-4 text-green-600" />
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">Multiple Revenue Streams</h4>
                    <p className="text-sm text-gray-600">
                      Earn through subscriptions, sponsorships, tips, and copy-trading revenue
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <div className="flex-shrink-0 w-6 h-6 bg-green-100 rounded-full flex items-center justify-center mt-0.5">
                    <Check className="w-4 h-4 text-green-600" />
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">Advanced Analytics</h4>
                    <p className="text-sm text-gray-600">
                      Track performance and optimize your content strategy with detailed insights
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <div className="flex-shrink-0 w-6 h-6 bg-green-100 rounded-full flex items-center justify-center mt-0.5">
                    <Check className="w-4 h-4 text-green-600" />
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">Compliance Ready</h4>
                    <p className="text-sm text-gray-600">
                      Built-in tools ensure your content meets financial education standards
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <div className="flex-shrink-0 w-6 h-6 bg-green-100 rounded-full flex items-center justify-center mt-0.5">
                    <Check className="w-4 h-4 text-green-600" />
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">Audience Building</h4>
                    <p className="text-sm text-gray-600">
                      Grow your community with subscriber tiers and engagement tools
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <div className={styles.cta}>
              <h4 className={styles.ctaTitle}>Ready to get started?</h4>
              <p className={styles.ctaDescription}>
                Join our community of successful trading educators and start monetizing your expertise today.
              </p>
              <div className={styles.ctaFeatures}>
                <span>✓ Free to start</span>
                <span>✓ No setup fees</span>
                <span>✓ 24/7 support</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}