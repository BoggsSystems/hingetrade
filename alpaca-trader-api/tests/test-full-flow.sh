#!/bin/bash

echo "Testing Alpaca Trader API Full Flow"
echo "===================================="

API_URL="http://localhost:5000"
USER_ID="test-user-123"

echo ""
echo "1. Testing Health Check..."
curl -s $API_URL/health | jq '.'

echo ""
echo "2. Testing User Profile Creation..."
curl -s -X GET $API_URL/api/me \
  -H "X-Demo-User-Id: $USER_ID" | jq '.'

echo ""
echo "3. Testing Mock Account Retrieval..."
curl -s $API_URL/api/test/account | jq '.'

echo ""
echo "4. Creating a Watchlist..."
curl -s -X POST $API_URL/api/watchlists \
  -H "Content-Type: application/json" \
  -H "X-Demo-User-Id: $USER_ID" \
  -d '{
    "name": "Tech Stocks",
    "symbols": ["AAPL", "GOOGL", "MSFT"]
  }' | jq '.'

echo ""
echo "5. Getting Watchlists..."
curl -s -X GET $API_URL/api/watchlists \
  -H "X-Demo-User-Id: $USER_ID" | jq '.'

echo ""
echo "6. Creating a Price Alert..."
curl -s -X POST $API_URL/api/alerts \
  -H "Content-Type: application/json" \
  -H "X-Demo-User-Id: $USER_ID" \
  -d '{
    "symbol": "AAPL",
    "operator": ">",
    "threshold": 150.00,
    "active": true
  }' | jq '.'

echo ""
echo "7. Getting Alerts..."
curl -s -X GET $API_URL/api/alerts \
  -H "X-Demo-User-Id: $USER_ID" | jq '.'

echo ""
echo "8. MailHog Messages..."
curl -s http://localhost:8025/api/v1/messages | jq '. | length' | xargs -I {} echo "Total emails sent: {}"

echo ""
echo "===================================="
echo "Test Complete!"