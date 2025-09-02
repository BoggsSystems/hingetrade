# Creator Studio

A comprehensive video creation and monetization platform for trading content creators built with Next.js 14, Prisma, and TypeScript.

## Features

- **Video Creation & Management**: Upload, record, and manage trading videos
- **AI-Powered Enhancement**: Automatic transcription, symbol detection, and chart synchronization
- **Monetization**: Multiple revenue streams including subscriptions, sponsorships, and copy-trading
- **Analytics**: Comprehensive insights into audience engagement and revenue
- **Content Moderation**: Built-in compliance tools and review workflows
- **Creator Tools**: Professional dashboard for content creators

## Tech Stack

- **Frontend**: Next.js 14 (App Router), React 18, TypeScript
- **Styling**: Tailwind CSS, shadcn/ui components
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: NextAuth.js with JWT sessions
- **File Storage**: S3-compatible storage (MinIO for development)
- **Background Jobs**: BullMQ with Redis
- **Email**: SMTP integration (MailHog for development)

## Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL database
- Redis server
- S3-compatible storage (MinIO for development)

### Installation

1. **Clone and setup**:
   ```bash
   cd creator-studio
   npm install
   ```

2. **Environment Configuration**:
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your configuration
   ```

3. **Database Setup**:
   ```bash
   # Generate Prisma client
   npm run db:generate
   
   # Run database migrations
   npm run db:migrate
   
   # Seed database with demo data
   npm run db:seed
   ```

4. **Start Development Server**:
   ```bash
   npm run dev
   ```

The application will be available at `http://localhost:3001`.

### Demo Users

After seeding the database:

- **Admin**: admin@hingetrade.com (password: password)
- **Creator**: creator@hingetrade.com (password: password)
- **Moderator**: moderator@hingetrade.com (password: password)

## Project Structure

```
creator-studio/
├── src/
│   ├── app/                 # Next.js App Router pages
│   │   ├── auth/           # Authentication pages
│   │   ├── dashboard/      # Creator dashboard
│   │   └── ...
│   ├── components/         # React components
│   │   ├── ui/            # Reusable UI components
│   │   └── ...
│   ├── lib/               # Utility functions
│   ├── hooks/             # Custom React hooks
│   ├── types/             # TypeScript definitions
│   └── server/            # Server-side code (tRPC, etc.)
├── prisma/
│   ├── schema.prisma      # Database schema
│   └── seed.ts           # Database seeding
├── public/               # Static assets
└── ...
```

## Key Features

### Authentication & Authorization
- Role-based access control (viewer, trader, creator, moderator, admin)
- NextAuth.js integration with multiple providers
- Secure session management

### Video Management
- Upload videos or record directly in browser
- AI-powered transcription and enhancement
- Chart context synchronization
- Scheduled publishing

### Monetization
- Multiple revenue streams
- Subscription tiers
- Sponsorship management
- Payout processing

### Analytics
- Performance tracking
- Audience insights
- Revenue analytics
- Growth metrics

### Content Moderation
- Automated compliance checks
- Manual review workflows
- Policy violation detection
- Escalation procedures

## Development

### Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint
- `npm run typecheck` - Run TypeScript checks
- `npm run db:generate` - Generate Prisma client
- `npm run db:push` - Push schema changes to database
- `npm run db:migrate` - Run database migrations
- `npm run db:seed` - Seed database with demo data

### Environment Variables

Key environment variables (see `.env.example` for complete list):

- `DATABASE_URL` - PostgreSQL connection string
- `NEXTAUTH_SECRET` - Secret for JWT signing
- `REDIS_URL` - Redis connection string
- `S3_*` - S3/MinIO storage configuration
- `SMTP_*` - Email configuration

## Deployment

The application is designed for easy deployment with:

- **Docker**: Multi-stage builds for production
- **Vercel/Netlify**: For serverless deployment
- **Traditional hosting**: With PM2 or similar process managers

### Production Checklist

- [ ] Set production environment variables
- [ ] Configure database with connection pooling
- [ ] Set up Redis cluster
- [ ] Configure S3 storage with CDN
- [ ] Set up email service (SendGrid, SES, etc.)
- [ ] Configure monitoring and logging
- [ ] Set up SSL certificates
- [ ] Configure domain and DNS

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is private and proprietary to HingeTrade. All rights reserved.