#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Complete Funding Flow Test ===${NC}"
echo "This test will create a user, submit KYC, manually approve it, and test funding"
echo ""

# Step 1: Register user
echo -e "\n${GREEN}Step 1: Registering new user${NC}"
TIMESTAMP=$(date +%s)
USERNAME="fundtest${TIMESTAMP}"
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
REFRESH_TOKEN=$(echo $RESPONSE | jq -r '.RefreshToken')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo -e "${RED}Failed to register user${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ User registered successfully${NC}"
echo "  Username: $USERNAME"
echo "  User ID: $USER_ID"
echo "  Token: ${TOKEN:0:20}..."

# Step 2: Submit KYC
echo -e "\n${GREEN}Step 2: Submitting KYC${NC}"
KYC_RESPONSE=$(curl -s -X POST http://localhost:5000/api/kyc/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "personalInfo": {
      "firstName": "Test",
      "lastName": "User",
      "dateOfBirth": "1990-01-01",
      "phoneNumber": "+1-555-123-4567",
      "socialSecurityNumber": "123-45-6789",
      "email": "'$EMAIL'"
    },
    "address": {
      "streetAddress": "123 Test St",
      "city": "New York",
      "state": "NY",
      "zipCode": "10001",
      "country": "USA",
      "isMailingSame": true
    },
    "identity": {
      "ssn": "123-45-6789",
      "taxIdType": "SSN",
      "employment": {
        "status": "employed",
        "employer": "Test Corp",
        "occupation": "Engineer"
      },
      "publiclyTraded": false,
      "affiliatedExchange": false,
      "politicallyExposed": false,
      "familyExposed": false
    },
    "documents": {
      "idType": "drivers_license"
    },
    "financialProfile": {
      "annualIncome": "50000-100000",
      "netWorth": "50000-250000",
      "liquidNetWorth": "10000-50000",
      "fundingSource": "employment",
      "investmentObjective": "growth",
      "investmentExperience": "some",
      "riskTolerance": "moderate"
    },
    "agreements": {
      "customerAgreement": true,
      "marketDataAgreement": true,
      "privacyPolicy": true,
      "communicationConsent": true,
      "w9Certification": true
    }
  }')

SUBMISSION_ID=$(echo $KYC_RESPONSE | jq -r '.submissionId')
ALPACA_ACCOUNT_ID=$(echo $KYC_RESPONSE | jq -r '.alpacaAccountId')

echo -e "${GREEN}✓ KYC submitted${NC}"
echo "  Submission ID: $SUBMISSION_ID"
echo "  Alpaca Account ID: $ALPACA_ACCOUNT_ID"

# Step 3: Manually approve KYC
echo -e "\n${GREEN}Step 3: Manually approving KYC${NC}"
APPROVE_RESPONSE=$(curl -s -X POST http://localhost:5000/api/kyc/approve \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}')

echo "Approve response: $APPROVE_RESPONSE"

# Step 4: Verify KYC status
echo -e "\n${GREEN}Step 4: Verifying KYC status${NC}"
sleep 2
STATUS_RESPONSE=$(curl -s -X GET http://localhost:5000/api/kyc/status \
  -H "Authorization: Bearer $TOKEN")

KYC_STATUS=$(echo $STATUS_RESPONSE | jq -r '.KycStatus')
echo -e "${GREEN}✓ KYC Status: $KYC_STATUS${NC}"

if [ "$KYC_STATUS" != "Approved" ]; then
    echo -e "${RED}KYC not approved, cannot proceed with funding${NC}"
    exit 1
fi

# Step 5: Create Plaid Link token
echo -e "\n${BLUE}Step 5: Creating Plaid Link token${NC}"
LINK_TOKEN_RESPONSE=$(curl -s -X POST http://localhost:5000/api/funding/plaid/link-token \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "'$USER_ID'",
    "userEmail": "'$EMAIL'"
  }')

LINK_TOKEN=$(echo $LINK_TOKEN_RESPONSE | jq -r '.link_token // .LinkToken')

if [ "$LINK_TOKEN" = "null" ] || [ -z "$LINK_TOKEN" ]; then
    echo -e "${RED}Failed to create Plaid Link token${NC}"
    echo "Response: $LINK_TOKEN_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Plaid Link token created${NC}"
echo "  Link Token: ${LINK_TOKEN:0:50}..."

# Step 6: Simulate Plaid sandbox flow
echo -e "\n${BLUE}Step 6: Using Plaid sandbox credentials${NC}"
echo -e "${YELLOW}Note: In production, user would complete Plaid Link UI here${NC}"
echo ""
echo "For manual testing with Plaid Link:"
echo "1. Use the link token: $LINK_TOKEN"
echo "2. In Plaid Link, use credentials:"
echo "   - Username: user_good"
echo "   - Password: pass_good"
echo "3. Select any Chase account"
echo "4. Get the public token and account ID"
echo ""

# For automated testing, we'll simulate what happens after Plaid Link
echo -e "${YELLOW}Simulating Plaid Link completion...${NC}"
echo "Using test values (these won't work without real Plaid Link):"
PUBLIC_TOKEN="public-sandbox-test-token"
ACCOUNT_ID="test-account-id"

# Step 7: Try to create ACH relationship
echo -e "\n${BLUE}Step 7: Creating ACH relationship (will fail with test tokens)${NC}"
ACH_RESPONSE=$(curl -s -X POST http://localhost:5000/api/funding/plaid/create-ach-relationship \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "publicToken": "'$PUBLIC_TOKEN'",
    "accountId": "'$ACCOUNT_ID'"
  }' 2>&1 || true)

echo "ACH Relationship Response: $ACH_RESPONSE"

# Step 8: Check bank accounts
echo -e "\n${GREEN}Step 8: Checking bank accounts${NC}"
BANK_ACCOUNTS=$(curl -s -X GET http://localhost:5000/api/funding/bank-accounts \
  -H "Authorization: Bearer $TOKEN")

BANK_COUNT=$(echo $BANK_ACCOUNTS | jq '. | length' 2>/dev/null || echo 0)
echo "Bank accounts found: $BANK_COUNT"
echo "Bank accounts: $BANK_ACCOUNTS"

# Step 9: Summary
echo -e "\n${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}✓ User created: $USERNAME${NC}"
echo -e "${GREEN}✓ KYC submitted and approved${NC}"
echo -e "${GREEN}✓ Plaid Link token created${NC}"
echo -e "${YELLOW}! ACH relationship creation requires real Plaid Link flow${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Implement Plaid Link in the frontend"
echo "2. Use the Link token to let user connect their bank"
echo "3. Exchange the public token for ACH relationship"
echo "4. Then funding will be available"
echo ""
echo "User credentials for testing:"
echo "  Username: $USERNAME"
echo "  Password: TestPass123@"
echo "  Token: $TOKEN"