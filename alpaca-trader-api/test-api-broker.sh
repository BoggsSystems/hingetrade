#!/bin/bash

echo "Testing Alpaca Trader API with Broker API credentials..."
echo

# Wait for API to start
sleep 3

# Test health endpoint
echo "1. Testing health endpoint:"
curl -s http://localhost:5050/health | jq .
echo

# Try to link account (will fail without auth, but shows the endpoint exists)
echo "2. Testing account link endpoint (expected to fail with 401):"
curl -s -X POST http://localhost:5050/api/account/link \
  -H "Content-Type: application/json" \
  -d '{
    "apiKeyId": "CKB4051UELTQZSUS78S8",
    "apiSecret": "ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA",
    "env": "paper"
  }' -w "\nHTTP Status: %{http_code}\n"
echo

echo "3. API endpoints available:"
curl -s http://localhost:5050/swagger/v1/swagger.json | jq '.paths | keys'
echo

echo "To test the API fully, you need to:"
echo "1. Configure Auth0 for JWT authentication"
echo "2. Get a valid JWT token"
echo "3. Make authenticated requests with 'Authorization: Bearer <token>'"