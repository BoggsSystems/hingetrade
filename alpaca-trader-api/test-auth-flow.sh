#!/bin/bash

BASE_URL="http://localhost:5001"
EMAIL="test$(date +%s)@example.com"
PASSWORD="TestPassword123!"

echo "🔐 Testing complete auth flow for symbols endpoint..."
echo "Email: $EMAIL"
echo "Password: $PASSWORD"

# Step 1: Register a user
echo -e "\n1️⃣ Registering user..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"firstName\": \"Test\",
    \"lastName\": \"User\"
  }")

echo "Register response: $REGISTER_RESPONSE"

# Step 2: Login to get JWT token
echo -e "\n2️⃣ Logging in to get JWT token..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

echo "Login response: $LOGIN_RESPONSE"

# Extract access token using grep and sed (more portable than jq)
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Failed to extract access token"
    echo "Full response: $LOGIN_RESPONSE"
    exit 1
fi

echo "✅ Got access token: ${ACCESS_TOKEN:0:20}..."

# Step 3: Test symbols endpoint with JWT token
echo -e "\n3️⃣ Testing symbols endpoint with JWT token..."
SYMBOLS_RESPONSE=$(curl -s -v "$BASE_URL/api/symbols/search?query=AAPL" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" 2>&1)

echo "Symbols response:"
echo "$SYMBOLS_RESPONSE"

# Step 4: Check backend logs for AlphaVantage activity
echo -e "\n4️⃣ Checking backend logs for AlphaVantage activity..."
echo "Looking for our special logs..."
tail -n 20 backend.log | grep -E "(===============|AlphaVantage|SearchSymbols)" || echo "No AlphaVantage logs found"

echo -e "\n✅ Test complete!"