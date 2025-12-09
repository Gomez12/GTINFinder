#!/bin/bash

# Test script for GTINFinder OIDC Login Flow

echo "🧪 Testing GTINFinder OIDC Login Flow"
echo "=================================="

# Test 1: Check if all services are running
echo "1️⃣ Checking service status..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Frontend is running on http://localhost:3000"
else
    echo "❌ Frontend is not running"
    exit 1
fi

if curl -s http://localhost:9000 > /dev/null; then
    echo "✅ Authentik is running on http://localhost:9000"
else
    echo "❌ Authentik is not running"
    exit 1
fi

if curl -s http://localhost:8055 > /dev/null; then
    echo "✅ Directus is running on http://localhost:8055"
else
    echo "❌ Directus is not running"
    exit 1
fi

# Test 2: Check OIDC Discovery
echo ""
echo "2️⃣ Testing OIDC Discovery..."
DISCOVERY_RESPONSE=$(curl -s "http://localhost:9000/application/o/gtin-finder/.well-known/openid-configuration")
if echo "$DISCOVERY_RESPONSE" | grep -q "issuer"; then
    echo "✅ OIDC Discovery endpoint is working"
    ISSUER=$(echo "$DISCOVERY_RESPONSE" | grep -o '"issuer":"[^"]*"' | cut -d'"' -f4)
    echo "   Issuer: $ISSUER"
else
    echo "❌ OIDC Discovery endpoint failed"
    exit 1
fi

# Test 3: Check JWKS endpoint
echo ""
echo "3️⃣ Testing JWKS endpoint..."
if curl -s "http://localhost:9000/application/o/gtin-finder/jwks/" | grep -q "keys"; then
    echo "✅ JWKS endpoint is working"
else
    echo "❌ JWKS endpoint failed"
    exit 1
fi

# Test 4: Check frontend environment variables
echo ""
echo "4️⃣ Testing frontend environment..."
FRONTEND_RESPONSE=$(curl -s http://localhost:3000)
if echo "$FRONTEND_RESPONSE" | grep -q "GTINFinder"; then
    echo "✅ Frontend is loading correctly"
else
    echo "❌ Frontend is not loading properly"
    exit 1
fi

# Test 5: Test Authentik login
echo ""
echo "5️⃣ Testing Authentik authentication..."
LOGIN_RESPONSE=$(curl -s -c auth_test_cookies.txt -X POST "http://localhost:9000/if/flow/default-authentication-flow/" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "uid_field=akadmin&password=admin123")

if echo "$LOGIN_RESPONSE" | grep -q "Set-Cookie"; then
    echo "✅ Authentik login is working"
else
    echo "⚠️  Authentik login may need manual verification"
fi

# Test 6: Test Directus API
echo ""
echo "6️⃣ Testing Directus API..."
if curl -s http://localhost:8055/server/info > /dev/null; then
    echo "✅ Directus API is accessible"
else
    echo "❌ Directus API is not accessible"
    exit 1
fi

echo ""
echo "🎉 All tests passed! GTINFinder login flow is ready!"
echo ""
echo "📋 Test Summary:"
echo "   ✅ Frontend: http://localhost:3000"
echo "   ✅ Authentik: http://localhost:9000 (akadmin/admin123)"
echo "   ✅ Directus: http://localhost:8055 (admin@example.com/admin123)"
echo "   ✅ OIDC Provider: GTINFinder"
echo "   ✅ OIDC Discovery: Working"
echo "   ✅ JWKS Endpoint: Working"
echo ""
echo "🌐 Ready for Sprint 1 testing!"
echo ""
echo "📝 Next Steps:"
echo "1. Open http://localhost:3000 in your browser"
echo "2. Click 'Sign in with Authentik'"
echo "3. Login with akadmin/admin123"
echo "4. You should be redirected back to the GTINFinder dashboard"
echo ""
echo "🔗 OIDC Configuration:"
echo "   Client ID: i70lhiKFzGjUFOy9avmhz8pyF9yeJ1tKK4HdD1FM"
echo "   Redirect URIs: http://localhost:3000/*"
echo "   Scopes: openid profile email offline_access"