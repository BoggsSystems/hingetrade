#!/bin/bash

echo "Testing KYC Submission Flow (with camelCase)"
echo "==========================================="

# 1. Register a new user
echo ""
echo "Step 1: Registering user..."
TIMESTAMP=$(date +%s)

# Create the JSON data in a variable
REGISTER_JSON=$(cat <<EOF
{
  "email": "kyctest${TIMESTAMP}@test.com",
  "password": "Test123!",
  "username": "kyctest${TIMESTAMP}"
}
EOF
)

REGISTER_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d "$REGISTER_JSON")

echo "Register Response: $REGISTER_RESPONSE" | head -c 200
echo "..."

# Extract the token using sed (try both camelCase and PascalCase)
TOKEN=$(echo "$REGISTER_RESPONSE" | sed -n 's/.*"[aA]ccessToken":"\([^"]*\)".*/\1/p')

if [ -z "$TOKEN" ]; then
    echo "Failed to register user or extract token"
    exit 1
fi

echo "Successfully registered user and got token"

# 2. Submit KYC data (using camelCase since server is now case-insensitive)
echo ""
echo "Step 2: Submitting KYC data..."

# Create a minimal base64 image (1x1 transparent PNG)
BASE64_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="

# Create the KYC JSON data with camelCase
KYC_JSON=$(cat <<EOF
{
  "personalInfo": {
    "firstName": "John",
    "lastName": "Doe",
    "dateOfBirth": "1990-01-01",
    "phoneNumber": "(555) 555-1234",
    "email": "kyctest${TIMESTAMP}@test.com"
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
    "idFrontBase64": "${BASE64_IMAGE}",
    "idFrontFileName": "id_front.png",
    "idFrontFileType": "image/png",
    "idBackBase64": "${BASE64_IMAGE}",
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
}
EOF
)

echo "Submitting KYC data to server..."
KYC_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST http://localhost:5000/api/kyc/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$KYC_JSON")

# Extract HTTP status
HTTP_STATUS=$(echo "$KYC_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$KYC_RESPONSE" | sed '/HTTP_STATUS:/d')

echo "HTTP Status: $HTTP_STATUS"
echo "KYC Response: $RESPONSE_BODY"

# Check if submission was successful
if [ "$HTTP_STATUS" = "200" ]; then
    echo "KYC submission successful!"
    
    # 3. Check KYC status
    echo ""
    echo "Step 3: Checking KYC status..."
    sleep 1
    STATUS_RESPONSE=$(curl -s -X GET http://localhost:5000/api/kyc/status \
      -H "Authorization: Bearer $TOKEN")
    echo "Status Response: $STATUS_RESPONSE"
    
    # Wait for auto-approval (5 seconds)
    echo ""
    echo "Waiting 5 seconds for auto-approval..."
    sleep 5
    
    STATUS_RESPONSE=$(curl -s -X GET http://localhost:5000/api/kyc/status \
      -H "Authorization: Bearer $TOKEN")
    echo "Updated Status Response: $STATUS_RESPONSE"
else
    echo "KYC submission failed!"
fi