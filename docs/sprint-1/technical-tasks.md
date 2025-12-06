# Sprint 1 Technical Tasks - Detailed Breakdown

**Sprint:** 1 (Week 1-2)  
**Focus:** Foundation & Infrastructure  
**Total Tasks:** 96  

---

## 🐳 Story 1: Docker Compose Setup (8 points)

### 1.1 Docker Compose File Creation
```yaml
# docker-compose.yml structure
services:
  postgresql:
    image: postgres:15
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 30s
      timeout: 10s
      retries: 3

  directus:
    image: directus/directus:10
    environment:
      KEY: ${DIRECTUS_KEY}
      SECRET: ${DIRECTUS_SECRET}
      DB_CLIENT: pg
      DB_HOST: postgresql
      DB_PORT: 5432
      DB_DATABASE: ${DIRECTUS_DB}
      DB_USER: ${DIRECTUS_USER}
      DB_PASSWORD: ${DIRECTUS_PASSWORD}
    ports:
      - "8055:8055"
    depends_on:
      postgresql:
        condition: service_healthy

  airflow:
    image: apache/airflow:2.7.2
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__CORE__SQL_ALCHEMY_CONN: postgresql+psycopg2://${AIRFLOW_USER}:${AIRFLOW_PASSWORD}@postgresql:5432/${AIRFLOW_DB}
      AIRFLOW__CORE__FERNET_KEY: ${AIRFLOW_FERNET_KEY}
      AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION: 'true'
      AIRFLOW__CORE__LOAD_EXAMPLES: 'false'
    volumes:
      - ./airflow/dags:/opt/airflow/dags
    ports:
      - "8080:8080"
    depends_on:
      postgresql:
        condition: service_healthy

  authentik:
    image: ghcr.io/goauthentik/server:2023.10
    environment:
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
      AUTHENTIK_POSTGRESQL__HOST: postgresql
      AUTHENTIK_POSTGRESQL__NAME: ${AUTHENTIK_DB}
      AUTHENTIK_POSTGRESQL__USER: ${AUTHENTIK_USER}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${AUTHENTIK_PASSWORD}
    ports:
      - "9000:9000"
    depends_on:
      postgresql:
        condition: service_healthy

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - directus
      - airflow
      - authentik

volumes:
  postgres_data:
```

### 1.2 Environment Variables Template
```bash
# .env template
# Database
POSTGRES_DB=gtin_finder
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password

# Directus
DIRECTUS_KEY=your_directus_key
DIRECTUS_SECRET=your_directus_secret
DIRECTUS_DB=directus
DIRECTUS_USER=directus_user
DIRECTUS_PASSWORD=directus_password

# Airflow
AIRFLOW_DB=airflow
AIRFLOW_USER=airflow_user
AIRFLOW_PASSWORD=airflow_password
AIRFLOW_FERNET_KEY=your_fernet_key

# Authentik
AUTHENTIK_SECRET_KEY=your_authentik_secret
AUTHENTIK_DB=authentik
AUTHENTIK_USER=authentik_user
AUTHENTIK_PASSWORD=authentik_password
```

