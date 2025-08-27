#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Alpaca Broker API credentials (from .env)
API_KEY_ID="CKB4051UELTQZSUS78S8"
API_SECRET="ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA"
BASE_URL="https://broker-api.sandbox.alpaca.markets"

# Generate unique test data
TIMESTAMP=$(date +%s)
EMAIL="alpaca_test_${TIMESTAMP}@example.com"

echo -e "${YELLOW}Testing Direct Alpaca Broker API Account Creation${NC}"
echo "=================================================="
echo "Email: ${EMAIL}"

# Step 1: Create account directly in Alpaca
echo -e "\n${YELLOW}Creating account in Alpaca Broker API...${NC}"

ACCOUNT_DATA='{
  "contact": {
    "email_address": "'${EMAIL}'",
    "phone_number": "+12025551234",
    "street_address": ["123 Test Street"],
    "unit": "Apt 1",
    "city": "Test City",
    "state": "CA",
    "postal_code": "12345",
    "country": "USA"
  },
  "identity": {
    "given_name": "Test",
    "middle_name": "",
    "family_name": "User'${TIMESTAMP}'",
    "date_of_birth": "1990-01-01",
    "tax_id": "456-78-9012",
    "tax_id_type": "USA_SSN",
    "country_of_citizenship": "USA",
    "country_of_birth": "USA",
    "country_of_tax_residence": "USA",
    "funding_source": ["employment_income"]
  },
  "disclosures": {
    "is_control_person": false,
    "is_affiliated_exchange_or_finra": false,
    "is_politically_exposed": false,
    "immediate_family_exposed": false
  },
  "agreements": [
    {
      "agreement": "customer_agreement",
      "signed_at": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
      "ip_address": "127.0.0.1"
    },
    {
      "agreement": "account_agreement",
      "signed_at": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
      "ip_address": "127.0.0.1"
    }
  ],
  "documents": [],
  "trusted_contact": {
    "given_name": "Trusted",
    "family_name": "Contact",
    "email_address": "trusted@example.com",
    "phone_number": "+12025555678"
  },
  "employment": {
    "employment_status": "EMPLOYED",
    "employer_name": "Test Company",
    "employer_address": "456 Business Ave",
    "employment_position": "Software Engineer"
  },
  "profile": {
    "annual_income_min": 50000,
    "annual_income_max": 74999,
    "liquid_net_worth_min": 10000,
    "liquid_net_worth_max": 24999,
    "total_net_worth_min": 25000,
    "total_net_worth_max": 49999
  }
}'

RESPONSE=$(curl -s -X POST "${BASE_URL}/v1/accounts" \
  -u "${API_KEY_ID}:${API_SECRET}" \
  -H "Content-Type: application/json" \
  -d "${ACCOUNT_DATA}")

echo "Response: ${RESPONSE}"

# Extract account ID if successful
ACCOUNT_ID=$(echo "${RESPONSE}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')

if [ ! -z "$ACCOUNT_ID" ]; then
    echo -e "${GREEN}Successfully created Alpaca account: ${ACCOUNT_ID}${NC}"
    
    # Step 2: Check account status
    echo -e "\n${YELLOW}Checking account status...${NC}"
    STATUS_RESPONSE=$(curl -s -X GET "${BASE_URL}/v1/accounts/${ACCOUNT_ID}" \
      -u "${API_KEY_ID}:${API_SECRET}")
    
    echo "Account Status: ${STATUS_RESPONSE}"
else
    echo -e "${RED}Failed to create account in Alpaca${NC}"
    # Check if it's a rate limit or other error
    ERROR=$(echo "${RESPONSE}" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
    if [ ! -z "$ERROR" ]; then
        echo -e "${RED}Error: ${ERROR}${NC}"
    fi
fi

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. If successful, check the Alpaca Broker API dashboard"
echo "2. The new account should appear in the accounts list"
echo "3. We need to integrate this into our KycEndpoints.cs"