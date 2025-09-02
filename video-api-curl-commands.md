# Video API Curl Commands

## Quick Test Commands for HingeTrade Video API

### 1. Health Check (No Auth Required)
```bash
curl -X GET http://localhost:5001/health | jq '.'
```

### 2. Login to Get Token
```bash
# Login with test user
curl -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "emailOrUsername": "tester",
    "password": "Test123!@#"
  }' | jq '.'

# Save the token from response
export TOKEN="your-jwt-token-here"
```

### 3. Get Video Feed
```bash
# Personalized feed
curl -X GET "http://localhost:5001/api/videos/feed?page=1&pageSize=20&feedType=personalized" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.'

# Trending videos
curl -X GET "http://localhost:5001/api/videos/trending?page=1&pageSize=20" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.'

# Videos by symbol
curl -X GET "http://localhost:5001/api/videos/by-symbol/TSLA?page=1&pageSize=20" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.'
```

### 4. Get Specific Video
```bash
curl -X GET "http://localhost:5001/api/videos/00000000-0000-0000-0000-000000000001" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.'
```

### 5. Video Interactions
```bash
# Like a video
curl -X POST "http://localhost:5001/api/videos/00000000-0000-0000-0000-000000000001/interactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "interactionType": "Like",
    "value": true
  }' | jq '.'

# Save a video
curl -X POST "http://localhost:5001/api/videos/00000000-0000-0000-0000-000000000001/interactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "interactionType": "Save",
    "value": true
  }' | jq '.'
```

### 6. Get Creator Info
```bash
curl -X GET "http://localhost:5001/api/videos/creators/00000000-0000-0000-0000-000000000001" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.'
```

## Debugging Commands

### Check if API is Running
```bash
# Should return JSON with service status
curl -s http://localhost:5001/health | jq '.'
```

### Test Without jq (raw output)
```bash
curl -X GET "http://localhost:5001/api/videos/feed?page=1&pageSize=20" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json"
```

### Verbose Mode (see headers)
```bash
curl -v -X GET "http://localhost:5001/api/videos/feed?page=1&pageSize=20" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json"
```

### Check Response Headers Only
```bash
curl -I -X GET "http://localhost:5001/api/videos/feed?page=1&pageSize=20" \
  -H "Authorization: Bearer $TOKEN"
```

## Expected Responses

### Successful Video Feed Response:
```json
{
  "videos": [
    {
      "id": "uuid",
      "title": "TSLA Breaking Out! 🚀",
      "description": "Tesla analysis...",
      "mentionedSymbols": ["TSLA", "NVDA"],
      "realTimePrices": {
        "TSLA": 234.56,
        "NVDA": 489.12
      },
      "creatorDisplayName": "TechTrader Pro",
      "viewCount": 12500,
      // ... more fields
    }
  ],
  "total": 50,
  "page": 1,
  "pageSize": 20,
  "hasMore": true
}
```

### Error Response (API not running):
```
curl: (7) Failed to connect to localhost port 5001: Connection refused
```

### Error Response (Not authenticated):
```json
{
  "error": "Unauthorized"
}
```

### Error Response (Creator Studio API down):
```json
{
  "error": "Failed to fetch videos from Creator Studio",
  "details": "Connection refused"
}
```