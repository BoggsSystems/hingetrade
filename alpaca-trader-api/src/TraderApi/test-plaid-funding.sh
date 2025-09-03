#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "Starting Plaid + Alpaca funding test scenario..."

# Step 1: Register user
echo -e "\n${GREEN}Step 1: Registering new user${NC}"
RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "plaidtest'$(date +%s)'",
    "email": "plaidtest'$(date +%s)'@example.com",
    "password": "TestPass123@"
  }')

TOKEN=$(echo $RESPONSE | jq -r '.AccessToken')
USER_ID=$(echo $RESPONSE | jq -r '.User.Id')
USERNAME=$(echo $RESPONSE | jq -r '.User.Username')

if [ "$TOKEN" = "null" ]; then
    echo -e "${RED}Failed to register user${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

echo "User registered successfully:"
echo "Username: $USERNAME"
echo "User ID: $USER_ID"

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
      "email": "'$USERNAME'@example.com"
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

echo "KYC submitted"

# Step 3: Wait for KYC approval
echo -e "\n${GREEN}Step 3: Waiting for KYC approval${NC}"
echo "Checking KYC status..."

for i in {1..12}; do
    sleep 5
    STATUS_RESPONSE=$(curl -s -X GET http://localhost:5000/api/kyc/status \
      -H "Authorization: Bearer $TOKEN")
    
    KYC_STATUS=$(echo $STATUS_RESPONSE | jq -r '.KycStatus')
    
    echo "Attempt $i: KYC Status = $KYC_STATUS"
    
    if [ "$KYC_STATUS" = "Approved" ]; then
        echo -e "${GREEN}KYC Approved!${NC}"
        break
    fi
done

# Step 4: Create Plaid Link token
echo -e "\n${BLUE}Step 4: Creating Plaid Link token${NC}"
LINK_TOKEN_RESPONSE=$(curl -s -X POST http://localhost:5000/api/funding/plaid/link-token \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "'$USER_ID'",
    "userEmail": "'$USERNAME'@example.com"
  }')

LINK_TOKEN=$(echo $LINK_TOKEN_RESPONSE | jq -r '.link_token // .LinkToken')

if [ "$LINK_TOKEN" = "null" ] || [ -z "$LINK_TOKEN" ]; then
    echo -e "${RED}Failed to create Plaid Link token${NC}"
    echo "Response: $LINK_TOKEN_RESPONSE"
    exit 1
fi

echo "Plaid Link token created: ${LINK_TOKEN:0:20}..."

# Step 5: Simulate Plaid Link flow (in sandbox)
echo -e "\n${BLUE}Step 5: Simulating Plaid Link flow${NC}"
echo "In a real implementation, the user would go through Plaid Link UI"
echo "For testing, use Plaid's sandbox public token:"
echo "Public Token: public-sandbox-12345678-abcd-efgh-ijkl-123456789012"

# Step 6: Exchange public token and create ACH relationship
echo -e "\n${BLUE}Step 6: Creating ACH relationship with Plaid processor token${NC}"
echo "Note: This will fail without a valid Plaid sandbox public token"
echo "To get a valid token:"
echo "1. Create a Plaid sandbox account"
echo "2. Use the Plaid Quickstart app to get a public token"
echo "3. Replace the public token below"

# This is a placeholder - in real use, you'd get this from Plaid Link
PUBLIC_TOKEN="public-sandbox-12345678-abcd-efgh-ijkl-123456789012"
ACCOUNT_ID="account-sandbox-12345678-abcd-efgh-ijkl-123456789012"

ACH_RESPONSE=$(curl -s -X POST http://localhost:5000/api/funding/plaid/create-ach-relationship \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "publicToken": "'$PUBLIC_TOKEN'",
    "accountId": "'$ACCOUNT_ID'"
  }' || true)

echo "ACH Relationship Response: $ACH_RESPONSE"

# Step 7: Check bank accounts
echo -e "\n${GREEN}Step 7: Checking bank accounts${NC}"
BANK_ACCOUNTS=$(curl -s -X GET http://localhost:5000/api/funding/bank-accounts \
  -H "Authorization: Bearer $TOKEN")

echo "Bank accounts: $BANK_ACCOUNTS"

# Step 8: If we have a bank account, initiate a transfer
BANK_COUNT=$(echo $BANK_ACCOUNTS | jq '. | length')
if [ "$BANK_COUNT" -gt "0" ]; then
    echo -e "\n${GREEN}Step 8: Initiating ACH transfer${NC}"
    RELATIONSHIP_ID=$(echo $BANK_ACCOUNTS | jq -r '.[0].id')
    
    TRANSFER_RESPONSE=$(curl -s -X POST http://localhost:5000/api/funding/transfers/ach \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "amount": 1000.00,
        "direction": "INCOMING",
        "relationshipId": "'$RELATIONSHIP_ID'"
      }')
    
    echo "Transfer response: $TRANSFER_RESPONSE"
else
    echo -e "\n${RED}No bank accounts found. Cannot initiate transfer.${NC}"
fi

echo -e "\n${BLUE}Plaid Integration Test Complete!${NC}"
echo ""
echo "To complete the Plaid integration:"
echo "1. Set up Plaid sandbox credentials in appsettings.json"
echo "2. Use Plaid's quickstart app to get real sandbox tokens"
echo "3. Update the frontend to integrate Plaid Link"
echo ""