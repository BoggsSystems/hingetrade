# Alpha Vantage Integration

## Configuration

The Alpha Vantage API key can be configured in multiple ways:

### Option 1: Environment Variable (Recommended)
Add to your `.env` file:
```
ALPHA_VANTAGE_API_KEY=your-api-key-here
```

### Option 2: AppSettings
Add to `appsettings.json` or `appsettings.Development.json`:
```json
{
  "AlphaVantage": {
    "ApiKey": "your-api-key-here"
  }
}
```

### Option 3: Direct Environment Variable
Set the environment variable before running:
```bash
export ALPHA_VANTAGE_API_KEY=your-api-key-here
dotnet run
```

## Testing the API

Test the symbol search endpoint:
```bash
# Make sure you're logged in first
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  "http://localhost:5001/api/symbols/search?query=AAPL"
```

## Rate Limits
- Free tier: 5 requests per minute
- The client automatically handles rate limiting