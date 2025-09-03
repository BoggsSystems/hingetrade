# Alpaca Broker API Notes

## Important: You have a Broker API Account

Your account is an **Alpaca Broker API Sandbox** account, not a standard Trading API account. This has important implications:

### Key Differences

1. **Authentication**: Uses Basic Auth instead of custom headers
   - Standard API: `APCA-API-KEY-ID` and `APCA-API-SECRET-KEY` headers
   - Broker API: `Authorization: Basic base64(key:secret)`

2. **Endpoints**: Different URL structure
   - Standard API: `https://paper-api.alpaca.markets/v2/account`
   - Broker API: `https://broker-api.sandbox.alpaca.markets/v1/accounts`

3. **Account Model**: Broker API manages multiple sub-accounts
   - You can create and manage multiple trading accounts
   - Each account has its own positions, orders, etc.

4. **API Structure**:
   - `/v1/accounts` - List all accounts
   - `/v1/accounts/{account_id}` - Get specific account
   - `/v1/trading/accounts/{account_id}/orders` - Orders for an account
   - `/v1/trading/accounts/{account_id}/positions` - Positions for an account

## Current Implementation Status

✅ **Working**:
- Basic Authentication implemented
- Connection to Broker API Sandbox verified
- Can list accounts

⚠️ **Needs Updates**:
- API endpoints need to be updated for Broker API structure
- Account selection logic (which sub-account to use)
- Order/Position endpoints need account_id parameter

## Next Steps

To fully support Broker API:

1. **Select or Create a Trading Account**:
   - Pick one of the existing accounts from the list
   - Or create a new account via POST `/v1/accounts`

2. **Update API Client**:
   - Modify endpoints to include account_id
   - Update data models for Broker API responses

3. **Store Account Selection**:
   - Save selected account_id per user
   - Use this for all trading operations

## Quick Test Commands

List accounts:
```bash
curl -X GET "https://broker-api.sandbox.alpaca.markets/v1/accounts" \
  -H "Authorization: Basic $(echo -n 'CKB4051UELTQZSUS78S8:ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA' | base64)"
```

Get specific account (replace {account_id}):
```bash
curl -X GET "https://broker-api.sandbox.alpaca.markets/v1/accounts/{account_id}" \
  -H "Authorization: Basic $(echo -n 'CKB4051UELTQZSUS78S8:ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA' | base64)"
```