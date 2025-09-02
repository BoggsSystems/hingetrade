#!/bin/bash

# Video API Testing Script for HingeTrade
# This script tests all video-related endpoints in the Alpaca Trader API

# Configuration
API_BASE_URL="http://localhost:5001"
API_TOKEN=""  # Will be set after login

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== HingeTrade Video API Testing ===${NC}\n"

# Function to print headers
print_header() {
    echo -e "\n${YELLOW}--- $1 ---${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Test 1: Health Check
print_header "Testing Health Endpoint"
echo "curl -X GET $API_BASE_URL/health"
curl -s -X GET "$API_BASE_URL/health" | jq '.' || print_error "Health check failed"

# Test 2: Register Test User (if needed)
print_header "Registering Test User"
REGISTER_PAYLOAD='{
  "username": "videotest",
  "email": "videotest@test.com",
  "password": "Test123!@#",
  "firstName": "Video",
  "lastName": "Tester"
}'

echo "curl -X POST $API_BASE_URL/api/auth/register"
REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "$REGISTER_PAYLOAD")

echo "$REGISTER_RESPONSE" | jq '.' 2>/dev/null || echo "$REGISTER_RESPONSE"

# Test 3: Login to get JWT token
print_header "Logging in to get JWT Token"
LOGIN_PAYLOAD='{
  "emailOrUsername": "videotest",
  "password": "Test123!@#"
}'

echo "curl -X POST $API_BASE_URL/api/auth/login"
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "$LOGIN_PAYLOAD")

# Extract token from response
API_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.accessToken' 2>/dev/null)

if [ -z "$API_TOKEN" ] || [ "$API_TOKEN" = "null" ]; then
    print_error "Failed to get auth token"
    echo "Response: $LOGIN_RESPONSE"
    echo -e "\n${RED}Cannot continue without authentication. Please ensure the API is running.${NC}"
    exit 1
else
    print_success "Got JWT token: ${API_TOKEN:0:20}..."
fi

# Test 4: Get Video Feed (Personalized)
print_header "Testing Video Feed - Personalized"
echo "curl -X GET $API_BASE_URL/api/videos/feed?page=1&pageSize=20&feedType=personalized"
curl -s -X GET "$API_BASE_URL/api/videos/feed?page=1&pageSize=20&feedType=personalized" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Accept: application/json" | jq '.' || print_error "Video feed request failed"

# Test 5: Get Trending Videos
print_header "Testing Trending Videos"
echo "curl -X GET $API_BASE_URL/api/videos/trending?page=1&pageSize=20"
curl -s -X GET "$API_BASE_URL/api/videos/trending?page=1&pageSize=20" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Accept: application/json" | jq '.' || print_error "Trending videos request failed"

# Test 6: Get Videos by Symbol
print_header "Testing Videos by Symbol (TSLA)"
echo "curl -X GET $API_BASE_URL/api/videos/by-symbol/TSLA?page=1&pageSize=20"
curl -s -X GET "$API_BASE_URL/api/videos/by-symbol/TSLA?page=1&pageSize=20" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Accept: application/json" | jq '.' || print_error "Videos by symbol request failed"

# Test 7: Get Specific Video (using mock ID)
print_header "Testing Get Specific Video"
VIDEO_ID="00000000-0000-0000-0000-000000000001"
echo "curl -X GET $API_BASE_URL/api/videos/$VIDEO_ID"
curl -s -X GET "$API_BASE_URL/api/videos/$VIDEO_ID" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Accept: application/json" | jq '.' || print_error "Get video request failed"

# Test 8: Record Video Interaction
print_header "Testing Video Interaction (Like)"
INTERACTION_PAYLOAD='{
  "interactionType": "Like",
  "value": true
}'
echo "curl -X POST $API_BASE_URL/api/videos/$VIDEO_ID/interactions"
curl -s -X POST "$API_BASE_URL/api/videos/$VIDEO_ID/interactions" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$INTERACTION_PAYLOAD" | jq '.' || print_error "Video interaction request failed"

# Test 9: Get Creator Info
print_header "Testing Get Creator Info"
CREATOR_ID="00000000-0000-0000-0000-000000000001"
echo "curl -X GET $API_BASE_URL/api/videos/creators/$CREATOR_ID"
curl -s -X GET "$API_BASE_URL/api/videos/creators/$CREATOR_ID" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Accept: application/json" | jq '.' || print_error "Get creator request failed"

# Test 10: Test Video Feed with Different Parameters
print_header "Testing Video Feed with Pagination"
echo "curl -X GET $API_BASE_URL/api/videos/feed?page=2&pageSize=10&feedType=following"
curl -s -X GET "$API_BASE_URL/api/videos/feed?page=2&pageSize=10&feedType=following" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Accept: application/json" | jq '.' || print_error "Paginated feed request failed"

echo -e "\n${BLUE}=== Testing Complete ===${NC}\n"

# Summary of endpoints tested
echo -e "${GREEN}Video API Endpoints Tested:${NC}"
echo "✓ GET  /api/videos/feed - Get personalized video feed"
echo "✓ GET  /api/videos/trending - Get trending videos"
echo "✓ GET  /api/videos/by-symbol/{symbol} - Get videos by stock symbol"
echo "✓ GET  /api/videos/{videoId} - Get specific video"
echo "✓ POST /api/videos/{videoId}/interactions - Record video interaction"
echo "✓ GET  /api/videos/creators/{creatorId} - Get creator info"

echo -e "\n${YELLOW}Note: If requests fail with 404 or connection errors:${NC}"
echo "1. Ensure Alpaca Trader API is running: cd alpaca-trader-api/src/TraderApi && dotnet run"
echo "2. Ensure Creator Studio API is running: cd creator-studio-api && dotnet run"
echo "3. Check that both services are healthy and connected"