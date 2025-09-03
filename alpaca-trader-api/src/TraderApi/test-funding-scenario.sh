#\!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting complete funding test scenario..."

# Step 1: Register user
echo -e "\n${GREEN}Step 1: Registering new user${NC}"
RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testfunding'$(date +%s)'",
    "email": "testfunding'$(date +%s)'@example.com",
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
    },
    "bankAccount": {
      "accountType": "checking",
      "routingNumber": "123456789",
      "accountNumber": "987654321",
      "bankName": "Test Bank",
      "accountHolderName": "Test User"
    }
  }')

echo "KYC Response: $KYC_RESPONSE"

# Step 3: Check KYC status
echo -e "\n${GREEN}Step 3: Checking KYC status${NC}"
echo "Waiting for KYC approval (checking every 5 seconds)..."

for i in {1..12}; do
    sleep 5
    STATUS_RESPONSE=$(curl -s -X GET http://localhost:5000/api/kyc/status \
      -H "Authorization: Bearer $TOKEN")
    
    KYC_STATUS=$(echo $STATUS_RESPONSE | jq -r '.KycStatus')
    
    echo "Attempt $i: KYC Status = $KYC_STATUS"
    
    if [ "$KYC_STATUS" = "Approved" ]; then
        echo -e "${GREEN}KYC Approved\!${NC}"
        break
    fi
done

# Step 4: Get bank accounts
echo -e "\n${GREEN}Step 4: Getting bank accounts${NC}"
BANK_ACCOUNTS=$(curl -s -X GET http://localhost:5000/api/funding/bank-accounts \
  -H "Authorization: Bearer $TOKEN")

echo "Bank accounts: $BANK_ACCOUNTS"

# Step 5: Initiate ACH transfer
echo -e "\n${GREEN}Step 5: Initiating ACH transfer${NC}"
TRANSFER_RESPONSE=$(curl -s -X POST http://localhost:5000/api/funding/transfers/ach \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000.00,
    "direction": "INCOMING"
  }')

echo "Transfer response: $TRANSFER_RESPONSE"

# Step 6: Check transfers
echo -e "\n${GREEN}Step 6: Checking transfers${NC}"
TRANSFERS=$(curl -s -X GET http://localhost:5000/api/funding/transfers \
  -H "Authorization: Bearer $TOKEN")

echo "Transfers: $TRANSFERS"

echo -e "\n${GREEN}Test scenario complete\!${NC}"