### 1.3 Network Configuration
```yaml
# Custom network for service communication
networks:
  gtin-finder-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### 1.4 Health Checks Implementation
```yaml
# Health check examples for each service
healthcheck:
  test: ["CMD-SHELL", "curl -f http://localhost:8055/health || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

---

## 🗄️ Story 2: PostgreSQL Database Setup (5 points)

### 2.1 Database Initialization Script
```sql
-- init.sql
CREATE DATABASE directus;
CREATE DATABASE airflow;
CREATE DATABASE authentik;

-- Users
CREATE USER directus_user WITH PASSWORD 'directus_password';
CREATE USER airflow_user WITH PASSWORD 'airflow_password';
CREATE USER authentik_user WITH PASSWORD 'authentik_password';

-- Permissions
GRANT ALL PRIVILEGES ON DATABASE directus TO directus_user;
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow_user;
GRANT ALL PRIVILEGES ON DATABASE authentik TO authentik_user;
```

### 2.2 Connection Pooling Configuration
```yaml
# PostgreSQL configuration
postgresql:
  environment:
    POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
    POSTGRES_SHARED_PRELOAD_LIBRARIES: pg_stat_statements
    POSTGRES_MAX_CONNECTIONS: 200
    POSTGRES_SHARED_BUFFERS: 256MB
    POSTGRES_EFFECTIVE_CACHE_SIZE: 1GB
```

### 2.3 Backup Scripts
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
docker exec postgresql pg_dump -U postgres gtin_finder > backup_${DATE}.sql
```

---

## 🚀 Story 3: Directus Installation (6 points)

### 3.1 Directus Configuration
```javascript
// directus/config.js
module.exports = {
  key: process.env.DIRECTUS_KEY,
  secret: process.env.DIRECTUS_SECRET,
  database: {
    client: 'pg',
    host: 'postgresql',
    port: 5432,
    database: 'directus',
    user: 'directus_user',
    password: 'directus_password'
  },
  publicUrl: 'http://localhost:8055',
  storage: {
    location: 'local',
    local: {
      root: './uploads'
    }
  },
  cors: {
    origin: ['http://localhost:3000'],
    credentials: true
  }
};
```

### 3.2 Admin User Creation Script
```bash
#!/bin/bash
# create-admin.sh
docker exec directus npx directus users create \
  --email admin@example.com \
  --password admin123 \
  --role administrator
```

### 3.3 API Token Generation
```bash
#!/bin/bash
# generate-token.sh
docker exec directus npx directus tokens create \
  --name "Development Token" \
  --expires "2024-12-31T23:59:59Z"
```

---

## 💨 Story 4: Airflow Setup (6 points)

### 4.1 Airflow Configuration
```ini
# airflow/airflow.cfg
[core]
executor = LocalExecutor
sql_alchemy_conn = postgresql+psycopg2://airflow_user:airflow_password@postgresql:5432/airflow
fernet_key = your_fernet_key
dags_are_paused_at_creation = true
load_examples = false

[webserver]
rbac = true
expose_config = true

[logging]
base_log_folder = /opt/airflow/logs
```

### 4.2 Basic DAG Template
```python
# airflow/dags/example_dag.py
from airflow import DAG
from airflow.operators.dummy import DummyOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'gtin_example',
    default_args=default_args,
    description='Example GTIN processing DAG',
    schedule_interval=timedelta(days=1),
    catchup=False,
)

start = DummyOperator(task_id='start', dag=dag)
end = DummyOperator(task_id='end', dag=dag)

start >> end
```

### 4.3 Airflow User Setup
```bash
#!/bin/bash
# create-airflow-user.sh
docker exec airflow airflow users create \
  --username admin \
  --firstname Admin \
  --lastname User \
  --role Admin \
  --email admin@example.com
```

---

## 🔐 Story 5: Authentik Configuration (5 points)

### 5.1 Authentik Environment Configuration
```yaml
# authentik/docker-compose.yml addition
authentik:
  environment:
    AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
    AUTHENTIK_POSTGRESQL__HOST: postgresql
    AUTHENTIK_POSTGRESQL__NAME: authentik
    AUTHENTIK_POSTGRESQL__USER: authentik_user
    AUTHENTIK_POSTGRESQL__PASSWORD: authentik_password
    AUTHENTIK_ERROR_REPORTING__ENABLED: "false"
    AUTHENTIK_EMAIL__HOST: localhost
    AUTHENTIK_EMAIL__PORT: 1025
```

### 5.2 Admin Setup Script
```bash
#!/bin/bash
# setup-authentik.sh
# Wait for Authentik to be ready
sleep 30

# Create admin user (interactive)
docker exec -it authentik ak manage createsuperuser
```

### 5.3 OIDC Provider Configuration
```yaml
# Authentik UI Configuration Steps:
# 1. Go to Applications -> Providers
# 2. Create OAuth2/OpenID Connect Provider
# 3. Configure:
#    - Client Type: Confidential
#    - Response Types: code
#    - Grant Types: authorization_code
#    - Redirect URIs: http://localhost:3000/*
```

---

## ⚛️ Story 6: React Setup (4 points)

### 6.1 Project Initialization
```bash
# Create React project
npm create vite@latest frontend -- --template react-ts
cd frontend
npm install

