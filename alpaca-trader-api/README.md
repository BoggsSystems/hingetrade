# Alpaca Trader API

Production-ready ASP.NET Core 9 backend for Alpaca-powered trading. This is a thin BFF (Backend for Frontend) over the Alpaca API that never exposes Alpaca keys to the browser.

## Features

- 🔐 JWT Authentication with Auth0
- 📊 Account, Positions, and Orders management
- 📋 Watchlists with symbol tracking
- 🔔 Price alerts with real-time monitoring
- 🎯 Risk management with configurable guardrails
- 🪝 Webhook support for trade/account updates
- 🏦 **Dual API Support** - Works with both Alpaca Trading API and Broker API
- 🧪 **Mock Server** - Built-in mock Alpaca server for development
- 🚀 Production-ready with Docker, K8s, and CI/CD
- 📝 Full OpenAPI/Swagger documentation

## Prerequisites

- .NET 9 SDK
- Docker & Docker Compose
- PostgreSQL 16 (or use Docker)
- Redis 7 (or use Docker)
- Auth0 account (free tier works)
- Alpaca account with paper trading API keys

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/yourusername/alpaca-trader-api.git
cd alpaca-trader-api
```

### 2. Configure Environment

Create a `.env` file in the root:

```env
# Auth0 Configuration
AUTH0_AUTHORITY=https://YOUR_TENANT.auth0.com/
AUTH0_AUDIENCE=alpaca-trader-api

# Encryption key for storing Alpaca secrets
KEY_PROTECTION_KEY=your-32-character-encryption-key

# Webhook secret for Alpaca webhooks
WEBHOOK_SECRET=your-webhook-secret
```

### 3. Start Dependencies

```bash
docker compose -f deploy/docker-compose.yml up -d postgres redis mailhog
```

### 4. Run Database Migrations

```bash
cd src/TraderApi
dotnet ef database update
```

### 5. Run the API

```bash
dotnet run
```

The API will be available at:
- API: http://localhost:5000
- Swagger UI: http://localhost:5000/swagger
- MailHog UI: http://localhost:8025

## Auth0 Setup

1. Create a new API in Auth0 Dashboard
2. Set identifier as `alpaca-trader-api`
3. Note your Auth0 domain (e.g., `your-tenant.auth0.com`)
4. Create a Machine-to-Machine application for testing
5. Authorize it for your API with necessary scopes

## Alpaca Setup

1. Sign up for Alpaca and get paper trading API keys
2. Note your API Key ID and Secret Key
3. For production, generate separate live trading keys
4. Configure webhook endpoint: `https://your-domain.com/api/webhooks/alpaca`

### Broker API Support

The API supports both standard Trading API and Broker API accounts. For Broker API:

1. Use Broker API credentials when linking
2. Set `isBrokerApi: true` when linking account
3. Optionally provide `brokerAccountId` for specific account
4. See [Broker API Integration Guide](docs/BROKER_API_INTEGRATION.md) for details

## API Endpoints

### Health & Meta
- `GET /health` - Health check with service status
- `GET /me` - Get current user profile

### Accounts
- `GET /api/account` - Get Alpaca account details
- `POST /api/account/link` - Link Alpaca API credentials

### Positions
- `GET /api/positions` - Get all open positions

### Orders
- `GET /api/orders?status=open&limit=50` - Get orders
- `POST /api/orders` - Create new order with risk checks
- `DELETE /api/orders/{id}` - Cancel order

### Watchlists
- `GET /api/watchlists` - Get user's watchlists
- `POST /api/watchlists` - Create watchlist
- `POST /api/watchlists/{id}/symbols` - Add symbol
- `DELETE /api/watchlists/{id}/symbols/{symbol}` - Remove symbol

### Alerts
- `GET /api/alerts` - Get price alerts
- `POST /api/alerts` - Create alert
- `PATCH /api/alerts/{id}` - Update alert
- `DELETE /api/alerts/{id}` - Delete alert

### Webhooks
- `POST /api/webhooks/alpaca` - Receive Alpaca webhooks

## Example Requests

### Link Alpaca Account

