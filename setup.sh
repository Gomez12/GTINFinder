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

echo "🔧 Directus admin user will be created automatically via environment variables"
echo "⏳ Waiting for Directus to complete initialization and create admin user..."

# Wait for Directus to be fully ready and admin user to be created
for i in {1..12}; do
    if curl -s http://localhost:8055/server/info > /dev/null 2>&1; then
        echo "✅ Directus is responding, checking admin user..."

        # Test if admin user can login
        LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8055/auth/login \
            -H "Content-Type: application/json" \
            -d '{"email":"admin@example.com","password":"admin123"}')

        if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
            echo "✅ Admin user created successfully and is accessible"
            break
        fi
    fi

    if [ $i -eq 12 ]; then
        echo "⚠️ Directus admin user setup incomplete after 2 minutes"
        echo "📋 Manual verification required:"
        echo "1. Go to http://localhost:8055"
        echo "2. Try to login with:"
        echo "   Email: admin@example.com"
        echo "   Password: admin123"
        echo "3. If login fails, complete the initial setup wizard"
    else
        echo "Attempt $i/12 - waiting 10 seconds..."
        sleep 10
    fi
done

echo "📋 Creating Directus collections via API..."
# Get admin token for API calls
echo "Getting admin token for collection creation..."

ADMIN_TOKEN=$(curl -s -X POST http://localhost:8055/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' | \
    grep -o '"access_token":"[^"]*"' | cut -d'"' -f4 || echo "")

