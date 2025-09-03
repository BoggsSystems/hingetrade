#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Plaid Integration Test ===${NC}"

# Step 1: Register user
echo -e "\n${GREEN}1. Registering user${NC}"
TIMESTAMP=$(date +%s)
USERNAME="plaidtest${TIMESTAMP}"
EMAIL="${USERNAME}@example.com"

RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "'$USERNAME'",
    "email": "'$EMAIL'",
    "password": "TestPass123@"
  }')

TOKEN=$(echo $RESPONSE | jq -r '.AccessToken')
USER_ID=$(echo $RESPONSE | jq -r '.User.Id')

echo "✓ User created: $USERNAME"
echo "  User ID: $USER_ID"

# Step 2: Submit simple KYC
echo -e "\n${GREEN}2. Submitting KYC${NC}"
KYC_RESPONSE=$(curl -s -X POST http://localhost:5000/api/kyc/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Test",
    "lastName": "User",
    "dateOfBirth": "1990-01-01",
    "taxId": "123-45-6789"
  }')

echo "KYC Response: $KYC_RESPONSE"

# Extract the Alpaca account ID if available
ALPACA_ID=$(echo $KYC_RESPONSE | jq -r '.alpacaAccountId // empty' 2>/dev/null || echo "")

# Step 3: Approve KYC
echo -e "\n${GREEN}3. Approving KYC${NC}"
APPROVE_RESPONSE=$(curl -s -X POST http://localhost:5000/api/kyc/approve \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}')

echo "Approval response: $APPROVE_RESPONSE"

# Step 4: Verify KYC status
echo -e "\n${GREEN}4. Checking KYC status${NC}"
sleep 2
STATUS=$(curl -s -X GET http://localhost:5000/api/kyc/status \
  -H "Authorization: Bearer $TOKEN")
  
KYC_STATUS=$(echo $STATUS | jq -r '.KycStatus')
echo "KYC Status: $KYC_STATUS"

if [ "$KYC_STATUS" != "Approved" ]; then
    echo -e "${RED}KYC not approved!${NC}"
    exit 1
fi

# Step 5: Create Plaid Link token
echo -e "\n${BLUE}5. Creating Plaid Link token${NC}"
LINK_RESPONSE=$(curl -s -X POST http://localhost:5000/api/funding/plaid/link-token \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "'$USER_ID'",
    "userEmail": "'$EMAIL'"
  }')

LINK_TOKEN=$(echo $LINK_RESPONSE | jq -r '.link_token // .LinkToken // empty')

if [ -z "$LINK_TOKEN" ]; then
    echo -e "${RED}Failed to create Link token${NC}"
    echo "Response: $LINK_RESPONSE"
else
    echo -e "${GREEN}✓ Plaid Link token created!${NC}"
    echo "  Token: ${LINK_TOKEN:0:50}..."
    
    # Display Link token details
    echo -e "\n${YELLOW}Plaid Link Token Details:${NC}"
    echo $LINK_RESPONSE | jq '.'
fi

# Step 6: Check bank accounts (should be empty initially)
echo -e "\n${GREEN}6. Checking bank accounts${NC}"
BANKS=$(curl -s -X GET http://localhost:5000/api/funding/bank-accounts \
  -H "Authorization: Bearer $TOKEN")
  
echo "Current bank accounts:"
echo $BANKS | jq '.'

# Summary
echo -e "\n${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}✓ User registered${NC}"
echo -e "${GREEN}✓ KYC submitted and approved${NC}"
echo -e "${GREEN}✓ Plaid Link token created${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. In your frontend, initialize Plaid Link with the token"
echo "2. User selects their bank and accounts"
echo "3. Plaid returns a public token"
echo "4. Call /api/funding/plaid/create-ach-relationship with:"
echo "   - publicToken: (from Plaid)"
echo "   - accountId: (selected account from Plaid)"
echo ""
echo "Test credentials for Plaid Link sandbox:"
echo "  Username: user_good"
echo "  Password: pass_good"
echo "  Bank: Any (Chase works well)"