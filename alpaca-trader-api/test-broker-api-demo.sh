#!/bin/bash

echo "========================================="
echo "Alpaca Broker API Demo Test"
echo "========================================="
echo

API_URL="http://localhost:5050"

# Check API health
echo "1. Checking API health..."
curl -s "$API_URL/health" | jq .
echo

# Test authenticated endpoints with demo auth
echo "2. Testing authenticated endpoints with demo authentication..."
echo

# Get user profile
echo "Getting user profile..."
curl -s "$API_URL/api/me" | jq .
echo

# Link Alpaca account
echo "3. Linking Alpaca Broker API account..."
LINK_RESPONSE=$(curl -s -X POST "$API_URL/api/account/link" \
  -H "Content-Type: application/json" \
  -d '{
    "apiKeyId": "CKB4051UELTQZSUS78S8",
    "apiSecret": "ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA",
    "env": "paper"
  }')
echo "$LINK_RESPONSE" | jq .
echo

# Get account info
echo "4. Getting Alpaca account information..."
curl -s "$API_URL/api/account" | jq .
echo

# Get positions
echo "5. Getting current positions..."
curl -s "$API_URL/api/positions" | jq .
echo

# Get recent orders
echo "6. Getting recent orders..."
curl -s "$API_URL/api/orders?limit=5" | jq .
echo

# Create a test order (will be rejected due to market hours)
echo "7. Creating a test order (AAPL limit buy)..."
ORDER_RESPONSE=$(curl -s -X POST "$API_URL/api/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "AAPL",
    "qty": 1,
    "side": "buy",
    "type": "limit",
    "limitPrice": 150.00,
    "timeInForce": "day"
  }')
echo "$ORDER_RESPONSE" | jq .
echo

# Create watchlist
echo "8. Creating a watchlist..."
WATCHLIST_RESPONSE=$(curl -s -X POST "$API_URL/api/watchlists" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Tech Stocks",
    "symbols": ["AAPL", "MSFT", "GOOGL", "AMZN", "META"]
  }')
echo "$WATCHLIST_RESPONSE" | jq .
echo

# Get watchlists
echo "9. Getting all watchlists..."
curl -s "$API_URL/api/watchlists" | jq .
echo

# Create price alert
echo "10. Creating a price alert..."
ALERT_RESPONSE=$(curl -s -X POST "$API_URL/api/alerts" \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "AAPL",
    "operator": ">",
    "threshold": 200.00
  }')
echo "$ALERT_RESPONSE" | jq .
echo

# Get alerts
echo "11. Getting all alerts..."
curl -s "$API_URL/api/alerts" | jq .
echo

echo "========================================="
echo "Demo complete!"
echo
echo "Notes:"
echo "- Demo authentication is enabled, no JWT required"
echo "- Using Broker API with account: CKB4051UELTQZSUS78S8"
echo "- Orders may be rejected outside market hours"
echo "- All data is persisted in SQLite (development mode)"
echo "========================================="