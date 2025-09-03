#\!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting funding test with manual approval..."

# Step 1: Register user
echo -e "\n${GREEN}Step 1: Registering new user${NC}"
TIMESTAMP=$(date +%s)
USERNAME="funduser${TIMESTAMP}"
EMAIL="${USERNAME}@example.com"

RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${USERNAME}\",
    \"email\": \"${EMAIL}\",
    \"password\": \"TestPass123@\"
  }")

TOKEN=$(echo $RESPONSE | jq -r '.AccessToken')
USER_ID=$(echo $RESPONSE | jq -r '.User.Id')

if [ "$TOKEN" = "null" ]; then
    echo -e "${RED}Failed to register user${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

echo "User registered successfully:"
echo "Username: $USERNAME"
echo "Email: $EMAIL"
echo "User ID: $USER_ID"
echo "Token: ${TOKEN:0:50}..."

# Step 2: Submit KYC
echo -e "\n${GREEN}Step 2: Submitting KYC${NC}"
KYC_RESPONSE=$(curl -s -X POST http://localhost:5000/api/kyc/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "personalInfo": {
      "firstName": "Fund",
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
    },
    "bankAccount": {
      "accountType": "checking",
      "routingNumber": "123456789",
      "accountNumber": "987654321",
      "bankName": "Test Bank",
      "accountHolderName": "Fund User"
    }
  }')

echo "KYC Response: $KYC_RESPONSE"

# Step 3: Manually approve KYC using psql
echo -e "\n${GREEN}Step 3: Manually approving KYC in database${NC}"
PGPASSWORD=localdev psql -h localhost -U localuser -d traderapi_auth -c "UPDATE \"AuthUsers\" SET \"KycStatus\" = 2, \"KycApprovedAt\" = NOW() WHERE \"Email\" = '${EMAIL}';" 2>/dev/null || echo "Failed to update database"

# Wait a moment for the update to take effect
sleep 2

# Step 4: Verify KYC status
echo -e "\n${GREEN}Step 4: Verifying KYC status${NC}"
STATUS_RESPONSE=$(curl -s -X GET http://localhost:5000/api/kyc/status \
  -H "Authorization: Bearer $TOKEN")
echo "KYC Status: $STATUS_RESPONSE"

# Step 5: Get bank accounts (should return empty in sandbox)
echo -e "\n${GREEN}Step 5: Getting bank accounts${NC}"
BANK_ACCOUNTS=$(curl -s -X GET http://localhost:5000/api/funding/bank-accounts \
  -H "Authorization: Bearer $TOKEN")
echo "Bank accounts response: $BANK_ACCOUNTS"

# Step 6: Initiate ACH transfer
echo -e "\n${GREEN}Step 6: Initiating ACH transfer (funding account)${NC}"
TRANSFER_RESPONSE=$(curl -s -X POST http://localhost:5000/api/funding/transfers/ach \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 10000.00,
    "direction": "INCOMING"
  }')
echo "Transfer response: $TRANSFER_RESPONSE"

# Step 7: Check transfers
echo -e "\n${GREEN}Step 7: Checking transfers${NC}"
TRANSFERS=$(curl -s -X GET http://localhost:5000/api/funding/transfers \
  -H "Authorization: Bearer $TOKEN")
echo "Transfers: $TRANSFERS"

# Step 8: If we got a transfer ID, check its status
TRANSFER_ID=$(echo $TRANSFER_RESPONSE | jq -r '.transferId' 2>/dev/null || echo "null")
if [ "$TRANSFER_ID" \!= "null" ] && [ \! -z "$TRANSFER_ID" ]; then
    echo -e "\n${GREEN}Step 8: Checking specific transfer status${NC}"
    TRANSFER_STATUS=$(curl -s -X GET "http://localhost:5000/api/funding/transfers/$TRANSFER_ID" \
      -H "Authorization: Bearer $TOKEN")
    echo "Transfer $TRANSFER_ID status: $TRANSFER_STATUS"
fi

echo -e "\n${GREEN}Test scenario complete\!${NC}"
echo "Summary:"
echo "- User: $EMAIL"
echo "- KYC: Manually approved"
echo "- Transfer initiated: \$10,000"
