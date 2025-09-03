#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Fund Alpaca Account 921090503 ===${NC}"
echo ""

# Account details from the dashboard
ACCOUNT_ID="29940464-d7e7-4c54-8d6c-60242929eb98"
ACCOUNT_NUMBER="921090503"

# Get API credentials from environment
API_KEY_ID="${ALPACA_API_KEY_ID}"
API_SECRET="${ALPACA_API_SECRET}"

if [ -z "$API_KEY_ID" ] || [ -z "$API_SECRET" ]; then
    echo -e "${YELLOW}Please set environment variables:${NC}"
    echo "export ALPACA_API_KEY_ID='your-key-id'"
    echo "export ALPACA_API_SECRET='your-secret'"
    exit 1
fi

# Create auth header
AUTH_HEADER="Authorization: Basic $(echo -n "${API_KEY_ID}:${API_SECRET}" | base64)"

echo -e "${GREEN}Step 1: Check existing bank relationships${NC}"
curl -s -X GET "https://broker-api.sandbox.alpaca.markets/v1/accounts/${ACCOUNT_ID}/ach_relationships" \
  -H "$AUTH_HEADER" | jq '.'

echo -e "\n${GREEN}Step 2: Check current account balance${NC}"
curl -s -X GET "https://broker-api.sandbox.alpaca.markets/v1/accounts/${ACCOUNT_ID}" \
  -H "$AUTH_HEADER" | jq '.cash, .cash_withdrawable, .cash_transferable'

echo -e "\n${BLUE}For Alpaca Sandbox Instant Funding:${NC}"
echo "1. First create a test ACH relationship using Plaid sandbox"
echo "2. Then create instant funding transfer"
echo ""

# Create instant sandbox funding (only works if ACH relationship exists)
echo -e "${YELLOW}To create instant sandbox funding:${NC}"
cat << 'EOF'
# Step 1: Create test ACH relationship (one-time setup)
# You need a Plaid processor token first

# Step 2: Create instant funding
curl -X POST https://broker-api.sandbox.alpaca.markets/v1/accounts/29940464-d7e7-4c54-8d6c-60242929eb98/transfers \
  -H "Authorization: Basic $(echo -n 'YOUR_API_KEY_ID:YOUR_API_SECRET' | base64)" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": "10000",
    "direction": "INCOMING",
    "timing": "immediate",
    "relationship_id": "YOUR_ACH_RELATIONSHIP_ID"
  }'
EOF

echo -e "\n${GREEN}Alternative: Use Alpaca Dashboard${NC}"
echo "The easiest way to fund sandbox accounts is through the Alpaca dashboard:"
echo "1. Go to https://broker-app.alpaca.markets/dashboard"
echo "2. Find account ${ACCOUNT_NUMBER}"
echo "3. Use the 'Fund Account' option for instant sandbox funding"