# Install additional dependencies
npm install -D tailwindcss postcss autoprefixer
npm install -D eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser
npm install -D prettier eslint-config-prettier
npm install react-router-dom
npm install @auth0/auth0-react
```

### 6.2 Tailwind Configuration
```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
        }
      }
    },
  },
  plugins: [],
}
```

### 6.3 ESLint Configuration
```json
// .eslintrc.json
{
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended",
    "prettier"
  ],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/explicit-function-return-type": "warn"
  }
}
```

### 6.4 Project Structure
```
src/
├── components/
│   ├── common/
│   ├── auth/
│   └── gtin/
├── pages/
├── hooks/
├── services/
├── types/
├── utils/
└── styles/
```

---

## 🔗 Story 7: OIDC Integration (5 points)

### 7.1 Auth0 Configuration
```typescript
// src/auth/AuthProvider.tsx
import { Auth0Provider } from '@auth0/auth0-react';

const domain = process.env.REACT_APP_AUTH0_DOMAIN;
const clientId = process.env.REACT_APP_AUTH0_CLIENT_ID;

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <Auth0Provider
      domain={domain!}
      clientId={clientId!}
      redirectUri={window.location.origin}
    >
      {children}
    </Auth0Provider>
  );
};
```

### 7.2 Protected Route Component
```typescript
// src/components/auth/ProtectedRoute.tsx
import { useAuth0 } from '@auth0/auth0-react';
import { Navigate } from 'react-router-dom';

export const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAuthenticated, isLoading } = useAuth0();

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return isAuthenticated ? <>{children}</> : <Navigate to="/login" />;
};
```

### 7.3 Login Component
```typescript
// src/components/auth/Login.tsx
import { useAuth0 } from '@auth0/auth0-react';

export const Login = () => {
  const { loginWithRedirect } = useAuth0();

  return (
    <button
      onClick={() => loginWithRedirect()}
      className="bg-primary-600 text-white px-4 py-2 rounded"
    >
      Log In
    </button>
  );
};
```

---

## 📝 Story 8: GTIN Input Form (3 points)

### 8.1 GTIN Validation Utility
```typescript
// src/utils/gtinValidator.ts
export const validateGTIN = (gtin: string): boolean => {
  const cleanGTIN = gtin.replace(/[^0-9]/g, '');
  const validLengths = [8, 12, 13, 14];
  
  if (!validLengths.includes(cleanGTIN.length)) {
    return false;
  }

  return calculateChecksum(cleanGTIN) === parseInt(cleanGTIN.slice(-1));
};

const calculateChecksum = (gtin: string): number => {
  // GTIN checksum calculation logic
  const digits = gtin.slice(0, -1).split('').map(Number);
  const multipliers = gtin.length === 8 ? [3, 1] : [1, 3];
  
  let sum = 0;
  digits.forEach((digit, index) => {
    sum += digit * multipliers[index % 2];
  });
  
  return (10 - (sum % 10)) % 10;
};
```

### 8.2 GTIN Input Component
```typescript
// src/components/gtin/GTINInput.tsx
import { useState } from 'react';
import { validateGTIN } from '../../utils/gtinValidator';

export const GTINInput = () => {
  const [gtin, setGtin] = useState('');
  const [isValid, setIsValid] = useState(true);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setGtin(value);
    setIsValid(validateGTIN(value));
  };

  return (
    <div className="space-y-2">
      <label className="block text-sm font-medium text-gray-700">
        GTIN Code
      </label>
      <input
        type="text"
        value={gtin}
        onChange={handleChange}
        className={`w-full px-3 py-2 border rounded-md ${
          isValid ? 'border-gray-300' : 'border-red-500'
        }`}
        placeholder="Enter GTIN (8, 12, 13, or 14 digits)"
      />
      {!isValid && gtin && (
        <p className="text-red-500 text-sm">Invalid GTIN format</p>
      )}
    </div>
  );
};
```

---

## 🔌 Story 9: Directus API Integration (4 points)

### 9.1 API Service Configuration
```typescript
// src/services/directus.ts
import { Directus } from '@directus/sdk';

