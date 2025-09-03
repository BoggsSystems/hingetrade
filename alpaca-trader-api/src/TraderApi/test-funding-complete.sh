#\!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting complete funding test scenario with manual approval..."

# Step 1: Register user
echo -e "\n${GREEN}Step 1: Registering new user${NC}"
TIMESTAMP=$(date +%s)
USERNAME="fundtest${TIMESTAMP}"
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

echo "✓ User registered successfully"
echo "  Username: $USERNAME"
echo "  Email: $EMAIL"

# Step 2: Submit KYC
echo -e "\n${GREEN}Step 2: Submitting KYC${NC}"
KYC_RESPONSE=$(curl -s -X POST http://localhost:5000/api/kyc/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "personalInfo": {
      "firstName": "Test",
      "lastName": "Funding",
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
      "accountHolderName": "Test Funding"
    }
  }')

SUCCESS=$(echo $KYC_RESPONSE | jq -r '.success')
if [ "$SUCCESS" \!= "true" ]; then
    echo -e "${RED}KYC submission failed${NC}"
    echo "Response: $KYC_RESPONSE"
else
    echo "✓ KYC submitted successfully"
fi

# Step 3: Manually approve KYC (development only)
echo -e "\n${GREEN}Step 3: Manually approving KYC (dev mode)${NC}"
APPROVE_RESPONSE=$(curl -s -X POST http://localhost:5000/api/kyc/approve \
  -H "Authorization: Bearer $TOKEN")

echo "Approval response: $APPROVE_RESPONSE"

# Step 4: Verify KYC status
echo -e "\n${GREEN}Step 4: Verifying KYC status${NC}"
STATUS_RESPONSE=$(curl -s -X GET http://localhost:5000/api/kyc/status \
  -H "Authorization: Bearer $TOKEN")
KYC_STATUS=$(echo $STATUS_RESPONSE | jq -r '.KycStatus')
echo "KYC Status: $KYC_STATUS"

if [ "$KYC_STATUS" \!= "Approved" ]; then
    echo -e "${RED}KYC not approved, cannot proceed with funding${NC}"
    exit 1
fi
echo "✓ KYC Approved"

# Step 5: Get bank accounts
echo -e "\n${GREEN}Step 5: Getting bank accounts${NC}"
BANK_ACCOUNTS=$(curl -s -X GET http://localhost:5000/api/funding/bank-accounts \
  -H "Authorization: Bearer $TOKEN")
echo "Bank accounts: $BANK_ACCOUNTS" | jq '.'

# Step 6: Initiate ACH transfer (deposit funds)
echo -e "\n${GREEN}Step 6: Initiating ACH transfer - depositing \$10,000${NC}"
TRANSFER_RESPONSE=$(curl -s -X POST http://localhost:5000/api/funding/transfers/ach \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 10000.00,
    "direction": "INCOMING"
  }')

TRANSFER_ID=$(echo $TRANSFER_RESPONSE | jq -r '.transferId')
if [ "$TRANSFER_ID" \!= "null" ] && [ \! -z "$TRANSFER_ID" ]; then
    echo "✓ Transfer initiated successfully"
    echo "  Transfer ID: $TRANSFER_ID"
    echo "  Response: $(echo $TRANSFER_RESPONSE | jq '.')"
else
    echo -e "${RED}Transfer failed${NC}"
    echo "Response: $TRANSFER_RESPONSE"
fi

# Step 7: List all transfers
echo -e "\n${GREEN}Step 7: Listing all transfers${NC}"
TRANSFERS=$(curl -s -X GET http://localhost:5000/api/funding/transfers \
  -H "Authorization: Bearer $TOKEN")
echo "All transfers:"
echo "$TRANSFERS" | jq '.'

# Step 8: Check specific transfer status if we have a transfer ID
if [ "$TRANSFER_ID" \!= "null" ] && [ \! -z "$TRANSFER_ID" ]; then
    echo -e "\n${GREEN}Step 8: Checking specific transfer status${NC}"
    TRANSFER_STATUS=$(curl -s -X GET "http://localhost:5000/api/funding/transfers/$TRANSFER_ID" \
      -H "Authorization: Bearer $TOKEN")
    echo "Transfer $TRANSFER_ID details:"
    echo "$TRANSFER_STATUS" | jq '.'
fi

echo -e "\n${GREEN}🎉 Funding test scenario complete\!${NC}"
echo -e "\nSummary:"
echo "- User: $EMAIL"
echo "- KYC: Approved ✓"
echo "- Transfer: \$10,000 deposit initiated"
echo -e "\nCheck the Alpaca dashboard to see the funded account\!"
