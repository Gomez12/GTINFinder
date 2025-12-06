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

echo "📋 Creating Directus collections..."
# Import collections from snapshot file
docker-compose exec -T directus npx directus snapshot apply --yes /directus/collections.json || \
echo "⚠️  Collections import failed - you may need to create them manually in the Directus UI"

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
