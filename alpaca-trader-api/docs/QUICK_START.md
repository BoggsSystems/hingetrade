# Quick Start Guide

This guide helps you get the Alpaca Trader API up and running quickly.

## Prerequisites

- .NET 9 SDK
- Docker and Docker Compose
- PostgreSQL client tools (optional, for database access)

## Step 1: Start External Dependencies

The application requires PostgreSQL, Redis, and MailHog. Use Docker Compose to start them:

```bash
# Start all dependencies
docker-compose up -d

# Verify they're running
docker ps

# You should see:
# - PostgreSQL on port 5432
# - Redis on port 6379
# - MailHog on ports 1025 (SMTP) and 8025 (Web UI)
```

## Step 2: Set Up the Database

The application will automatically create the database schema on first run in development mode. No manual migration is needed.

## Step 3: Configure the Application

### For Development (with Mock Alpaca Server)

1. Start the mock Alpaca server:
   ```bash
   cd tests/MockAlpacaServer
   dotnet run
   # Runs on http://localhost:5001
   ```

2. The development configuration is already set to use the mock server.

### For Testing with Real Alpaca API

1. Edit `src/TraderApi/appsettings.Development.json`:
   ```json
   {
     "Alpaca": {
       "BaseUrl": "https://broker-api.sandbox.alpaca.markets"
     }
   }
   ```

## Step 4: Run the API

```bash
cd src/TraderApi
ASPNETCORE_ENVIRONMENT=Development dotnet run
```

The API will start on `http://localhost:5000`.

## Step 5: Test the API

### Health Check
```bash
curl http://localhost:5000/health
```

Expected response:
```json
{
  "status": "degraded",
  "timestamp": "2024-03-15T10:00:00Z",
  "services": {
    "database": {"status": "healthy"},
    "redis": {"status": "healthy"},
    "alpaca": {"status": "not_configured"}
  }
}
```

### Link an Alpaca Account (Demo Mode)

With demo authentication enabled:

```bash
curl -X POST http://localhost:5000/api/account/link \
  -H "Content-Type: application/json" \
  -H "X-Demo-User-Id: test-user" \
  -d '{
    "apiKeyId": "CKB4051UELTQZSUS78S8",
    "apiSecret": "ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA",
    "env": "paper",
    "isBrokerApi": true,
    "brokerAccountId": "920964623"
  }'
```

### Get Account Details

```bash
curl http://localhost:5000/api/account \
  -H "X-Demo-User-Id: test-user"
```

## Step 6: Access Supporting Services

- **MailHog Web UI**: http://localhost:8025
  - View all emails sent by the application
  
- **PostgreSQL**: 
  ```bash
  psql -h localhost -U postgres -d alpaca_trader
  # Password: postgres
  ```

## Troubleshooting

### Redis Connection Errors

If you see Redis connection errors in the logs:
1. Ensure Redis is running: `docker ps | grep redis`
2. Check Redis connectivity: `redis-cli ping`
3. Restart Redis if needed: `docker-compose restart redis`

### Database Connection Issues

1. Check PostgreSQL is running: `docker ps | grep postgres`
2. Verify connection: `psql -h localhost -U postgres -c "SELECT 1"`
3. Check logs: `docker-compose logs postgres`

### Mock Server Issues

If the mock Alpaca server stops:
1. Check if it's still running
2. Restart it: `cd tests/MockAlpacaServer && dotnet run`
3. Ensure port 5001 is not in use by another process

## Next Steps

1. **Configure Auth0** for production authentication
2. **Set up real Alpaca credentials** for live trading
3. **Deploy to production** using the Kubernetes manifests
4. **Set up monitoring** with OpenTelemetry

## Development Tips

### Running Tests
```bash
dotnet test
```

### Watching for Changes
```bash
dotnet watch run
```

### Checking Code Quality
```bash
dotnet format
dotnet build -warnaserror
```

### Database Migrations (if needed)
```bash
# Add a migration
dotnet ef migrations add MigrationName

# Update database
dotnet ef database update
```

## Security Notes

- Demo authentication is enabled by default in development
- Never use demo auth in production
- Always use HTTPS in production
- Keep your Alpaca API keys secure
- Use environment variables or secure key management for production