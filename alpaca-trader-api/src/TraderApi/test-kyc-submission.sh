#\!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Testing KYC Submission Flow"
echo "=========================="

# 1. Register a new user
printf "\n${GREEN}Step 1: Registering user...${NC}\n"
TIMESTAMP=$(date +%s)
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"kyctest${TIMESTAMP}@test.com\",\"password\":\"Test123\!\",\"username\":\"kyctest${TIMESTAMP}\"}")

echo "Register Response: $REGISTER_RESPONSE"

# Extract the token
TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    printf "${RED}Failed to register user or extract token${NC}"
    exit 1
fi

printf "${GREEN}Successfully registered user and got token${NC}"

# 2. Submit KYC data
printf "\n${GREEN}Step 2: Submitting KYC data...${NC}"

# Create a minimal base64 image (1x1 transparent PNG)
BASE64_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="

KYC_DATA='{
  "personalInfo": {
    "firstName": "John",
    "lastName": "Doe",
    "dateOfBirth": "1990-01-01",
    "phoneNumber": "(555) 555-1234",
    "email": "kyctest'${TIMESTAMP}'@test.com"
  },
  "address": {
    "streetAddress": "123 Main St",
    "streetAddress2": "Apt 4B",
    "city": "San Francisco",
    "state": "CA",
    "zipCode": "94105",
    "country": "USA",
    "isMailingSame": true,
    "mailingAddress": null
  },
  "identity": {
    "ssn": "123-45-6789",
    "taxIdType": "SSN",
    "employment": {
      "status": "employed",
      "employer": "Tech Corp",
      "occupation": "Software Engineer"
    },
    "publiclyTraded": false,
    "publicCompany": null,
    "affiliatedExchange": false,
    "affiliatedFirm": null,
    "politicallyExposed": false,
    "familyExposed": false
  },
  "documents": {
    "idType": "drivers_license",
    "idFrontBase64": "'${BASE64_IMAGE}'",
    "idFrontFileName": "id_front.png",
    "idFrontFileType": "image/png",
    "idBackBase64": "'${BASE64_IMAGE}'",
    "idBackFileName": "id_back.png",
    "idBackFileType": "image/png"
  },
  "financialProfile": {
    "annualIncome": "50001-100000",
    "netWorth": "100001-250000",
    "liquidNetWorth": "25001-50000",
    "fundingSource": "employment",
    "investmentObjective": "growth",
    "investmentExperience": "good",
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
    "routingNumber": "121000248",
    "accountNumber": "123456789",
    "bankName": "Wells Fargo"
  }
}'

KYC_RESPONSE=$(curl -s -X POST http://localhost:5000/api/kyc/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$KYC_DATA")

echo "KYC Response: $KYC_RESPONSE"

# Check if submission was successful
if echo "$KYC_RESPONSE" | grep -q '"success":true'; then
    printf "${GREEN}KYC submission successful\!${NC}"
    
    # 3. Check KYC status
    printf "\n${GREEN}Step 3: Checking KYC status...${NC}"
    sleep 1
    STATUS_RESPONSE=$(curl -s -X GET http://localhost:5000/api/kyc/status \
      -H "Authorization: Bearer $TOKEN")
    echo "Status Response: $STATUS_RESPONSE"
    
    # Wait for auto-approval (5 seconds)
    printf "\n${GREEN}Waiting 5 seconds for auto-approval...${NC}"
    sleep 5
    
    STATUS_RESPONSE=$(curl -s -X GET http://localhost:5000/api/kyc/status \
      -H "Authorization: Bearer $TOKEN")
    echo "Updated Status Response: $STATUS_RESPONSE"
else
    printf "${RED}KYC submission failed\!${NC}"
    echo "Full response: $KYC_RESPONSE"
fi
