'use client';

import { useState, useEffect, useRef } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { 
  Video, 
  Users, 
  DollarSign, 
  BarChart3, 
  Upload,
  Play,
  Eye,
  TrendingUp,
  Clock,
  User,
  LogOut,
  Settings,
  ChevronDown,
  Loader2
} from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'
import { useAnalytics } from '@/hooks/useAnalytics'
import UploadVideoModal from '@/components/modals/UploadVideoModal'
import VideoList from '@/components/VideoList'
import styles from './dashboard.module.css'

export default function DashboardPage() {
  console.log('🚀 Dashboard page is loading...')
  console.log('📱 Dashboard styles:', styles)
  
  const { user, logout } = useAuth()
  const { dashboardData, loading, error, refresh } = useAnalytics()
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false)
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false)
  const userMenuRef = useRef<HTMLDivElement>(null)


  const [refreshVideos, setRefreshVideos] = useState(0)

  // Helper functions
  const formatNumber = (num: number) => {
    if (num >= 1000000) {
      return (num / 1000000).toFixed(1) + 'M'
    }
    if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'k'
    }
    return num.toString()
  }

  const formatWatchTime = (hours: number) => {
    if (hours >= 1000) {
      return (hours / 1000).toFixed(1) + 'k hours'
    }
    return Math.round(hours) + 'h'
  }

  const formatGrowthPercentage = (percentage: number) => {
    const rounded = Math.round(percentage)
    return rounded >= 0 ? `+${rounded}%` : `${rounded}%`
  }

  const handleLogout = async () => {
    try {
      await logout()
    } catch (error) {
      console.error('Logout failed:', error)
    }
  }


  // Close user menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setIsUserMenuOpen(false)
      }
    }

    if (isUserMenuOpen) {
      document.addEventListener('mousedown', handleClickOutside)
      return () => document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [isUserMenuOpen])

  console.log('📊 Dashboard data:', { dashboardData, loading, error })
  
  // Log for debugging
  console.log('🎨 Rendering dashboard with className:', styles.dashboard)

  // Show loading state
  if (loading) {
    return (
      <div className={styles.dashboard}>
        <div className="flex items-center justify-center min-h-screen">
          <div className="flex items-center gap-2">
            <Loader2 className="h-6 w-6 animate-spin" />
            <span>Loading analytics...</span>
          </div>
        </div>
      </div>
    )
  }

  // Show error state (but continue to show the UI with fallback data)
  const showErrorBanner = error && !dashboardData
  
  return (
    <div className={styles.dashboard}>
      {/* Header */}
      <header className={styles.header}>
        <div className={styles.headerContainer}>
          <div className={styles.headerContent}>
            <div className={styles.logo}>
              <div className={styles.logoIcon}>
                <Video className="h-5 w-5 text-white" />
              </div>
              <h1 className={styles.logoText}>Creator Studio</h1>
            </div>
            <div className={styles.headerActions}>
              <Button variant="outline" size="sm">
                <BarChart3 className="mr-2 h-4 w-4" />
                Analytics
              </Button>
              <Button size="sm" onClick={() => setIsUploadModalOpen(true)}>
                <Upload className="mr-2 h-4 w-4" />
                Upload Video
              </Button>
              
              {/* User Menu */}
              <div className={styles.userMenu} ref={userMenuRef}>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
                  className={styles.userMenuButton}
                >
                  <User className="mr-2 h-4 w-4" />
                  {user?.firstName || user?.email || 'User'}
                  <ChevronDown className="ml-2 h-4 w-4" />
                </Button>
                
                {isUserMenuOpen && (
                  <div className={styles.userMenuDropdown}>
                    <div className={styles.userInfo}>
                      <div className={styles.userAvatar}>
                        <User className="h-5 w-5" />
                      </div>
                      <div className={styles.userDetails}>
                        <div className={styles.userName}>
                          {user?.firstName && user?.lastName 
                            ? `${user.firstName} ${user.lastName}` 
                            : user?.email
                          }
                        </div>
                        <div className={styles.userEmail}>{user?.email}</div>
                      </div>
                    </div>
                    
                    <div className={styles.menuDivider}></div>
                    
                    <button className={styles.menuItem}>
                      <Settings className="h-4 w-4" />
                      Settings
                    </button>
                    
                    <button 
                      className={styles.menuItem} 
                      onClick={handleLogout}
                    >
                      <LogOut className="h-4 w-4" />
                      Logout
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </header>

      <div className={styles.container}>
        {/* Welcome Section */}
        <div className={styles.welcome}>
          <h2 className={styles.welcomeTitle}>Welcome back!</h2>
          <p className={styles.welcomeDescription}>
            Here's what's happening with your content today.
          </p>
        </div>

        {/* Error Banner */}
        {showErrorBanner && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-800 text-sm">
              ⚠️ Unable to load analytics data: {error}. Showing default values.
            </p>
          </div>
        )}


        {/* Stats Grid */}
        <div className={styles.statsGrid}>
          <Card>
            <CardHeader className={styles.statHeader}>
              <CardTitle className={styles.statTitle}>Total Videos</CardTitle>
              <Video className={styles.statIcon} />
            </CardHeader>
            <CardContent>
              <div className={styles.statValue}>{dashboardData?.totalVideos || 0}</div>
              <p className={styles.statSubtext}>
                {dashboardData?.publishedVideos || 0} published
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className={styles.statHeader}>
              <CardTitle className={styles.statTitle}>Total Views</CardTitle>
              <Eye className={styles.statIcon} />
            </CardHeader>
            <CardContent>
              <div className={styles.statValue}>
                {(dashboardData?.totalViews || 0).toLocaleString()}
              </div>
              <p className={styles.statSubtext}>
                {formatWatchTime(dashboardData?.totalWatchTimeHours || 0)} watch time
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className={styles.statHeader}>
              <CardTitle className={styles.statTitle}>Subscribers</CardTitle>
              <Users className={styles.statIcon} />
            </CardHeader>
            <CardContent>
              <div className={styles.statValue}>{dashboardData?.subscribers || 0}</div>
              <p className={styles.statSubtext}>
                {formatGrowthPercentage(dashboardData?.monthlyGrowthPercentage || 0)} from last month
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className={styles.statHeader}>
              <CardTitle className={styles.statTitle}>Revenue</CardTitle>
              <DollarSign className={styles.statIcon} />
            </CardHeader>
            <CardContent>
              <div className={styles.statValue}>
                ${(dashboardData?.revenue || 0).toFixed(2)}
              </div>
              <p className={styles.statSubtext}>
                {formatGrowthPercentage(dashboardData?.thisMonth?.revenueGrowthPercentage || 0)} from last month
              </p>
            </CardContent>
          </Card>
        </div>

        <div className={styles.mainGrid}>
          {/* Recent Videos */}
          <div className={styles.videosSection}>
            <Card>
              <CardHeader>
                <CardTitle>Recent Videos</CardTitle>
                <CardDescription>
                  Your latest video uploads and their performance
                </CardDescription>
              </CardHeader>
              <CardContent>
                <VideoList limit={3} showActions={true} key={refreshVideos} />
                <div style={{ marginTop: 'var(--spacing-lg)' }}>
                  <Button variant="outline" className="w-full">
                    View All Videos
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Quick Actions & Recent Activity */}
          <div className={styles.sidebar}>
            {/* Quick Actions */}
            <Card>
              <CardHeader>
                <CardTitle>Quick Actions</CardTitle>
              </CardHeader>
              <CardContent className={styles.quickActions}>
                <Button className="w-full justify-start" onClick={() => setIsUploadModalOpen(true)}>
                  <Upload className="mr-2 h-4 w-4" />
                  Upload New Video
                </Button>
                <Button variant="outline" className="w-full justify-start">
                  <Video className="mr-2 h-4 w-4" />
                  Record Video
                </Button>
                <Button variant="outline" className="w-full justify-start">
                  <BarChart3 className="mr-2 h-4 w-4" />
                  View Analytics
                </Button>
                <Button variant="outline" className="w-full justify-start">
                  <DollarSign className="mr-2 h-4 w-4" />
                  Payout Settings
                </Button>
              </CardContent>
            </Card>

            {/* Performance Overview */}
            <Card>
              <CardHeader>
                <CardTitle>This Month</CardTitle>
                <CardDescription>Your performance overview</CardDescription>
              </CardHeader>
              <CardContent className={styles.performance}>
                <div className={styles.performanceItem}>
                  <span className={styles.performanceLabel}>Views</span>
                  <div className={styles.performanceValue}>
                    <span className={styles.performanceNumber}>
                      {formatNumber(dashboardData?.thisMonth?.views || 0)}
                    </span>
                    <div className={styles.performanceChange}>
                      <TrendingUp className="h-3 w-3" />
                      {formatGrowthPercentage(dashboardData?.thisMonth?.viewsGrowthPercentage || 0)}
                    </div>
                  </div>
                </div>
                <div className={styles.performanceItem}>
                  <span className={styles.performanceLabel}>Watch Time</span>
                  <div className={styles.performanceValue}>
                    <span className={styles.performanceNumber}>
                      {formatWatchTime(dashboardData?.thisMonth?.watchTimeHours || 0)}
                    </span>
                    <div className={styles.performanceChange}>
                      <TrendingUp className="h-3 w-3" />
                      {formatGrowthPercentage(dashboardData?.thisMonth?.watchTimeGrowthPercentage || 0)}
                    </div>
                  </div>
                </div>
                <div className={styles.performanceItem}>
                  <span className={styles.performanceLabel}>Revenue</span>
                  <div className={styles.performanceValue}>
                    <span className={styles.performanceNumber}>
                      ${(dashboardData?.thisMonth?.revenue || 0).toFixed(0)}
                    </span>
                    <div className={styles.performanceChange}>
                      <TrendingUp className="h-3 w-3" />
                      {formatGrowthPercentage(dashboardData?.thisMonth?.revenueGrowthPercentage || 0)}
                    </div>
                  </div>
                </div>
                <div className={styles.performanceItem}>
                  <span className={styles.performanceLabel}>Unique Viewers</span>
                  <div className={styles.performanceValue}>
                    <span className={styles.performanceNumber}>
                      {formatNumber(dashboardData?.uniqueViews || 0)}
                    </span>
                    <div className={styles.performanceChange}>
                      <TrendingUp className="h-3 w-3" />
                      {formatGrowthPercentage(dashboardData?.monthlyGrowthPercentage || 0)}
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Tips */}
            <Card>
              <CardHeader>
                <CardTitle>Creator Tip</CardTitle>
              </CardHeader>
              <CardContent>
                <div className={styles.tip}>
                  <div className={styles.tipIcon}>
                    <Clock className="h-4 w-4" style={{ color: 'var(--color-positive)' }} />
                  </div>
                  <div>
                    <h4 className={styles.tipTitle}>Optimal Upload Time</h4>
                    <p className={styles.tipDescription}>
                      Your audience is most active between 6-8 PM EST. 
                      Try scheduling your next video for better engagement!
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Upload Video Modal */}
      <UploadVideoModal
        isOpen={isUploadModalOpen}
        onClose={() => setIsUploadModalOpen(false)}
        onSuccess={(videoData) => {
          console.log('Video uploaded successfully:', videoData);
          setIsUploadModalOpen(false);
          setRefreshVideos(prev => prev + 1); // Refresh the video list
        }}
      />
    </div>
  )
}