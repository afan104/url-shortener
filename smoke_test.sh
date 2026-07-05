#!/usr/bin/env bash
set -e

BASE_URL="http://localhost:8000"

echo "Testing POST /shorten..."
response=$(curl -s -X POST "$BASE_URL/shorten" -H "Content-Type: application/json" -d '{"url": "https://example.com"}')
echo "$response"
code=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['code'])")

echo "Testing GET /$code (expect 301)..."
curl -s -D - -o /dev/null "$BASE_URL/$code" | grep "301"

echo "Testing GET /doesnotexist (expect 404)..."
curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL/doesnotexist" | grep "404"

echo "Testing POST /shorten with bad URL (expect 422)..."
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$BASE_URL/shorten" -H "Content-Type: application/json" -d '{"url": "not-a-url"}' | grep "422"

echo "All checks passed."