if [ -n "$ADMIN_TOKEN" ]; then
    echo "✅ Got admin token, creating collections..."

    # Function to check if collection exists
    check_collection_exists() {
        local collection_name=$1
        local response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
            http://localhost:8055/collections/$collection_name)
        if echo "$response" | grep -q '"data"'; then
            return 0  # Collection exists
        else
            return 1  # Collection doesn't exist
        fi
    }

    # Function to create collection with fields
    create_collection_with_fields() {
        local collection_name=$1
        local collection_payload=$2

        if check_collection_exists "$collection_name"; then
            echo "✅ Collection '$collection_name' already exists"
            return 0
        fi

        echo "📝 Creating collection with fields: $collection_name"
        local response=$(curl -s -X POST http://localhost:8055/collections \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $ADMIN_TOKEN" \
            -d "$collection_payload")

        if echo "$response" | grep -q '"data"'; then
            echo "✅ Collection '$collection_name' created successfully with fields"
            return 0
        else
            echo "❌ Failed to create collection '$collection_name': $response"
            return 1
        fi
    }

    # Collection 1: gtins
    create_collection_with_fields "gtins" '{
        "collection": "gtins",
        "meta": {
            "icon": "barcode",
            "note": "GTIN product information"
        },
        "schema": {
            "name": "gtins"
        },
        "fields": [
            {
                "collection": "gtins",
                "field": "gtin",
                "type": "string",
                "schema": {
                    "is_nullable": false,
                    "max_length": 14,
                    "is_unique": true
                },
                "meta": {
                    "collection": "gtins",
                    "field": "gtin",
                    "interface": "input",
                    "required": true
                }
            },
            {
                "collection": "gtins",
                "field": "product_name",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 255
                },
                "meta": {
                    "collection": "gtins",
                    "field": "product_name",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "gtins",
                "field": "brand",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 100
                },
                "meta": {
                    "collection": "gtins",
                    "field": "brand",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "gtins",
                "field": "category",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 100
                },
                "meta": {
                    "collection": "gtins",
                    "field": "category",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "gtins",
                "field": "description",
                "type": "text",
                "schema": {
                    "is_nullable": true
                },
                "meta": {
                    "collection": "gtins",
                    "field": "description",
                    "interface": "input-multiline",
                    "required": false
                }
            },
            {
                "collection": "gtins",
                "field": "status",
                "type": "string",
                "schema": {
                    "is_nullable": false,
                    "default_value": "pending",
                    "max_length": 50
                },
                "meta": {
                    "collection": "gtins",
                    "field": "status",
                    "interface": "select-dropdown",
                    "options": {
                        "choices": [
                            {"text": "Pending", "value": "pending"},
                            {"text": "Validated", "value": "validated"},
                            {"text": "Error", "value": "error"}
                        ]
                    },
                    "required": true
                }
            },
            {
                "collection": "gtins",
                "field": "created_at",
                "type": "dateTime",
                "schema": {
                    "is_nullable": false,
                    "default_value": {
                        "function": "now"
                    }
                },
                "meta": {
                    "collection": "gtins",
                    "field": "created_at",
                    "interface": "datetime",
                    "display": "datetime",
                    "required": true,
                    "readonly": true
                }
            },
            {
                "collection": "gtins",
                "field": "updated_at",
                "type": "dateTime",
                "schema": {
                    "is_nullable": true
                },
                "meta": {
                    "collection": "gtins",
                    "field": "updated_at",
                    "interface": "datetime",
                    "display": "datetime",
                    "required": false,
                    "readonly": true
                }
            }
        ]
    }'

    # Collection 2: gtin_raw_data
    create_collection_with_fields "gtin_raw_data" '{
        "collection": "gtin_raw_data",
        "meta": {
            "icon": "database",
            "note": "Raw GTIN data from various sources"
        },
        "schema": {
            "name": "gtin_raw_data"
        },
        "fields": [
            {
                "collection": "gtin_raw_data",
                "field": "id",
                "type": "integer",
                "schema": {
                    "is_nullable": false,
                    "is_primary_key": true,
                    "has_auto_increment": true
                },
                "meta": {
                    "collection": "gtin_raw_data",
                    "field": "id",
                    "interface": "numeric",
                    "readonly": true,
                    "required": true
                }
            },
            {
                "collection": "gtin_raw_data",
                "field": "gtin",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 14
                },
                "meta": {
                    "collection": "gtin_raw_data",
                    "field": "gtin",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "gtin_raw_data",
                "field": "source",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 50
                },
                "meta": {
                    "collection": "gtin_raw_data",
                    "field": "source",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "gtin_raw_data",
                "field": "raw_data",
                "type": "json",
                "schema": {
                    "is_nullable": true
                },
                "meta": {
                    "collection": "gtin_raw_data",
                    "field": "raw_data",
                    "interface": "code",
                    "required": false
                }
            },
            {
                "collection": "gtin_raw_data",
                "field": "received_at",
                "type": "dateTime",
                "schema": {
                    "is_nullable": false,
                    "default_value": {
                        "function": "now"
                    }
                },
                "meta": {
                    "collection": "gtin_raw_data",
                    "field": "received_at",
                    "interface": "datetime",
                    "display": "datetime",
                    "required": true,
                    "readonly": true
                }
            }
        ]
    }'

    # Collection 3: gtin_golden_records
    create_collection_with_fields "gtin_golden_records" '{
        "collection": "gtin_golden_records",
        "meta": {
            "icon": "star",
            "note": "Consolidated GTIN golden records"
        },
        "schema": {
            "name": "gtin_golden_records"
        },
        "fields": [
            {
                "collection": "gtin_golden_records",
                "field": "id",
                "type": "integer",
                "schema": {
                    "is_nullable": false,
                    "is_primary_key": true,
                    "has_auto_increment": true
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "id",
                    "interface": "numeric",
                    "readonly": true,
                    "required": true
                }
            },
            {
                "collection": "gtin_golden_records",
                "field": "gtin",
                "type": "string",
                "schema": {
                    "is_nullable": false,
                    "max_length": 14,
                    "is_unique": true
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "gtin",
                    "interface": "input",
                    "required": true
                }
            },
            {
                "collection": "gtin_golden_records",
                "field": "product_name",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 255
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "product_name",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "gtin_golden_records",
                "field": "brand",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 100
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "brand",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "gtin_golden_records",
                "field": "category",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 100
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "category",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "gtin_golden_records",
                "field": "description",
                "type": "text",
                "schema": {
                    "is_nullable": true
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "description",
                    "interface": "input-multiline",
                    "required": false
                }
            },
            {
                "collection": "gtin_golden_records",
                "field": "confidence_score",
                "type": "float",
                "schema": {
                    "is_nullable": false,
                    "default_value": 0.0
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "confidence_score",
                    "interface": "numeric",
                    "required": true
                }
            },
            {
                "collection": "gtin_golden_records",
                "field": "sources_count",
                "type": "integer",
                "schema": {
                    "is_nullable": false,
                    "default_value": 0
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "sources_count",
                    "interface": "numeric",
                    "required": true
                }
            },
            {
                "collection": "gtin_golden_records",
                "field": "created_at",
                "type": "dateTime",
                "schema": {
                    "is_nullable": false,
                    "default_value": {
                        "function": "now"
                    }
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "created_at",
                    "interface": "datetime",
                    "display": "datetime",
                    "required": true,
                    "readonly": true
                }
            },
            {
                "collection": "gtin_golden_records",
                "field": "updated_at",
                "type": "dateTime",
                "schema": {
                    "is_nullable": true
                },
                "meta": {
                    "collection": "gtin_golden_records",
                    "field": "updated_at",
                    "interface": "datetime",
                    "display": "datetime",
                    "required": false,
                    "readonly": true
                }
            }
        ]
    }'

    # Collection 4: data_sources
    create_collection_with_fields "data_sources" '{
        "collection": "data_sources",
        "meta": {
            "icon": "source",
            "note": "Data source configurations"
        },
        "schema": {
            "name": "data_sources"
        },
        "fields": [
            {
                "collection": "data_sources",
                "field": "id",
                "type": "integer",
                "schema": {
                    "is_nullable": false,
                    "is_primary_key": true,
                    "has_auto_increment": true
                },
                "meta": {
                    "collection": "data_sources",
                    "field": "id",
                    "interface": "numeric",
                    "readonly": true,
                    "required": true
                }
            },
            {
                "collection": "data_sources",
                "field": "name",
                "type": "string",
                "schema": {
                    "is_nullable": false,
                    "max_length": 100,
                    "is_unique": true
                },
                "meta": {
                    "collection": "data_sources",
                    "field": "name",
                    "interface": "input",
                    "required": true
                }
            },
            {
                "collection": "data_sources",
                "field": "api_endpoint",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 255
                },
                "meta": {
                    "collection": "data_sources",
                    "field": "api_endpoint",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "data_sources",
                "field": "api_key_required",
                "type": "boolean",
                "schema": {
                    "is_nullable": false,
                    "default_value": false
                },
                "meta": {
                    "collection": "data_sources",
                    "field": "api_key_required",
                    "interface": "boolean",
                    "required": true
                }
            },
            {
                "collection": "data_sources",
                "field": "rate_limit",
                "type": "integer",
                "schema": {
                    "is_nullable": false,
                    "default_value": 100
                },
                "meta": {
                    "collection": "data_sources",
                    "field": "rate_limit",
                    "interface": "numeric",
                    "required": true
                }
            },
            {
                "collection": "data_sources",
                "field": "is_active",
                "type": "boolean",
                "schema": {
                    "is_nullable": false,
                    "default_value": true
                },
                "meta": {
                    "collection": "data_sources",
                    "field": "is_active",
                    "interface": "boolean",
                    "required": true
                }
            },
            {
                "collection": "data_sources",
                "field": "created_at",
                "type": "dateTime",
                "schema": {
                    "is_nullable": false,
                    "default_value": {
                        "function": "now"
                    }
                },
                "meta": {
                    "collection": "data_sources",
                    "field": "created_at",
                    "interface": "datetime",
                    "display": "datetime",
                    "required": true,
                    "readonly": true
                }
            }
        ]
    }'

    # Collection 5: data_quality_scores
    create_collection_with_fields "data_quality_scores" '{
        "collection": "data_quality_scores",
        "meta": {
            "icon": "check-circle",
            "note": "Data quality assessment scores"
        },
        "schema": {
            "name": "data_quality_scores"
        },
        "fields": [
            {
                "collection": "data_quality_scores",
                "field": "id",
                "type": "integer",
                "schema": {
                    "is_nullable": false,
                    "is_primary_key": true,
                    "has_auto_increment": true
                },
                "meta": {
                    "collection": "data_quality_scores",
                    "field": "id",
                    "interface": "numeric",
                    "readonly": true,
                    "required": true
                }
            },
            {
                "collection": "data_quality_scores",
                "field": "gtin",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 14
                },
                "meta": {
                    "collection": "data_quality_scores",
                    "field": "gtin",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "data_quality_scores",
                "field": "source",
                "type": "string",
                "schema": {
                    "is_nullable": true,
                    "max_length": 50
                },
                "meta": {
                    "collection": "data_quality_scores",
                    "field": "source",
                    "interface": "input",
                    "required": false
                }
            },
            {
                "collection": "data_quality_scores",
                "field": "completeness_score",
                "type": "float",
                "schema": {
                    "is_nullable": false,
                    "default_value": 0.0
                },
                "meta": {
                    "collection": "data_quality_scores",
                    "field": "completeness_score",
                    "interface": "numeric",
                    "required": true
                }
            },
            {
                "collection": "data_quality_scores",
                "field": "accuracy_score",
                "type": "float",
                "schema": {
                    "is_nullable": false,
                    "default_value": 0.0
                },
                "meta": {
                    "collection": "data_quality_scores",
                    "field": "accuracy_score",
                    "interface": "numeric",
                    "required": true
                }
            },
            {
                "collection": "data_quality_scores",
                "field": "consistency_score",
                "type": "float",
                "schema": {
                    "is_nullable": false,
                    "default_value": 0.0
                },
                "meta": {
                    "collection": "data_quality_scores",
                    "field": "consistency_score",
                    "interface": "numeric",
                    "required": true
                }
            },
            {
                "collection": "data_quality_scores",
                "field": "overall_score",
                "type": "float",
                "schema": {
                    "is_nullable": false,
                    "default_value": 0.0
                },
                "meta": {
                    "collection": "data_quality_scores",
                    "field": "overall_score",
                    "interface": "numeric",
                    "required": true
                }
            },
            {
                "collection": "data_quality_scores",
                "field": "evaluated_at",
                "type": "dateTime",
                "schema": {
                    "is_nullable": false,
                    "default_value": {
                        "function": "now"
                    }
                },
                "meta": {
                    "collection": "data_quality_scores",
                    "field": "evaluated_at",
                    "interface": "datetime",
                    "display": "datetime",
                    "required": true,
                    "readonly": true
                }
            }
        ]
    }'

    echo "✅ Collections setup completed!"
    echo "🧪 Testing API access to gtins collection..."
    TEST_RESPONSE=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" http://localhost:8055/items/gtins)
    if echo "$TEST_RESPONSE" | grep -q '"data"'; then
        echo "✅ API test successful - gtins collection is accessible"
    else
        echo "⚠️  API test failed - collections may need manual verification"
    fi

else
    echo "❌ Failed to get admin token"
    echo "📋 Manual collection creation required:"
    echo "1. Go to http://localhost:8055"
    echo "2. Login with admin credentials"
    echo "3. Go to Settings > Data Model"
    echo "4. Create the collections manually"
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