```bash
# Standard Trading API
curl -X POST http://localhost:5000/api/account/link \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "apiKeyId": "YOUR_ALPACA_KEY_ID",
    "apiSecret": "YOUR_ALPACA_SECRET",
    "env": "paper"
  }'

# Broker API
curl -X POST http://localhost:5000/api/account/link \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "apiKeyId": "YOUR_BROKER_KEY_ID",
    "apiSecret": "YOUR_BROKER_SECRET",
    "env": "paper",
    "isBrokerApi": true,
    "brokerAccountId": "920964623"
  }'
```

### Create Order

```bash
curl -X POST http://localhost:5000/api/orders \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientOrderId": "my-order-001",
    "symbol": "AAPL",
    "side": "buy",
    "type": "limit",
    "qty": 10,
    "limitPrice": 150.00,
    "timeInForce": "day"
  }'
```

### Create Price Alert

```bash
curl -X POST http://localhost:5000/api/alerts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "AAPL",
    "operator": ">",
    "threshold": 155.00,
    "active": true
  }'
```

## Risk Management

The API enforces these risk rules (configurable in appsettings.json):

- **Max Order Notional**: $25,000 per order
- **Max Share Quantity**: 5,000 shares per order
- **Symbol Whitelist**: Only allowed symbols (AAPL, MSFT, SPY, etc.)
- **Trading Hours**: Regular market hours only (9:30 AM - 4:00 PM ET)
- **Idempotency**: Requires unique `clientOrderId` for each order

## Development

### Run Tests

```bash
cd tests/TraderApi.Tests
dotnet test
```

### Run with Mock Alpaca Server

For development without real Alpaca credentials:

```bash
# Terminal 1: Start mock Alpaca server
cd tests/MockAlpacaServer
dotnet run

# Terminal 2: Run the API
cd src/TraderApi
ASPNETCORE_ENVIRONMENT=Development dotnet run
```

The mock server simulates Broker API responses with test data.

### Run with Docker Compose

```bash
docker compose -f deploy/docker-compose.yml up
```

### Database Migrations

```bash
# Create new migration
dotnet ef migrations add MigrationName

# Update database
dotnet ef database update

# Generate SQL script
dotnet ef migrations script
```

## Production Deployment

### Docker

```bash
# Build image
docker build -f deploy/Dockerfile -t alpaca-trader-api .

# Run container
docker run -p 8080:8080 \
  -e ConnectionStrings__Postgres="..." \
  -e Auth__Authority="..." \
  alpaca-trader-api
```

### Kubernetes

1. Update secrets in `deploy/k8s.yaml`
2. Deploy:

```bash
kubectl apply -f deploy/k8s.yaml
```

### Environment Variables

See `appsettings.json` for all configuration options. Key variables:

- `ASPNETCORE_ENVIRONMENT`: Development, Staging, or Production
- `ConnectionStrings__Postgres`: PostgreSQL connection string
- `Redis__Connection`: Redis connection string
- `Auth__Authority`: Auth0 domain (with https://)
- `Auth__Audience`: API identifier in Auth0
- `Alpaca__Env`: "paper" or "live"
- `Alpaca__BaseUrl`: Alpaca API URL
- `KeyProtection__Key`: Encryption key for secrets
- `Webhook__SigningSecret`: Shared secret for webhooks

## Safety Checklist Before Going Live

- [ ] Change `Alpaca__Env` to "live" and update `Alpaca__BaseUrl`
- [ ] Review and adjust risk limits in `Risk` settings
- [ ] Update symbol allowlist for your trading strategy
- [ ] Enable webhook signature verification
- [ ] Use strong encryption key for `KeyProtection__Key`
- [ ] Set up monitoring and alerting
- [ ] Configure rate limiting appropriately
- [ ] Review Auth0 token expiration settings
- [ ] Set up database backups
- [ ] Configure CORS for your frontend domain only
- [ ] Enable HTTPS with valid certificates
- [ ] Set up error tracking (e.g., Sentry)
- [ ] Configure structured logging output
- [ ] Review and test all risk rules
- [ ] Set up kill switch feature flag

## Architecture Notes

- **Minimal APIs**: Uses .NET 8 minimal APIs for reduced overhead
- **Feature Folders**: Organized by feature for better maintainability
- **Encryption**: Alpaca secrets encrypted at rest using AES-GCM
- **Background Jobs**: Alerts processed by hosted service with Redis locks
- **Idempotency**: Client-provided order IDs prevent duplicates
- **Rate Limiting**: Per-user and IP-based rate limiting
- **Health Checks**: Database, Redis, and Alpaca connectivity monitored

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details