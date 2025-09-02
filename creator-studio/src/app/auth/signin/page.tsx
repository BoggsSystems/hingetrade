import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Video } from 'lucide-react'
import styles from './signin.module.css'

export default function SignInPage() {
  return (
    <div className={styles.signinPage}>
      <div className={styles.header}>
        <div className={styles.headerContent}>
          <div className={styles.logo}>
            <div className={styles.logoIcon}>
              <Video className="h-6 w-6 text-white" />
            </div>
            <h1 className={styles.logoText}>Creator Studio</h1>
          </div>
        </div>
        <h2 className={styles.title}>
          Sign in to your account
        </h2>
        <p className={styles.subtitle}>
          Or{' '}
          <Link href="/auth/signup" className={styles.link}>
            create a new account
          </Link>
        </p>
      </div>

      <div className={styles.formContainer}>
        <Card>
          <CardHeader>
            <CardTitle className={styles.cardTitle}>Welcome back</CardTitle>
            <CardDescription className={styles.cardDescription}>
              Sign in to access your creator dashboard
            </CardDescription>
          </CardHeader>
          <CardContent className={styles.cardContent}>
            <form className={styles.form}>
              <div className={styles.field}>
                <Label htmlFor="email">Email address</Label>
                <div className={styles.inputWrapper}>
                  <Input
                    id="email"
                    name="email"
                    type="email"
                    autoComplete="email"
                    required
                    placeholder="Enter your email"
                  />
                </div>
              </div>

              <div className={styles.field}>
                <div className={styles.passwordHeader}>
                  <Label htmlFor="password">Password</Label>
                  <Link
                    href="/auth/forgot-password"
                    className={styles.forgotLink}
                  >
                    Forgot your password?
                  </Link>
                </div>
                <div className={styles.inputWrapper}>
                  <Input
                    id="password"
                    name="password"
                    type="password"
                    autoComplete="current-password"
                    required
                    placeholder="Enter your password"
                  />
                </div>
              </div>

              <div className={styles.submitWrapper}>
                <Button type="submit" className="w-full">
                  Sign in
                </Button>
              </div>
            </form>

            <div className={styles.socialSection}>
              <div className={styles.divider}>
                <div className={styles.dividerLine} />
                <div className={styles.dividerText}>
                  <span>Or continue with</span>
                </div>
              </div>

              <div className={styles.socialButton}>
                <Button variant="outline" className="w-full">
                  <svg className="mr-2 h-4 w-4" viewBox="0 0 24 24">
                    <path
                      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                      fill="#4285F4"
                    />
                    <path
                      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                      fill="#34A853"
                    />
                    <path
                      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                      fill="#FBBC05"
                    />
                    <path
                      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                      fill="#EA4335"
                    />
                  </svg>
                  Continue with Google
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        <div className={styles.demoInfo}>
          <p>
            Demo accounts: creator@hingetrade.com | admin@hingetrade.com
            <br />
            Password: password
          </p>
        </div>
      </div>
    </div>
  )
}