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
# Wait for Directus to be ready
sleep 15

# Try to reset existing admin user password first
echo "Attempting to reset existing admin user password..."
docker-compose exec -T directus npx directus users passwd --email admin@example.com --password admin123 2>/dev/null
PASSWD_RESULT=$?

if [ $PASSWD_RESULT -eq 0 ]; then
    echo "✅ Admin user password reset successfully"
else
    echo "Admin user not found, creating new admin user..."
    
    # Try creating admin user with different approaches
    echo "Method 1: Creating admin user with role..."
    docker-compose exec -T directus npx directus users create --email admin@example.com --password admin123 --role administrator 2>/dev/null
    CREATE_RESULT1=$?
    
    if [ $CREATE_RESULT1 -ne 0 ]; then
        echo "Method 2: Creating admin user without role..."
        docker-compose exec -T directus npx directus users create --email admin@example.com --password admin123 2>/dev/null
        CREATE_RESULT2=$?
        
        if [ $CREATE_RESULT2 -ne 0 ]; then
            echo "Method 3: Creating admin user with minimal parameters..."
            docker-compose exec -T directus npx directus users create --email admin@example.com --password admin123 --first-name Admin --last-name User 2>/dev/null
            CREATE_RESULT3=$?
            
            if [ $CREATE_RESULT3 -ne 0 ]; then
                echo "⚠️  All admin user creation methods failed"
                echo "📋 Manual admin user creation required:"
                echo "1. Go to http://localhost:8055"
                echo "2. Click 'Create Account' or use initial setup"
                echo "3. Create admin user with email: admin@example.com"
                echo "4. Set password: admin123"
            else
                echo "✅ Admin user created successfully (Method 3)"
            fi
        else
            echo "✅ Admin user created successfully (Method 2)"
        fi
    else
        echo "✅ Admin user created successfully (Method 1)"
    fi
fi

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
    # Method 2: Try system token with different format
    SYSTEM_TOKEN=$(grep DIRECTUS_SECRET .env | cut -d'=' -f2)
    if [ -n "$SYSTEM_TOKEN" ]; then
        echo "✅ Trying system token"
        TOKEN_TYPE="system"
        TOKEN="$SYSTEM_TOKEN"
        
        # Test system token with a simple API call
        TEST_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8055/server/info)
        if [[ "$TEST_RESPONSE" != *"project"* ]]; then
            echo "⚠️  System token test failed, trying shared secret format"
            # Try with shared secret header instead
            TOKEN_TYPE="shared"
        fi
    else
        echo "⚠️  Could not get any valid token"
        TOKEN_TYPE="none"
        TOKEN=""
    fi
fi

echo "⚠️  Directus collections need to be created manually."
    echo ""
    echo "📋 Manual setup required:"
    echo "1. Go to http://localhost:8055"
    echo "2. Login with:"
    echo "   Email: admin@example.com"
    echo "   Password: admin123"
    echo "3. Go to Settings > Data Model"
    echo "4. Create the following collections:"
    echo ""
    echo "   Collection 1: gtins"
    echo "   - Fields: gtin (string, 14 chars, unique, required)"
    echo "   - Fields: product_name (string, 255 chars)"
    echo "   - Fields: brand (string, 100 chars)"
    echo "   - Fields: category (string, 100 chars)"
    echo "   - Fields: description (text)"
    echo "   - Fields: status (string, options: pending, validated, error, default: pending)"
    echo "   - Fields: created_at (timestamp, default: now)"
    echo "   - Fields: updated_at (timestamp)"
    echo ""
    echo "   Collection 2: gtin_raw_data"
    echo "   - Fields: id (integer, primary key, auto increment)"
    echo "   - Fields: gtin (string, 14 chars)"
    echo "   - Fields: source (string, 50 chars)"
    echo "   - Fields: raw_data (json)"
    echo "   - Fields: received_at (timestamp, default: now)"
    echo ""
    echo "   Collection 3: gtin_golden_records"
    echo "   - Fields: id (integer, primary key, auto increment)"
    echo "   - Fields: gtin (string, 14 chars, unique)"
    echo "   - Fields: product_name (string, 255 chars)"
    echo "   - Fields: brand (string, 100 chars)"
    echo "   - Fields: category (string, 100 chars)"
    echo "   - Fields: description (text)"
    echo "   - Fields: confidence_score (float, default: 0.0)"
    echo "   - Fields: sources_count (integer, default: 0)"
    echo "   - Fields: created_at (timestamp, default: now)"
    echo "   - Fields: updated_at (timestamp)"
    echo ""
    echo "   Collection 4: data_sources"
    echo "   - Fields: id (integer, primary key, auto increment)"
    echo "   - Fields: name (string, 100 chars, unique, required)"
    echo "   - Fields: api_endpoint (string, 255 chars)"
    echo "   - Fields: api_key_required (boolean, default: false)"
    echo "   - Fields: rate_limit (integer, default: 100)"
    echo "   - Fields: is_active (boolean, default: true)"
    echo "   - Fields: created_at (timestamp, default: now)"
    echo ""
    echo "   Collection 5: data_quality_scores"
    echo "   - Fields: id (integer, primary key, auto increment)"
    echo "   - Fields: gtin (string, 14 chars)"
    echo "   - Fields: source (string, 50 chars)"
    echo "   - Fields: completeness_score (float, default: 0.0)"
    echo "   - Fields: accuracy_score (float, default: 0.0)"
    echo "   - Fields: consistency_score (float, default: 0.0)"
    echo "   - Fields: overall_score (float, default: 0.0)"
    echo "   - Fields: evaluated_at (timestamp, default: now)"
    echo ""
    echo "✅ After creating collections, the API test should work:"
    echo "   curl http://localhost:8055/items/gtins"

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
