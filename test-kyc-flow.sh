#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# API base URL
API_URL="http://localhost:5005/api"

# Generate unique test data
TIMESTAMP=$(date +%s)
EMAIL="test_${TIMESTAMP}@example.com"
USERNAME="testuser${TIMESTAMP}"

echo -e "${YELLOW}Testing KYC Flow with user: ${EMAIL}${NC}"
echo "=================================================="

# Step 1: Register user
echo -e "\n${YELLOW}1. Registering user...${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "${API_URL}/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'${EMAIL}'",
    "password": "TestPass123!",
    "username": "'${USERNAME}'",
    "acceptedTerms": true
  }')

echo "Register Response: ${REGISTER_RESPONSE}"

# Extract the access token
TOKEN=$(echo "${REGISTER_RESPONSE}" | sed -n 's/.*"[aA]ccessToken":"\([^"]*\)".*/\1/p')

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Failed to get access token${NC}"
    exit 1
fi

echo -e "${GREEN}Got access token${NC}"

# Step 2: Submit KYC data
echo -e "\n${YELLOW}2. Submitting KYC data...${NC}"
KYC_RESPONSE=$(curl -s -X POST "${API_URL}/kyc/submit" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "PersonalInfo": {
      "FirstName": "Test",
      "LastName": "User'${TIMESTAMP}'",
      "DateOfBirth": "1990-01-01",
      "SocialSecurityNumber": "123-45-6789",
      "PhoneNumber": "+1234567890"
    },
    "Address": {
      "StreetAddress": "123 Test Street",
      "City": "Test City",
      "State": "CA",
      "PostalCode": "12345",
      "Country": "USA",
      "IsMailingAddressSame": true
    },
    "Identity": {
      "DocumentType": "drivers_license",
      "DocumentNumber": "D1234567",
      "DocumentState": "CA",
      "DocumentExpirationDate": "2025-12-31",
      "DocumentImage": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
    },
    "Documents": {
      "ProofOfIdentity": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
      "ProofOfAddress": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
    },
    "FinancialProfile": {
      "EmploymentStatus": "employed",
      "Employer": "Test Company",
      "AnnualIncome": "50000-74999",
      "NetWorth": "25000-49999",
      "LiquidNetWorth": "10000-24999",
      "InvestmentExperience": "1-2",
      "RiskTolerance": "moderate",
      "InvestmentObjective": "growth"
    },
    "Agreements": {
      "CustomerAgreement": true,
      "MarginAgreement": false,
      "AccountAgreement": true,
      "DataSharingConsent": true,
      "PrivacyPolicyConsent": true,
      "ElectronicDeliveryConsent": true,
      "RiskDisclosureAcknowledgement": true,
      "DayTradingDisclosure": false
    },
    "BankAccount": {
      "BankName": "Test Bank",
      "AccountType": "checking",
      "RoutingNumber": "123456789",
      "AccountNumber": "1234567890",
      "AccountHolderName": "Test User"
    }
  }')

echo "KYC Response: ${KYC_RESPONSE}"

# Step 3: Check KYC status
echo -e "\n${YELLOW}3. Checking KYC status...${NC}"
sleep 2
STATUS_RESPONSE=$(curl -s -X GET "${API_URL}/kyc/status" \
  -H "Authorization: Bearer ${TOKEN}")

echo "Status Response: ${STATUS_RESPONSE}"

# Step 4: Wait for auto-approval (5 seconds in dev)
echo -e "\n${YELLOW}4. Waiting for auto-approval (5 seconds)...${NC}"
sleep 6

# Check status again
STATUS_RESPONSE2=$(curl -s -X GET "${API_URL}/kyc/status" \
  -H "Authorization: Bearer ${TOKEN}")

echo "Status after wait: ${STATUS_RESPONSE2}"

# Step 5: Check if this account appears in Alpaca (it won't currently)
echo -e "\n${YELLOW}5. Checking Alpaca Broker API (this will show existing data, not our new user)...${NC}"
echo -e "${RED}Note: KYC data is NOT sent to Alpaca yet - integration pending${NC}"

# You could add a direct Alpaca API call here to list accounts
# ALPACA_RESPONSE=$(curl -s -X GET "https://broker-api.sandbox.alpaca.markets/v1/accounts" \
#   -u "CKB4051UELTQZSUS78S8:ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA")

echo -e "\n${GREEN}Test completed!${NC}"
echo "=================================================="
echo -e "User created: ${EMAIL}"
echo -e "${YELLOW}To implement Alpaca integration, we need to:${NC}"
echo "1. Map KYC data to Alpaca's BrokerAccountRequest format"
echo "2. Call AlpacaClient.CreateBrokerAccountAsync in KycEndpoints.cs"
echo "3. Store the Alpaca account ID with the user"
echo "4. Handle Alpaca's response and update KYC status accordingly"