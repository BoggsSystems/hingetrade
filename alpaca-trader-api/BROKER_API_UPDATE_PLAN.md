# Broker API Update Plan

## Overview
Update the TraderApi to support Alpaca Broker API's multi-account structure while maintaining backward compatibility.

## Key Changes Required

### 1. Data Model Updates
- **AlpacaLink entity**: Add `BrokerAccountId` field to store selected sub-account
- **New entity**: `BrokerAccount` to cache broker account details
- **Migration**: Add database migration for new fields

### 2. Service Updates
- **AccountsService**:
  - Add `ListBrokerAccountsAsync()` to fetch all sub-accounts
  - Add `SelectBrokerAccountAsync()` to set active account
  - Update `GetAccountAsync()` to use selected broker account
  
- **AlpacaClient**:
  - Update endpoints to use Broker API paths
  - Add account_id parameter to all trading endpoints
  - Add methods for broker-specific operations

### 3. Endpoint Updates
- Add `GET /api/broker-accounts` - List all broker accounts
- Add `POST /api/broker-accounts/{id}/select` - Select active account
- Update existing endpoints to use selected account

### 4. Compatibility Strategy
- Detect if using Broker API vs Trading API based on base URL
- For Trading API: Continue current behavior
- For Broker API: Use multi-account flow

## Implementation Steps

1. **Phase 1: Data Model** (Current)
   - Add BrokerAccountId to AlpacaLink
   - Create BrokerAccount entity
   - Add migration

2. **Phase 2: Client Updates**
   - Update AlpacaClient for broker endpoints
   - Add account selection logic

3. **Phase 3: Service Updates**
   - Update AccountsService
   - Update OrdersService, PositionsService

4. **Phase 4: API Endpoints**
   - Add new broker account endpoints
   - Update existing endpoints

5. **Phase 5: Testing**
   - Test with your Broker API sandbox
   - Ensure Trading API compatibility

## Quick Start Approach
For immediate testing, we can:
1. Hard-code the first account ID from your sandbox
2. Update AlpacaClient endpoints for Broker API
3. Test core functionality (orders, positions)
4. Then implement full multi-account support