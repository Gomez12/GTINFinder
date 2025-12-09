#!/bin/bash

# Script to create Authentik OAuth2 Provider and Application for GTINFinder

echo "🔧 Creating Authentik OAuth2 Provider and Application..."

# Get admin session cookie
echo "📋 Getting admin session..."
curl -s -c cookies.txt -X POST "http://localhost:9000/if/flow/default-authentication-flow/" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "uid_field=akadmin&password=admin123&go_to=true" > /dev/null

# Get CSRF token from admin interface
echo "🔐 Getting CSRF token..."
CSRF_TOKEN=$(curl -s -b cookies.txt "http://localhost:9000/if/admin/#/" | grep -o '"csrfmiddlewaretoken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ Could not get CSRF token. Please complete the setup manually:"
    echo "1. Go to http://localhost:9000"
    echo "2. Login with akadmin/admin123"
    echo "3. Go to Providers > Create Provider"
    echo "4. Select OAuth2/OpenID Connect Provider"
    echo "5. Configure with:"
    echo "   - Name: GTINFinder"
    echo "   - Client type: Confidential"
    echo "   - Redirect URIs: http://localhost:3000/*"
    echo "   - JWT Algorithm: RS256"
    echo "6. Save and create Application"
    echo "7. Application name: GTINFinder"
    echo "8. Slug: gtin-finder"
    echo "9. Launch URL: http://localhost:3000"
    exit 1
fi

echo "✅ CSRF token obtained: ${CSRF_TOKEN:0:20}..."

# Create OAuth2 Provider
echo "📝 Creating OAuth2 Provider..."
PROVIDER_RESPONSE=$(curl -s -b cookies.txt -X POST "http://localhost:9000/api/v3/providers/oauth2/" \
  -H "Content-Type: application/json" \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -d '{
    "name": "GTINFinder",
    "authorization_flow": "default-authentication-flow",
    "client_type": "confidential",
    "jwt_alg": "RS256",
    "redirect_uris": "http://localhost:3000/*\nhttp://localhost:3000/silent-renew.html",
    "sub_mode": "user_id",
    "issuer_mode": "per_provider"
  }')

if echo "$PROVIDER_RESPONSE" | grep -q '"pk"'; then
    PROVIDER_PK=$(echo "$PROVIDER_RESPONSE" | grep -o '"pk":"[^"]*"' | cut -d'"' -f4)
    echo "✅ OAuth2 Provider created with PK: $PROVIDER_PK"
else
    echo "❌ Failed to create OAuth2 Provider: $PROVIDER_RESPONSE"
    exit 1
fi

# Create Application
echo "🎯 Creating Application..."
APP_RESPONSE=$(curl -s -b cookies.txt -X POST "http://localhost:9000/api/v3/core/applications/" \
  -H "Content-Type: application/json" \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -d "{
    \"name\": \"GTINFinder\",
    \"slug\": \"gtin-finder\",
    \"provider\": \"$PROVIDER_PK\",
    \"launch_url\": \"http://localhost:3000\",
    \"policy_engine_mode\": \"any\"
  }")

if echo "$APP_RESPONSE" | grep -q '"slug":"gtin-finder"'; then
    echo "✅ Application created successfully!"
    
    # Get the client credentials
    CLIENT_INFO=$(curl -s -b cookies.txt "http://localhost:9000/api/v3/providers/oauth2/$PROVIDER_PK/" | grep -E '"client_id"|"client_secret"')
    echo "📋 Client Credentials:"
    echo "$CLIENT_INFO"
    
    echo ""
    echo "🎉 Authentik setup completed successfully!"
    echo "📋 Next steps:"
    echo "1. Frontend should now be able to authenticate"
    echo "2. Test login at http://localhost:3000"
    echo "3. The OIDC endpoints are available at:"
    echo "   http://localhost:9000/application/o/gtin-finder/.well-known/openid-configuration"
else
    echo "❌ Failed to create Application: $APP_RESPONSE"
    exit 1
fi