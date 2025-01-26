#!/bin/bash

# API URL
API_URL="http://172.17.0.1:11434/v1/completions"

# Request payload
PAYLOAD='{
  "model": "deepseek-r1:7b",
  "prompt": "What is the purpose of deepseek-r1?",
  "options": {
    "stream": false
  }
}'

# Run the test with wget
echo "Testing deepseek-r1:7b with prompt: 'What is the purpose of deepseek-r1?'"
RESPONSE=$(wget -qO- --header="Content-Type: application/json" \
  --post-data="$PAYLOAD" \
  "$API_URL")

# Print the response
echo "Response from API:"
echo "$RESPONSE"

