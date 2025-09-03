#!/bin/bash

echo "Testing symbols endpoint..."

# Test without auth (should get 401)
echo "1. Testing without auth:"
curl -s "http://localhost:5001/api/symbols/search?query=AAPL" | head -1

# Test with invalid auth (should get 401)  
echo -e "\n2. Testing with invalid auth:"
curl -s -H "Authorization: Bearer invalid" "http://localhost:5001/api/symbols/search?query=AAPL" | head -1

echo -e "\n3. Checking backend logs for any symbol-related activity..."
tail -n 20 backend.log | grep -i -E "(symbols|alpha|search)" || echo "No symbol-related logs found"

echo -e "\n4. Checking if symbols endpoint is even registered..."
curl -s "http://localhost:5001/api/symbols" || echo "Endpoint not found"