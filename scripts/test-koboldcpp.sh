#!/bin/bash

# KoboldCpp Connection Test Script
# This script helps verify that your KoboldCpp server is accessible and properly configured

# Default values
KOBOLDCPP_URL="${KOBOLDCPP_BASE_URL:-http://192.168.1.100:5001}"

echo "🔍 Testing KoboldCpp connection..."
echo "URL: $KOBOLDCPP_URL"
echo ""

# Test 1: Basic connectivity
echo "1. Testing basic connectivity..."
if curl -s --connect-timeout 10 "$KOBOLDCPP_URL" > /dev/null; then
    echo "   ✅ KoboldCpp server is reachable"
else
    echo "   ❌ Cannot reach KoboldCpp server at $KOBOLDCPP_URL"
    echo "   💡 Check that:"
    echo "      - KoboldCpp is running"
    echo "      - The IP address and port are correct"
    echo "      - Firewall allows connections"
    exit 1
fi

# Test 2: OpenAI API endpoint
echo ""
echo "2. Testing OpenAI-compatible API endpoint..."
MODELS_RESPONSE=$(curl -s "$KOBOLDCPP_URL/v1/models" 2>/dev/null)
if echo "$MODELS_RESPONSE" | grep -q "models"; then
    echo "   ✅ OpenAI-compatible API is working"
    echo "   📋 Available models:"
    echo "$MODELS_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for model in data.get('data', []):
        print(f'      - {model.get(\"id\", \"unknown\")}')
except:
    print('      Could not parse models response')
"
else
    echo "   ❌ OpenAI-compatible API not responding correctly"
    echo "   💡 Make sure KoboldCpp was started with the --api flag"
    exit 1
fi

# Test 3: Chat completions endpoint
echo ""
echo "3. Testing chat completions endpoint..."
CHAT_RESPONSE=$(curl -s -X POST "$KOBOLDCPP_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "Hello"}],
        "max_tokens": 10
    }' 2>/dev/null)

if echo "$CHAT_RESPONSE" | grep -q "choices"; then
    echo "   ✅ Chat completions endpoint is working"
else
    echo "   ❌ Chat completions endpoint not responding correctly"
    echo "   Response: $CHAT_RESPONSE"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Your KoboldCpp server is properly configured."
echo ""
echo "Next steps:"
echo "1. Set KOBOLDCPP_BASE_URL=$KOBOLDCPP_URL in your .env file"
echo "2. Start Bytebot with: docker compose -f docker/docker-compose.koboldcpp.yml up -d"
echo "3. Visit http://localhost:9992 and look for 'koboldcpp-local' in the model dropdown"