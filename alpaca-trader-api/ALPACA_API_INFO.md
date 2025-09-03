# Alpaca API Endpoints and Authentication

## API Types

Alpaca offers different APIs for different purposes:

### 1. Trading API
- **Live Trading**: `https://api.alpaca.markets`
- **Paper Trading**: `https://paper-api.alpaca.markets`
- **Purpose**: Place orders, manage positions, view account info

### 2. Broker API (Alpaca-as-a-Service)
- **Production**: `https://broker-api.alpaca.markets`
- **Sandbox**: `https://broker-api.sandbox.alpaca.markets`
- **Purpose**: For brokers building on Alpaca's infrastructure

### 3. Market Data API
- **Live/Paper**: `https://data.alpaca.markets`
- **Purpose**: Real-time and historical market data

## Which API Do You Need?

Based on your credentials returning "403 Forbidden" on both:
- `https://paper-api.alpaca.markets` (Trading API - Paper)
- `https://broker-api.sandbox.alpaca.markets` (Broker API - Sandbox)

You need to determine which type of Alpaca account you have:

### If you have a Trading Account:
1. Use `https://paper-api.alpaca.markets` for paper trading
2. Use `https://api.alpaca.markets` for live trading
3. Generate keys at: https://app.alpaca.markets/

### If you have a Broker API Account:
1. Use `https://broker-api.sandbox.alpaca.markets` for testing
2. Use `https://broker-api.alpaca.markets` for production
3. Generate keys at: https://broker-api.alpaca.markets/

## Testing Your Credentials

### For Trading API (Most Common):
```bash
curl -H "APCA-API-KEY-ID: YOUR_KEY" \
     -H "APCA-API-SECRET-KEY: YOUR_SECRET" \
     https://paper-api.alpaca.markets/v2/account
```

### For Broker API:
```bash
curl -H "APCA-API-KEY-ID: YOUR_KEY" \
     -H "APCA-API-SECRET-KEY: YOUR_SECRET" \
     https://broker-api.sandbox.alpaca.markets/v1/accounts
```

## Current Configuration

The API is currently configured for standard Paper Trading:
- Base URL: `https://paper-api.alpaca.markets`
- Headers: `APCA-API-KEY-ID` and `APCA-API-SECRET-KEY`

## Troubleshooting 403 Forbidden

1. **Wrong API Type**: Broker API keys won't work with Trading API and vice versa
2. **Wrong Environment**: Live keys won't work with paper endpoint
3. **Account Not Activated**: New accounts may need email verification
4. **IP Restrictions**: Some accounts have IP whitelisting
5. **Expired Keys**: Keys may expire and need regeneration

## Next Steps

1. Confirm which type of Alpaca account you have
2. Generate appropriate API keys for that account type
3. Update the configuration to match your account type
4. Test the connection