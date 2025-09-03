#!/bin/bash

# Test direct account retrieval
echo "Testing direct account endpoint..."
curl -u "CKB4051UELTQZSUS78S8:ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA" \
  http://localhost:5001/v1/trading/accounts/920964623/account \
  -H "Accept: application/json"

echo -e "\n\nDone."