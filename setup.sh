#!/bin/bash
# GTINFinder Setup Script
# This script sets up the complete GTINFinder environment

set -e

echo "🚀 GTINFinder Setup Script"
echo "=========================="

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Generate secure keys
echo "🔐 Generating secure keys..."

# Directus key (32 chars)
DIRECTUS_KEY=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
echo "DIRECTUS_KEY=$DIRECTUS_KEY"

# Directus secret (32 chars)
DIRECTUS_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
echo "DIRECTUS_SECRET=$DIRECTUS_SECRET"

# Airflow Fernet key
AIRFLOW_FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" 2>/dev/null || echo "your_fernet_key_here_32_chars")
echo "AIRFLOW_FERNET_KEY=$AIRFLOW_FERNET_KEY"

# Authentik secret key (50 chars)
AUTHENTIK_SECRET_KEY=$(openssl rand -base64 50 | tr -d "=+/" | cut -c1-50)
echo "AUTHENTIK_SECRET_KEY=$AUTHENTIK_SECRET_KEY"

# Create .env file
echo "📝 Creating .env file..."
cat > .env << EOF
# Database Configuration
POSTGRES_DB=gtin_finder
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here

# Directus Configuration
DIRECTUS_KEY=${DIRECTUS_KEY}
DIRECTUS_SECRET=${DIRECTUS_SECRET}
DIRECTUS_DB=directus
DIRECTUS_USER=directus_user
DIRECTUS_PASSWORD=directus_secure_password

# Airflow Configuration
AIRFLOW_DB=airflow
AIRFLOW_USER=airflow_user
AIRFLOW_PASSWORD=airflow_secure_password
AIRFLOW_FERNET_KEY=${AIRFLOW_FERNET_KEY}

# Authentik Configuration
AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}
AUTHENTIK_DB=authentik
AUTHENTIK_USER=authentik_user
AUTHENTIK_PASSWORD=authentik_secure_password

# Frontend Configuration (for later)
REACT_APP_AUTH0_DOMAIN=localhost:9000
REACT_APP_AUTH0_CLIENT_ID=your_client_id_here
REACT_APP_API_URL=http://localhost:8055
EOF

echo "✅ .env file created"

echo "🚀 Starting services for initial setup..."
docker-compose up -d postgresql directus authentik-server

echo "⏳ Waiting for services to be ready..."
sleep 30

echo "🔧 Setting up Directus admin user..."
# Wait for Directus to be ready and create/reset admin user
docker-compose exec -T directus npx directus users passwd --email admin@example.com --password admin123 || \
docker-compose exec -T directus npx directus users create --email admin@example.com --password admin123 --role administrator

# Ensure admin user has proper permissions
echo "🔐 Setting up admin permissions..."
sleep 5

# Skip admin user ID check for now - focus on system token approach
echo "⚡ Using system token approach for collection creation"

echo "📋 Creating Directus collections..."
# Wait a bit more for Directus to be fully ready
sleep 10

# Get admin token for API calls (try different approaches)
echo "Getting Directus admin token..."

# Method 1: Try to get admin token via login
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8055/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' | \
    grep -o '"access_token":"[^"]*"' | cut -d'"' -f4 || echo "")

if [ -n "$ADMIN_TOKEN" ]; then
    echo "✅ Got admin token via login"
    TOKEN_TYPE="admin"
    TOKEN="$ADMIN_TOKEN"
else
    # Method 2: Try system token
    SYSTEM_TOKEN=$(grep DIRECTUS_SECRET .env | cut -d'=' -f2)
    if [ -n "$SYSTEM_TOKEN" ]; then
        echo "✅ Trying system token"
        TOKEN_TYPE="system"
        TOKEN="$SYSTEM_TOKEN"
    else
        echo "⚠️  Could not get any valid token"
        TOKEN_TYPE="none"
        TOKEN=""
    fi
fi

if [ -z "$TOKEN" ]; then
    echo "⚠️  Failed to authenticate with Directus. Collections will need to be created manually."
    echo "Please go to http://localhost:8055 and create the following collections:"
    echo "- gtins"
    echo "- gtin_raw_data" 
    echo "- gtin_golden_records"
    echo "- data_sources"
    echo "- data_quality_scores"
