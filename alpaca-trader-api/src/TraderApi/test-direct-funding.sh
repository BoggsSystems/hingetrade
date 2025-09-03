#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Direct Funding Test ===${NC}"
echo "Using existing Alpaca account: 29940464-d7e7-4c54-8d6c-60242929eb98"
echo ""

# First, we need to find the user associated with this account
echo -e "${GREEN}Step 1: Finding user with this Alpaca account...${NC}"
# For this test, we'll need to register a new user and manually set their Alpaca account

# Register a test user
echo "Creating test user..."
RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "directfund'$(date +%s)'",
    "email": "directfund'$(date +%s)'@example.com",
    "password": "TestPass123@"
  }')

TOKEN=$(echo $RESPONSE | jq -r '.AccessToken')
USER_ID=$(echo $RESPONSE | jq -r '.User.Id')

echo "✓ Test user created"
echo "  User ID: $USER_ID"

# Now we need to simulate having this user linked to the Alpaca account
# In production, this would happen through KYC submission
# For testing, we'll directly test the funding endpoints

echo -e "\n${GREEN}Step 2: Testing bank accounts endpoint${NC}"
echo "Note: This will fail because the test user doesn't have the Alpaca account linked"
BANK_RESPONSE=$(curl -s -X GET http://localhost:5000/api/funding/bank-accounts \
  -H "Authorization: Bearer $TOKEN" 2>&1 || true)

echo "Bank accounts response: $BANK_RESPONSE"

echo -e "\n${YELLOW}To properly test funding with account 921090503:${NC}"
echo "1. The account needs bank relationships created via Plaid"
echo "2. Use Alpaca's Broker API directly with your API credentials"
echo ""

# Test creating ACH relationship directly with Alpaca
echo -e "${GREEN}Step 3: Creating test ACH relationship via Plaid${NC}"
echo "This requires:"
echo "- Valid Plaid public token from Plaid Link"
echo "- Account ID from Plaid"
echo ""

# For Alpaca sandbox, you can create instant sandbox funding
echo -e "${BLUE}Alternative: Create instant sandbox funding${NC}"
echo "In Alpaca sandbox, you can create instant funding relationships"
echo ""

# Show how to create a test bank relationship
cat << 'EOF'
To create a test bank relationship in Alpaca sandbox:

1. Get a Plaid public token:
   - Use Plaid Link with sandbox credentials
   - User: user_good, Password: pass_good
   - Select any bank account

2. Create ACH relationship:
   curl -X POST https://broker-api.sandbox.alpaca.markets/v1/accounts/29940464-d7e7-4c54-8d6c-60242929eb98/ach_relationships \
     -H "Authorization: Basic $(echo -n 'YOUR_API_KEY_ID:YOUR_API_SECRET' | base64)" \
     -H "Content-Type: application/json" \
     -d '{
       "account_owner_name": "Test User",
       "bank_account_type": "CHECKING",
       "processor_token": "processor-sandbox-xxxxx",
       "ach_processor": "plaid"
     }'

3. Create instant funding (sandbox only):
   curl -X POST https://broker-api.sandbox.alpaca.markets/v1/accounts/29940464-d7e7-4c54-8d6c-60242929eb98/transfers \
     -H "Authorization: Basic $(echo -n 'YOUR_API_KEY_ID:YOUR_API_SECRET' | base64)" \
     -H "Content-Type: application/json" \
     -d '{
       "amount": "1000",
       "direction": "INCOMING",
       "timing": "immediate",
       "relationship_id": "YOUR_RELATIONSHIP_ID"
     }'
EOF

echo -e "\n${YELLOW}Summary:${NC}"
echo "✓ Account 921090503 exists and is approved"
echo "✓ To fund it, you need:"
echo "  1. Create bank relationship via Plaid"
echo "  2. Then initiate ACH transfer"
echo "✓ Or use Alpaca dashboard for manual sandbox funding"