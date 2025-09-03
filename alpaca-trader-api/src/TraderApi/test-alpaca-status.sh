#!/bin/bash

# Test Alpaca account status checking
echo "Testing Alpaca Account Status Check"
echo "==================================="

# Alpaca API credentials from .env
API_KEY_ID="CKB4051UELTQZSUS78S8"
API_SECRET="ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA"
BASE_URL="https://broker-api.sandbox.alpaca.markets"

# The account ID from our test
ACCOUNT_ID="e7dbf878-35c6-42f0-a888-5bf41c3befed"

echo ""
echo "Checking status of account: $ACCOUNT_ID"
echo ""

# Get account details
curl -s -X GET "$BASE_URL/v1/accounts/$ACCOUNT_ID" \
  -u "$API_KEY_ID:$API_SECRET" \
  -H "Accept: application/json" | jq '.'

echo ""
echo "Done."