const directus = new Directus('http://localhost:8055');

export const api = {
  async createGTIN(gtin: string) {
    try {
      const result = await directus.items('gtins').createOne({
        gtin_code: gtin,
        status: 'pending',
        created_at: new Date().toISOString(),
      });
      return result;
    } catch (error) {
      console.error('Error creating GTIN:', error);
      throw error;
    }
  },

  async getGTINs() {
    try {
      const result = await directus.items('gtins').readByQuery({
        limit: 50,
        sort: ['-created_at'],
      });
      return result.data;
    } catch (error) {
      console.error('Error fetching GTINs:', error);
      throw error;
    }
  },
};
```

### 9.2 GTIN Collection Schema
```json
{
  "collection": "gtins",
  "fields": [
    {
      "field": "id",
      "type": "integer",
      "meta": {
        "hidden": true,
        "readonly": true
      }
    },
    {
      "field": "gtin_code",
      "type": "string",
      "meta": {
        "required": true,
        "length": 14
      }
    },
    {
      "field": "status",
      "type": "string",
      "meta": {
        "required": true,
        "default": "pending"
      }
    },
    {
      "field": "created_at",
      "type": "timestamp",
      "meta": {
        "readonly": true
      }
    },
    {
      "field": "updated_at",
      "type": "timestamp",
      "meta": {
        "readonly": true
      }
    }
  ]
}
```

---

## 🎨 Story 10: UI Styling (3 points)

### 10.1 Design Tokens
```typescript
// src/styles/tokens.ts
export const tokens = {
  colors: {
    primary: {
      50: '#eff6ff',
      100: '#dbeafe',
      500: '#3b82f6',
      600: '#2563eb',
      700: '#1d4ed8',
    },
    gray: {
      50: '#f9fafb',
      100: '#f3f4f6',
      500: '#6b7280',
      900: '#111827',
    },
    success: '#10b981',
    warning: '#f59e0b',
    error: '#ef4444',
  },
  spacing: {
    xs: '0.5rem',
    sm: '1rem',
    md: '1.5rem',
    lg: '2rem',
    xl: '3rem',
  },
  borderRadius: {
    sm: '0.25rem',
    md: '0.375rem',
    lg: '0.5rem',
  },
};
```

### 10.2 Component Library Base
```typescript
// src/components/common/Button.tsx
import { ButtonHTMLAttributes, ReactNode } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  children: ReactNode;
}

export const Button = ({ 
  variant = 'primary', 
  size = 'md', 
  children, 
  className = '',
  ...props 
}: ButtonProps) => {
  const baseClasses = 'font-medium rounded-md transition-colors focus:outline-none focus:ring-2';
  
  const variantClasses = {
    primary: 'bg-primary-600 text-white hover:bg-primary-700 focus:ring-primary-500',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
    danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
  };
  
  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  };

  return (
    <button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};
```

---

## 🧪 Story 11: Error Handling (3 points)

### 11.1 Error Boundary Component
```typescript
// src/components/common/ErrorBoundary.tsx
import React, { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Uncaught error:', error, errorInfo);
  }

  public render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <div className="max-w-md w-full bg-white shadow-lg rounded-lg p-6">
            <h1 className="text-2xl font-bold text-red-600 mb-4">Something went wrong</h1>
            <p className="text-gray-600 mb-4">
              We're sorry, but something unexpected happened. Please try refreshing the page.
            </p>
            <button
              onClick={() => window.location.reload()}
              className="w-full bg-primary-600 text-white py-2 px-4 rounded-md hover:bg-primary-700"
            >
              Refresh Page
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### 11.2 Global Error Handler
```typescript
// src/utils/errorHandler.ts
export class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export const handleApiError = (error: any): AppError => {
  if (error.response) {
    const { status, data } = error.response;
    return new AppError(
      data.message || 'API request failed',
      data.code || 'API_ERROR',
      status
    );
  }
  
  if (error.request) {
    return new AppError(
      'Network error - please check your connection',
      'NETWORK_ERROR',
      0
    );
  }
  
  return new AppError(
    error.message || 'An unexpected error occurred',
    'UNKNOWN_ERROR',
    500
  );
};
```

