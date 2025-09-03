# Alpaca API Connection Troubleshooting

## Current Issue
Both sets of API credentials are returning "403 Forbidden" with message: `{"message": "forbidden."}`

## Checklist to Fix This Issue

### 1. Verify Paper Trading is Enabled
- Log into your Alpaca account at https://app.alpaca.markets/
- Check if you're in "Paper Trading" mode (should see this in the top navigation)
- If not, switch to Paper Trading mode

### 2. Generate New API Keys
1. Go to https://app.alpaca.markets/paper/dashboard/overview
2. Navigate to "Your API Keys" section (usually on the right side)
3. Click "Regenerate" to create new keys
4. Make sure you're generating keys for **Paper Trading**, not Live Trading

### 3. Check API Key Permissions
- Ensure the API keys have the following permissions:
  - Trading: Read/Write
  - Data: Read
  - Account: Read

### 4. Verify Account Status
- Check if your paper trading account is active
- Look for any warnings or notifications about account restrictions
- Ensure you've agreed to all necessary terms and conditions

### 5. Test with Official Alpaca Tool
Try using Alpaca's official API documentation tester:
1. Go to https://docs.alpaca.markets/reference/getaccount
2. Click "Try It" button
3. Enter your API credentials
4. Select "Paper" environment
5. Click "Send API Request"

If this also fails, the issue is definitely with the account/credentials.

### 6. Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| New account | Wait 10-15 minutes after account creation |
| Wrong environment | Ensure using paper-api.alpaca.markets, not api.alpaca.markets |
| IP restrictions | Check if your account has IP whitelisting enabled |
| Expired keys | Generate new keys from the dashboard |

## Once Fixed

When you have working credentials:

1. Update the `.env` file:
```bash
ALPACA_API_KEY_ID=your_new_key_id
ALPACA_API_SECRET=your_new_secret
```

2. Test the connection:
```bash
cd /Users/jeffboggs/hingetrade/alpaca-trader-api/test-alpaca
dotnet run
```

You should see:
```
✅ Success! Connected to Alpaca Paper Trading API
Account Info: { ... account details ... }
```

3. Then run the full API:
```bash
cd /Users/jeffboggs/hingetrade/alpaca-trader-api/src/TraderApi
dotnet run
```

## Alternative: Run Without Alpaca (Development Mode)

You can still develop and test most of the API without Alpaca credentials:

1. The API will run in "degraded" mode
2. You can test endpoints that don't require Alpaca connection
3. Focus on UI development, database design, etc.
4. Add Alpaca credentials later when ready

## Need More Help?

- Alpaca Support: https://alpaca.markets/support
- Alpaca Community Forum: https://forum.alpaca.markets/
- API Documentation: https://docs.alpaca.markets/