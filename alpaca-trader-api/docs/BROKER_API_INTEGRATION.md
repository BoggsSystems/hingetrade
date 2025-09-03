# Alpaca Broker API Integration Guide

This document describes how the Alpaca Trader API integrates with Alpaca's Broker API, including key differences from the standard Trading API and special considerations.

## Overview

The Alpaca Trader API supports both the standard Trading API and the Broker API. The Broker API is designed for applications that manage multiple trading accounts under a single master account.

## Key Differences Between Trading API and Broker API

### 1. Authentication

- **Trading API**: Uses custom headers (`APCA-API-KEY-ID` and `APCA-API-SECRET-KEY`)
- **Broker API**: Uses HTTP Basic Authentication with the same credentials

The API automatically detects which authentication method to use based on the API endpoint URL.

### 2. API Endpoints

- **Trading API Base URL**: `https://api.alpaca.markets` (production) or `https://paper-api.alpaca.markets` (paper)
- **Broker API Base URL**: `https://broker-api.alpaca.markets` (production) or `https://broker-api.sandbox.alpaca.markets` (sandbox)

### 3. Account Structure

- **Trading API**: Single account per API key
- **Broker API**: Multiple sub-accounts under a master account

### 4. Endpoint Paths

| Operation | Trading API | Broker API |
|-----------|-------------|------------|
| Get Account | `/v2/account` | `/v1/trading/accounts/{account_id}/account` |
| Get Positions | `/v2/positions` | `/v1/trading/accounts/{account_id}/positions` |
| Create Order | `/v2/orders` | `/v1/trading/accounts/{account_id}/orders` |
| List Accounts | N/A | `/v1/accounts` |

## Implementation Details

### Account Linking

When linking an Alpaca account, the system automatically detects if it's a Broker API account:

```csharp
// In AccountsService.cs
var isBrokerApi = request.IsBrokerApi || _alpacaSettings.BaseUrl.Contains("broker-api");
```

For Broker API accounts:
1. The system fetches all available accounts using `/v1/accounts`
2. Selects the first active account (or uses the provided broker account ID)
3. Stores the broker account ID for future API calls

### JSON Deserialization

The Broker API returns numeric values as strings (e.g., `"24190.64"` instead of `24190.64`). The API handles this with custom JSON converters:

- `FlexibleDecimalConverter`: Handles both numeric and string decimal values
- `FlexibleNullableDecimalConverter`: Handles nullable decimal properties

These converters are automatically applied to all Alpaca API responses.

### AlpacaClient Configuration

The `AlpacaClient` class automatically:
- Detects the API type based on the URL
- Sets appropriate authentication headers
- Routes requests to the correct endpoints
- Applies custom JSON serialization options

## Testing with Mock Server

For development and testing, a mock Alpaca server is provided:

```bash
# Start the mock server
cd tests/MockAlpacaServer
dotnet run

# The mock server runs on http://localhost:5001
```

The mock server:
- Simulates Broker API responses with string-encoded decimals
- Requires Basic Authentication
- Supports the main account and trading endpoints
- Returns test data for account `920964623`

## Configuration

### Development Configuration

In `appsettings.Development.json`:

```json
{
  "Alpaca": {
    "Env": "sandbox",
    "BaseUrl": "http://localhost:5001",  // For mock server
    "MarketDataUrl": "wss://stream.data.sandbox.alpaca.markets/v2/sip"
  }
}
```

### Production Configuration

For production Broker API:

```json
{
  "Alpaca": {
    "Env": "live",
    "BaseUrl": "https://broker-api.alpaca.markets",
    "MarketDataUrl": "wss://stream.data.alpaca.markets/v2/sip"
  }
}
```

## API Usage Examples

### Link a Broker API Account

```bash
curl -X POST http://localhost:5000/api/account/link \
  -H "Content-Type: application/json" \
  -H "X-Demo-User-Id: test-user" \
  -d '{
    "apiKeyId": "YOUR_API_KEY",
    "apiSecret": "YOUR_API_SECRET",
    "env": "paper",
    "isBrokerApi": true,
    "brokerAccountId": "920964623"  // Optional
  }'
```

### Get Account Details

```bash
curl http://localhost:5000/api/account \
  -H "X-Demo-User-Id: test-user"
```

## Troubleshooting

### 403 Forbidden Errors

- Verify the API credentials are valid
- Ensure you're using the correct API type (Trading vs Broker)
- Check that the broker account ID exists and is accessible

### JSON Deserialization Errors

The custom JSON converters should handle string-encoded decimals automatically. If you encounter issues:
1. Check that `AlpacaJsonOptions.Default` is being used for all deserialization
2. Verify the response format matches expected models
3. Enable debug logging to see the raw JSON response

### Authentication Issues

- Broker API requires Basic Authentication
- Trading API requires custom headers
- The system auto-detects based on the URL, but you can force it with `isBrokerApi: true`

## Security Considerations

1. API credentials are encrypted using AES-GCM before storage
2. Each user can only access their own linked accounts
3. Broker account IDs are validated before use
4. All API calls use HTTPS in production

## Future Enhancements

1. Support for multiple broker accounts per user
2. Account switching in the UI
3. Webhook support for Broker API events
4. Advanced order types specific to Broker API