---

## 📚 Story 12: Documentation (2 points)

### 12.1 README.md Structure
```markdown
# GTINFinder

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 18+
- Git

### Setup

1. Clone the repository
```bash
git clone <repository-url>
cd gtin-finder
```

2. Configure environment variables
```bash
cp .env.example .env
# Edit .env with your values
```

3. Start services
```bash
docker-compose up -d
```

4. Setup frontend
```bash
cd frontend
npm install
npm run dev
```

### Access Points
- Frontend: http://localhost:3000
- Directus Admin: http://localhost:8055
- Airflow: http://localhost:8080
- Authentik: http://localhost:9000

### Environment Variables
See `.env.example` for all required variables.

## Development

### Project Structure
```
gtin-finder/
├── docker-compose.yml
├── frontend/          # React application
├── airflow/           # Airflow DAGs
├── directus/          # Directus extensions
└── docs/             # Documentation
```

### Common Issues
- Port conflicts: Check if ports 3000, 8055, 8080, 9000 are available
- Database connection: Ensure PostgreSQL is healthy before starting other services
- Authentication: Complete Authentik setup before testing SSO
```

### 12.2 API Documentation
```markdown
# API Documentation

## GTIN Endpoints

### Create GTIN
```
POST /items/gtins
Content-Type: application/json
Authorization: Bearer <token>

{
  "gtin_code": "8712345678901",
  "status": "pending"
}
```

### Get GTINs
```
GET /items/gtins
Authorization: Bearer <token>

Response:
{
  "data": [
    {
      "id": 1,
      "gtin_code": "8712345678901",
      "status": "pending",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```
```

---

## 📊 Task Summary

### Tasks by Story
| Story | Total Tasks | Backend | Frontend | DevOps |
|-------|-------------|---------|----------|--------|
| 1 | 8 | 2 | 0 | 6 |
| 2 | 5 | 5 | 0 | 0 |
| 3 | 6 | 4 | 0 | 2 |
| 4 | 6 | 4 | 0 | 2 |
| 5 | 5 | 3 | 0 | 2 |
| 6 | 4 | 0 | 4 | 0 |
| 7 | 5 | 0 | 5 | 0 |
| 8 | 3 | 0 | 3 | 0 |
| 9 | 4 | 2 | 2 | 0 |
| 10 | 3 | 0 | 3 | 0 |
| 11 | 3 | 1 | 2 | 0 |
| 12 | 2 | 0 | 0 | 2 |
| **Total** | **96** | **21** | **19** | **56** |

### Estimated Hours
| Story | Points | Estimated Hours |
|-------|--------|----------------|
| 1 | 8 | 32 |
| 2 | 5 | 20 |
| 3 | 6 | 24 |
| 4 | 6 | 24 |
| 5 | 5 | 20 |
| 6 | 4 | 16 |
| 7 | 5 | 20 |
| 8 | 3 | 12 |
| 9 | 4 | 16 |
| 10 | 3 | 12 |
| 11 | 3 | 12 |
| 12 | 2 | 8 |
| **Total** | **40** | **216** |

### Dependencies
- **Critical Path:** Story 1 → Story 2 → Stories 3,4,5 → Stories 6-12
- **Parallel Work:** Stories 6-12 can be worked on simultaneously once infrastructure is ready
- **Risk Mitigation:** Start with Story 1 (Docker Compose) as highest priority

---

**Sprint 1 technical breakdown is complete!** 🎯

**Next Steps:**
1. Review task breakdown with development team
2. Assign tasks based on expertise (DevOps, Backend, Frontend)
3. Begin with Story 1 (Docker Compose Setup)
4. Set up daily standups to track progress