else
    echo "✅ Got $TOKEN_TYPE token, creating collections via API..."
    
    # Create gtins collection
    echo "Creating gtins collection..."
    RESPONSE=$(curl -s -X POST http://localhost:8055/collections \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "collection": "gtins",
            "meta": {
                "collection": "gtins",
                "icon": "barcode",
                "note": "Main GTIN records with validated data",
                "display_template": "{{gtin}} - {{product_name}}"
            },
            "schema": {
                "gtin": {"type": "string", "length": 14, "unique": true, "required": true},
                "product_name": {"type": "string", "length": 255},
                "brand": {"type": "string", "length": 100},
                "category": {"type": "string", "length": 100},
                "description": {"type": "text"},
                "status": {"type": "string", "options": ["pending", "validated", "error"], "default_value": "pending"},
                "created_at": {"type": "timestamp", "default_value": "$NOW"},
                "updated_at": {"type": "timestamp"}
            }
        }')
    if [[ "$RESPONSE" == *"errors"* ]]; then
        echo "⚠️  Failed to create gtins collection: $RESPONSE"
    else
        echo "✅ Created gtins collection"
    fi

    # Create gtin_raw_data collection
    echo "Creating gtin_raw_data collection..."
    RESPONSE=$(curl -s -X POST http://localhost:8055/collections \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "collection": "gtin_raw_data",
            "meta": {
                "collection": "gtin_raw_data",
                "icon": "data",
                "note": "Raw data from external APIs"
            },
            "schema": {
                "id": {"type": "integer", "primary_key": true, "auto_increment": true},
                "gtin": {"type": "string", "length": 14},
                "source": {"type": "string", "length": 50},
                "raw_data": {"type": "json"},
                "received_at": {"type": "timestamp", "default_value": "$NOW"}
            }
        }')
    if [[ "$RESPONSE" == *"errors"* ]]; then
        echo "⚠️  Failed to create gtin_raw_data collection: $RESPONSE"
    else
        echo "✅ Created gtin_raw_data collection"
    fi

    # Create gtin_golden_records collection
    echo "Creating gtin_golden_records collection..."
    RESPONSE=$(curl -s -X POST http://localhost:8055/collections \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "collection": "gtin_golden_records",
            "meta": {
                "collection": "gtin_golden_records",
                "icon": "star",
                "note": "Consolidated golden records"
            },
            "schema": {
                "id": {"type": "integer", "primary_key": true, "auto_increment": true},
                "gtin": {"type": "string", "length": 14, "unique": true},
                "product_name": {"type": "string", "length": 255},
                "brand": {"type": "string", "length": 100},
                "category": {"type": "string", "length": 100},
                "description": {"type": "text"},
                "confidence_score": {"type": "float", "default_value": 0.0},
                "sources_count": {"type": "integer", "default_value": 0},
                "created_at": {"type": "timestamp", "default_value": "$NOW"},
                "updated_at": {"type": "timestamp"}
            }
        }')
    if [[ "$RESPONSE" == *"errors"* ]]; then
        echo "⚠️  Failed to create gtin_golden_records collection: $RESPONSE"
    else
        echo "✅ Created gtin_golden_records collection"
    fi

    # Create data_sources collection
    echo "Creating data_sources collection..."
    RESPONSE=$(curl -s -X POST http://localhost:8055/collections \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "collection": "data_sources",
            "meta": {
                "collection": "data_sources",
                "icon": "source",
                "note": "Available data sources"
            },
            "schema": {
                "id": {"type": "integer", "primary_key": true, "auto_increment": true},
                "name": {"type": "string", "length": 100, "unique": true, "required": true},
                "api_endpoint": {"type": "string", "length": 255},
                "api_key_required": {"type": "boolean", "default_value": false},
                "rate_limit": {"type": "integer", "default_value": 100},
                "is_active": {"type": "boolean", "default_value": true},
                "created_at": {"type": "timestamp", "default_value": "$NOW"}
            }
        }')
    if [[ "$RESPONSE" == *"errors"* ]]; then
        echo "⚠️  Failed to create data_sources collection: $RESPONSE"
    else
        echo "✅ Created data_sources collection"
    fi

    # Create data_quality_scores collection
    echo "Creating data_quality_scores collection..."
    RESPONSE=$(curl -s -X POST http://localhost:8055/collections \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "collection": "data_quality_scores",
            "meta": {
                "collection": "data_quality_scores",
                "icon": "analytics",
                "note": "Data quality metrics"
            },
            "schema": {
                "id": {"type": "integer", "primary_key": true, "auto_increment": true},
                "gtin": {"type": "string", "length": 14},
                "source": {"type": "string", "length": 50},
                "completeness_score": {"type": "float", "default_value": 0.0},
                "accuracy_score": {"type": "float", "default_value": 0.0},
                "consistency_score": {"type": "float", "default_value": 0.0},
                "overall_score": {"type": "float", "default_value": 0.0},
                "evaluated_at": {"type": "timestamp", "default_value": "$NOW"}
            }
        }')
    if [[ "$RESPONSE" == *"errors"* ]]; then
        echo "⚠️  Failed to create data_quality_scores collection: $RESPONSE"
    else
        echo "✅ Created data_quality_scores collection"
    fi

    echo "✅ Collections creation completed via API"
fi

echo "🔧 Setting up Authentik admin password..."
# Wait for Authentik to be ready and reset admin password
docker-compose exec -T authentik-server python manage.py shell -c "
from authentik.core.models import User; 
u = User.objects.get(username='akadmin'); 
u.set_password('admin123'); 
u.save(); 
print('Password updated for akadmin')
" || echo "Authentik setup will be completed manually"

echo "🛑 Stopping services..."
docker-compose down

echo "✅ Setup completed successfully!"
echo ""
echo "📋 Login Credentials:"
echo "Directus (http://localhost:8055):"
echo "  Email: admin@example.com"
echo "  Password: admin123"
echo ""
echo "Airflow (http://localhost:8080):"
echo "  Username: airflow_user"
echo "  Password: airflow_secure_password"
echo ""
echo "Authentik (http://localhost:9000):"
echo "  Username: akadmin"
echo "  Password: admin123"
echo ""
echo "🚀 Run 'make up' to start all services!"
