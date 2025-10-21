#!/bin/bash

echo "🧪 Testing Braindumpster Webhook Endpoints"
echo "=========================================="
echo ""

echo "1️⃣ Testing Health Endpoint..."
curl -s http://57.129.81.193:5001/api/health | python3 -m json.tool
echo ""
echo ""

echo "2️⃣ Testing Webhook Test Endpoint..."
curl -s http://57.129.81.193:5001/api/webhooks/test | python3 -m json.tool
echo ""
echo ""

echo "3️⃣ Testing Main Webhook Endpoint (should return error for GET)..."
curl -s http://57.129.81.193:5001/api/webhooks/apple | python3 -m json.tool
echo ""
echo ""

echo "4️⃣ Testing Main Webhook with Sample Payload..."
curl -s -X POST http://57.129.81.193:5001/api/webhooks/apple \
  -H "Content-Type: application/json" \
  -d '{"signedPayload":"test"}' | python3 -m json.tool
echo ""

echo "✅ Tests complete!"
