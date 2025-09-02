import { PrismaClient, Role } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Seeding database...')

  // Create users with different roles
  const admin = await prisma.user.upsert({
    where: { email: 'admin@hingetrade.com' },
    update: {},
    create: {
      email: 'admin@hingetrade.com',
      name: 'Admin User',
      role: Role.admin,
    },
  })

  const moderator = await prisma.user.upsert({
    where: { email: 'moderator@hingetrade.com' },
    update: {},
    create: {
      email: 'moderator@hingetrade.com',
      name: 'Moderator User',
      role: Role.moderator,
    },
  })

  const creator = await prisma.user.upsert({
    where: { email: 'creator@hingetrade.com' },
    update: {},
    create: {
      email: 'creator@hingetrade.com',
      name: 'Creator User',
      role: Role.creator,
    },
  })

  const trader = await prisma.user.upsert({
    where: { email: 'trader@hingetrade.com' },
    update: {},
    create: {
      email: 'trader@hingetrade.com',
      name: 'Trader User',
      role: Role.trader,
    },
  })

  const viewer = await prisma.user.upsert({
    where: { email: 'viewer@hingetrade.com' },
    update: {},
    create: {
      email: 'viewer@hingetrade.com',
      name: 'Viewer User',
      role: Role.viewer,
    },
  })

  // Create creator profile
  const creatorProfile = await prisma.creatorProfile.upsert({
    where: { userId: creator.id },
    update: {},
    create: {
      userId: creator.id,
      displayName: 'Trading Pro',
      bio: 'Professional trader sharing market insights and strategies for over 10 years. Specialized in technical analysis and options trading.',
      socials: {
        twitter: '@tradingpro',
        youtube: 'TradingProChannel',
        tiktok: '@tradingpro',
        instagram: '@tradingpro',
      },
      isActive: true,
      taxStatus: 'w9_submitted',
      payoutStatus: 'verified',
    },
  })

  // Create sample videos
  const video1 = await prisma.video.create({
    data: {
      creatorId: creator.id,
      title: 'TSLA Technical Analysis - Breakout Strategy Explained',
      description: 'In this video, I break down Tesla\'s current chart patterns and explain my breakout strategy. We\'ll cover key support and resistance levels, volume analysis, and potential price targets for the upcoming weeks.',
      status: 'published',
      publishedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
      audience: 'public',
      allowCopyTrades: true,
      disclosures: {
        notAdvice: true,
        riskWarning: true,
      },
      sponsorship: {
        enabled: false,
      },
    },
  })

  const video2 = await prisma.video.create({
    data: {
      creatorId: creator.id,
      title: 'Options Trading Strategy for AAPL Earnings',
      description: 'Weekly options strategy for Apple earnings play. Learn how to position for earnings volatility while managing risk effectively.',
      status: 'needs_review',
      audience: 'subscribers',
      allowCopyTrades: false,
      disclosures: {
        notAdvice: true,
        riskWarning: true,
      },
      sponsorship: {
        enabled: true,
        brand: 'TradingView',
      },
    },
  })

  const video3 = await prisma.video.create({
    data: {
      creatorId: creator.id,
      title: 'Market Update: Fed Decision Impact Analysis',
      description: 'Quick market update covering the Fed decision and its impact on major indices and sectors.',
      status: 'draft',
      audience: 'public',
      allowCopyTrades: false,
      disclosures: {
        notAdvice: true,
        riskWarning: true,
      },
    },
  })

  // Create chart contexts
  await prisma.chartContext.create({
    data: {
      videoId: video1.id,
      symbol: 'TSLA',
      timeframe: '1h',
      indicators: {
        rsi: { enabled: true, period: 14 },
        macd: { enabled: true },
        sma: { enabled: true, periods: [20, 50] },
        ema: { enabled: true, periods: [12, 26] },
      },
      levels: [
        { price: 250.00, type: 'support', strength: 'strong' },
        { price: 280.00, type: 'resistance', strength: 'medium' },
        { price: 300.00, type: 'resistance', strength: 'strong' },
      ],
      syncCues: [
        { timestamp: 30, description: 'RSI oversold signal', price: 245.50 },
        { timestamp: 120, description: 'Breakout confirmation', price: 282.75 },
        { timestamp: 240, description: 'Volume spike analysis', price: 285.00 },
      ],
    },
  })

  // Create NLP extraction
  await prisma.nlpExtraction.create({
    data: {
      videoId: video1.id,
      symbols: ['TSLA', 'QQQ', 'SPY'],
      timeframe: '1h',
      indicators: {
        rsi: true,
        macd: true,
        sma: true,
        ema: true,
        bollinger: false,
      },
      priceLevels: [
        { level: 250.00, type: 'support' },
        { level: 280.00, type: 'resistance' },
        { level: 300.00, type: 'resistance' },
      ],
      patterns: {
        bullishFlag: { confidence: 0.8 },
        breakout: { confidence: 0.9 },
        triangle: { confidence: 0.6 },
      },
      confidence: 0.85,
    },
  })

  // Create transcripts
  await prisma.transcript.create({
    data: {
      videoId: video1.id,
      language: 'en',
      text: 'Hello everyone, welcome back to my channel. Today we\'re going to be looking at Tesla, ticker symbol TSLA. As you can see on the chart, we have a really interesting setup forming here...',
      words: [
        { word: 'Hello', start: 0.5, end: 1.0, confidence: 0.99 },
        { word: 'everyone,', start: 1.0, end: 1.8, confidence: 0.98 },
        { word: 'welcome', start: 1.8, end: 2.3, confidence: 0.99 },
        // ... more words would be here
      ],
    },
  })

  // Create earnings records
  await prisma.earning.create({
    data: {
      videoId: video1.id,
      creatorId: creator.id,
      impressions: 15420,
      rpm: 2.8,
      revenueCents: 4317, // $43.17
      periodStart: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      periodEnd: new Date(),
    },
  })

  await prisma.earning.create({
    data: {
      videoId: video2.id,
      creatorId: creator.id,
      impressions: 8930,
      rpm: 3.2,
      revenueCents: 2858, // $28.58
      periodStart: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      periodEnd: new Date(),
    },
  })

  // Create payout account
  await prisma.payoutAccount.create({
    data: {
      creatorId: creator.id,
      provider: 'stripe',
      accountRef: 'acct_1234567890',
      status: 'verified',
    },
  })

  // Create subscription tiers
  await prisma.subscriptionTier.create({
    data: {
      creatorId: creatorProfile.id,
      name: 'Basic Tier',
      priceCents: 999, // $9.99
      benefits: {
        features: [
          'Access to subscriber-only videos',
          'Weekly market updates',
          'Comment priority',
        ],
      },
      isActive: true,
    },
  })

  await prisma.subscriptionTier.create({
    data: {
      creatorId: creatorProfile.id,
      name: 'Premium Alerts',
      priceCents: 2999, // $29.99
      benefits: {
        features: [
          'All Basic features',
          'Real-time trade alerts',
          'Daily market analysis',
          'Private Discord access',
          'Strategy backtests',
        ],
      },
      isActive: true,
    },
  })

  await prisma.subscriptionTier.create({
    data: {
      creatorId: creatorProfile.id,
      name: 'VIP Membership',
      priceCents: 9999, // $99.99
      benefits: {
        features: [
          'All Premium features',
          '1-on-1 monthly call',
          'Portfolio reviews',
          'Custom trade alerts',
          'Priority support',
        ],
      },
      isActive: true,
    },
  })

  // Create audit logs
  await prisma.auditLog.create({
    data: {
      userId: creator.id,
      entityType: 'video',
      entityId: video1.id,
      action: 'publish',
      meta: {
        previousStatus: 'approved',
        newStatus: 'published',
      },
    },
  })

  await prisma.auditLog.create({
    data: {
      userId: creator.id,
      entityType: 'creator_profile',
      entityId: creatorProfile.id,
      action: 'update',
      meta: {
        fields: ['bio', 'socials'],
      },
    },
  })

  // Create moderation flags for testing
  await prisma.moderationFlag.create({
    data: {
      videoId: video2.id,
      type: 'sponsor_disclosure',
      severity: 'medium',
      notes: 'Video mentions TradingView but sponsorship disclosure may need to be more prominent',
    },
  })

  console.log('✅ Database seeded successfully!')
  console.log('👥 Demo users created:')
  console.log('  - admin@hingetrade.com (admin)')
  console.log('  - moderator@hingetrade.com (moderator)')
  console.log('  - creator@hingetrade.com (creator)')
  console.log('  - trader@hingetrade.com (trader)')
  console.log('  - viewer@hingetrade.com (viewer)')
  console.log('🔑 All users have password: "password"')
  console.log(`📹 Created ${await prisma.video.count()} sample videos`)
  console.log(`💰 Created ${await prisma.subscriptionTier.count()} subscription tiers`)
  console.log(`📊 Created ${await prisma.earning.count()} earning records`)
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })